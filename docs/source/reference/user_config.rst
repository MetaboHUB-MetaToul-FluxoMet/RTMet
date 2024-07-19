.. _reference.user-config:

===========================
Workflow User Configuration
===========================

Changes in the :term:`source directory` config file will be passed down to any :term:`workflow run`
that is subsequently installed. Changes in a run directory will only apply to the concerned run after
you use :command:`cylc reload`

.. seealso:: 
    :ref:`tutorial.user-config`

Configuration Options
=====================

The main configuration file can be found in the :file:`rose-suite.conf` file at the root of the
workflow directory.

.. rose:file:: rose-suite.conf

    .. autoconfig:: ../../cylc-src/bioreactor-workflow/rose-suite.conf

Input Tables
============

The input tables are stored in the :file:`config/` directory at the root of the workflow directory.

compounds_db.csv
----------------

.. csv-table:: Exemple
   :file: /_static/tables/compounds_db.csv
   :delim: ;
   :stub-columns: 1
   :header-rows: 1

The table is validated against the following schema:

.. literalinclude:: /../../cylc-src/bioreactor-workflow/meta/compounds_db.resource.json
    :language: json
    :caption: compounds_db.resource.json

