.. _development.workflow-design:

=======================
Workflow design choices
=======================

.. attention:: 
    🏗 Work in Progress 🏗

* Following Cylc's best practices
* Jinja2 templating
* Rose for configuration management
* Task inheritance to avoid code duplication
* Run setup is done at the first cyclepoint
* Tasks can run in specific conda environments
* `dataflow` and `qc` directories
* Data is stored in plain text `.csv` files
* Libraries/packages to be favored
* InfluxDB is an optional dependency

Following Cylc's best practices
===============================

