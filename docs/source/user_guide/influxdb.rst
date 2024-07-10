.. _influxdb-guide:

=================================
Visualizing results with InfluxDB
=================================

.. highlight:: console

.. attention:: 
    🏗 Work in Progress 🏗

InfluxDB is a time-series database that is used to store and visualize the results of the workflow
in real-time. This section provides an overview of how to set up and use InfluxDB with RTMet.

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

- :rose:conf:`rose-suite.conf[template variables]cfg__toggle_influxdb`
- :rose:conf:`rose-suite.conf[template variables]cfg__influxdb_url`
- :rose:conf:`rose-suite.conf[template variables]cfg__influxdb_org`
- :rose:conf:`rose-suite.conf[template variables]cfg__influxdb_auth_token`

Set the first one to `True` to enable the integration. The other 3 should match the credentials you
used to set up InfluxDB.

Now, create a new run of the workflow::

    $ cylc run bioreactor-workflow --run-name=test-influxdb
