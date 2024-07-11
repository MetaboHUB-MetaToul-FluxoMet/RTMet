.. _influxdb-guide:

=================================
Visualizing results with InfluxDB
=================================

.. highlight:: console

.. attention:: 
    🏗 Work in Progress 🏗

InfluxDB is a time-series database that is used to store and visualize the results of the workflow
in real-time. This guide provides an overview of how to set up and use InfluxDB with RTMet.

You should have an InfluxDB instance running, with an organization and first user. To set it up,
please refer to the :ref:`installation <installing-influxdb>` section.

The following instructions assume you're using the self-hosted version of InfluxDB, and references
that version of their documentation. If you're using the cloud solution, the steps should be similar.

Linking the workflow to the database
------------------------------------

You'll first need to create an all access token for the workflow to use. From the InfluxDB UI (web
interface):

- Navigate to **Load Data > API Tokens** using the left navigation bar.
- Click **➕ Generate API token** and select **All Access API Token**.
- Enter a description for the API token and click **✔️ Save**.
- Copy the generated token and store it for safe keeping. If you lose it, you'll need to generate a
  new one.

Now edit the main config file, :file:`~/cylc-src/bioreactor-workflow/rose-suite.conf`, to set the
following options:

- :rose:conf:`rose-suite.conf[template variables]cfg__toggle_influxdb` : `True`
- :rose:conf:`rose-suite.conf[template variables]cfg__influxdb_url` : URL of the running InfluxDB
  instance.
- :rose:conf:`rose-suite.conf[template variables]cfg__influxdb_org` : Organization to write to.
- :rose:conf:`rose-suite.conf[template variables]cfg__influxdb_auth_token` : The API token you just
  generated.


Now, create and start a new run of the workflow::

    $ cylc install bioreactor-workflow --run-name=influxdb-guide

Then open the TUI::

    $ cylc tui

Manually start the **influxdb-guide** run from there, by opening the context menu and choosing
**<play>**.

At cycle 0, you should see the task **create_bucket** run then succeed. If it is the case, the
workflow can properly access the InfluxDB instance and your all-access token is valid. Well done !

Access your InfluxDB instance via the web interface. Go to **Load Data > Buckets**. You should see
a new bucket named **influxdb-guide**. You may have to refresh the page.

.. error::
    If the **create_bucket** job failed or you don't see the bucket, check the logs of the job for
    any errors.

    They should be located in
    :file:`~/cylc-run/bioreactor-workflow/influxdb-guide/log/job/0/create_bucket/01/` as
    :file:`job.out` and :file:`job.err`.

Setting up the bioreactor dashboard
-----------------------------------

We're gonna use a preconfigured dashboard to visualize the data. Download the following
:reporawfile:`template <etc/influx_templates/bioreactor_template.yml>` from RTMet's repository

