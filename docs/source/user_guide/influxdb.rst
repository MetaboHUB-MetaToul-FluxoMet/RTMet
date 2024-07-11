.. _influxdb-guide:

=================================
Visualizing results with InfluxDB
=================================

.. highlight:: console

InfluxDB is a time-series database that is used to store and visualize the results of the workflow
in real-time. This guide provides an overview of how to set up and use InfluxDB with RTMet.

You should have an InfluxDB instance running, with an organization and first user. To set it up,
please refer to the :ref:`installation <installing-influxdb>` section.

The following instructions assume you're using the self-hosted version of InfluxDB. If you're using
the cloud solution, the steps should be similar.

Linking the workflow to the database
------------------------------------

You'll first need to create an all-access token for the workflow to use. From the InfluxDB UI (web
interface):

- Navigate to :octicon:`upload` **Load Data > API Tokens** using the left navigation bar.
- Click :octicon:`plus` **Generate API token** and select **All Access API Token**.
- Enter a description for the API token and click :octicon:`check` **Save**.
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

Access your InfluxDB instance via the web interface. Go to :octicon:`upload` **Load Data > Buckets**.
You should see a new bucket named **bioreactor-workflow/influxdb-guide**. You may have to refresh the
page.

.. error::
    If the **create_bucket** job failed or you don't see the bucket, check the logs of the job for
    any errors.

    They should be located in
    :file:`~/cylc-run/bioreactor-workflow/influxdb-guide/log/job/0/create_bucket/01/` as
    :file:`job.out` and :file:`job.err`.

Uploading data to InfluxDB
--------------------------

Since we're gonna try to visualize data, you'll need to give the workflow run some .raw files to
process, like you did in the :ref:`basic-tutorial`. This time, you may want to use some data of your
own, generated recently.

Add the .raw files to the :file:`raws/` subdirectory of the **influxdb-guide** run directory.
Watch the TUI to see the workflow process the files, and then automatically upload it to influxDB.

Setting up the bioreactor dashboard
-----------------------------------

We're gonna use a preconfigured dashboard to visualize the data. From the InfluxDB UI, go to
:octicon:`gear` **Settings > Templates** using the left navigation bar. Paste the following url in
the **Import Template** field:

https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet/blob/main/etc/influx_templates/bioreactor_template.yml

Ignore the warning that the template isn't from the Community Templates repository, and click
**Lookup Template** then **Install Template**.

Now, go to :octicon:`apps` **Dashboards** and open **Bioreactor Dashboard**.

.. image:: /_static/screenshots/bioreactor_dashboard.png
    :alt: InfluxDB dashboard named Bioreactor Dashboard

You probably won't see any data yet. Start by enabling :octicon:`checkbox` **Show Variables**. The
most important one is :octicon:`three-bars` **bucket**. Set it to the
**bioreactor-workflow/influxdb-guide** bucket you created earlier.

The timestamp given to InfluxDB when uploading results is the one written in the .raw file by the
instrument. If you're looking at historical data, you may want to adjust the :octicon:`clock` **Time
Range** of the dashboard at the top right.

If you don't remember the day of the experiment, start by selecting a very large window (1 year).
You should see some points squished together on the graph. The overlay legend will give you the exact
date and time of the data points.

.. note::
  The idea is that when using the workflow in real-time, you can monitor the data as it is being
  processed and uploaded. You would simply choose a sliding time range, e.g. :octicon:`clock` **Past 1h**,
  and activate auto-refresh.

You can also set the variables :octicon:`three-bars` **metabolite_n** to change the displayed
metabolite concentrations in the corresponding cells.