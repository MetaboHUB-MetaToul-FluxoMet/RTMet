============
Installation
============

.. highlight:: console

System requirements
===================

RTMet requires:
    - A Unix-like operating system: macOS, Linux, BSD.
    - A distribution of the Conda package manager.
    - GNU coreutils. 
    - :command:`git`, :command:`curl`, :command:`ssh` and :command:`rsync`

Some optional features will require:
    - An InfluxDB instance
    - JupyterHub

If you're using MacOS, follow the `instructions`_ from Cylc documentation explaining additional
dependencies.

.. _installing-the-workflow:

Installing the workflow
=======================

Conda
-----

If you don't already have a distribution of Conda installed, we recommend installing Miniforge::

    $ curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
    $ bash Miniforge3-$(uname)-$(uname -m).sh

If it's not already set, make sure that the Conda base environment does not activate by default::

    $ conda config --set auto_activate_base false

Cloning the project
-------------------

.. Download the latest release of RTMet (TODO).
    curl -L -O "https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet/releases/latest/download/workflow.tar.gz"

Download the workflow from the project's repository on GitHub, to a location of your choice::

    $ git clone https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet.git

We also have to make sure that Cylc finds the workflow by symlinking it::

    $ mkdir ~/cylc-src
    $ ln -s $(pwd)/RTMet/cylc-src/bioreactor-workflow ~/cylc-src/bioreactor-workflow

.. _setting-up-cylc-and-wrapper:

Setting up Cylc and its wrapper script
--------------------------------------

Cylc is a workflow manager and the core dependency of RTMet. Install it using the :file:`cylc.yml`
Conda environment file::

    $ cd RTMet/cylc-src/bioreactor-workflow/envs
    $ conda env create -f cylc.yml

Once it's done, you'll need to setup the Cylc wrapper script, which is needed for Cylc and Conda to
work together.

We recommend installing it in a directory that is in your :envvar:`$PATH`, such as :file:`/usr/local/bin`
(will require :command:`sudo` access)::

    $ WRAPPER_DIR='/usr/local/bin'
    $ conda activate cylc
    $ sudo $(which cylc) get-resources cylc ${WRAPPER_DIR} && chmod +x ${WRAPPER_DIR}/cylc
    $ sudo ln -s ${WRAPPER_DIR}/cylc ${WRAPPER_DIR}/rose
    $ conda deactivate

Then, you'll need to edit the wrapper script to point to the Conda environment where Cylc is installed.

.. code-block:: diff

   - CYLC_HOME_ROOT="${CYLC_HOME_ROOT:-/opt}"
   + CYLC_HOME_ROOT="${CYLC_HOME_ROOT:-${HOME}/miniforge3/envs}"

To test your installation, launch the :command:`cylc` command without any conda env active::

    $ for i in $(seq ${CONDA_SHLVL}); do conda deactivate; done
    $ cylc help

Installing workflow tasks environments
--------------------------------------

Bioinformatics tools are installed in separate Conda environments, for isolation and reproductibility
purposes. For binneR, you'll need to install it from the R console::

    $ for file in wf-*.yml; do conda env create -f $file; done
    $ conda activate wf-binner && Rscript -e "remotes::install_github('aberHRML/binneR', dependencies=FALSE, upgrade_dependencies=FALSE)"
    $ conda deactivate

.. _installing-influxdb:

Optional: Installing InfluxDB
=============================

Visualizing results in real time requires an InfluxDB instance. One option is to use
`InfluxData's official cloud solution`_. It's quick and easy to set up, so we recommend it for testing
the workflow.

.. warning:: The free-tier of InfluxData's cloud solution is quite limited. Buckets have a retention
    policy of 30 days, which means your data will be deleted one month after it being uploaded.
    Don't use it as a primary backup.

The other one is to use the self-hosted version, InfluxDB OSS v2. See installation instructions from
`InfluxDB's documentation`_.
Either way, make sure to setup your InfluxDB instance by creating an organization and a first user.


Optional: Installing JupyterHub
===============================
...


.. External References:
.. _Instructions: https://cylc.github.io/cylc-doc/latest/html/installation.html#installing-on-mac-os
.. _InfluxData's official cloud solution: https://cloud2.influxdata.com/signup
.. _InfluxDB's documentation: https://docs.influxdata.com/influxdb/v2/install/
