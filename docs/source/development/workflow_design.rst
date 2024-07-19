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

Our workflow generally follows Cylc's :ref:`cylc:workflow design guide`.

Some notable exceptions are:
  * :ref:`cylc:self-contained workflows`: RTMet relies on a user-wide (or system-wide) conda
    installation to handle most of its dependencies. This means they are vulnerable to external
    changes.
  * :ref:`cylc:workflow housekeeping`: Not implemented yet.
  * :doc:`Automating Failure Recovery <cylc:workflow-design-guide/general-principles>`: Not
    implemented yet.

Jinja2 templating
=================

Jinja2 templating is used extensively in the workflow definition file, :file:`flow.cylc`. It allows
text to be generated dynamically, based on the values of variables passed to the template.

Since the workflow source code contained in the :file:`flow.cylc` is basically text, Jinja2 templating
is a way for Cylc's devs to add logic without having to write a full-fledged programming language.

User configuration options are passed down from the :rose:file:`rose-suite.conf` file to the workflow as
Jinja2 variables. Some of these variables are used for branching logic:


.. code-block:: jinja
    :caption: Switching between input strategies
    :emphasize-lines: 5-9
    
    [scheduling]
        cycling mode = integer
        initial cycle point = 0
        [[xtriggers]]
    {% if cfg__input_strategy == 'internal' %}
            catch_raw = catch_raw_internal('%(point)s', '%(workflow_run_dir)s')
    {% elif cfg__input_strategy == 'local' %}
            catch_raw = catch_raw_local('%(point)s', '%(workflow_run_dir)s', {{ cfg__local_runs_dir }})
    {% endif %}

Whole parts of the workflow can be enabled or disabled based on the value of a variable:

.. code-block:: jinja
    :caption: Enabling InfluxDB support
    :emphasize-lines: 6-12

    [scheduling]
        [[graph]]
            ...
            R1/+P3 = quantify => compute_fluxes
            +P4/P1 = quantify & compute_fluxes[-P1] => compute_fluxes
    {% if cfg__toggle_influxdb %}
            R1/^ = validate_cfg => create_bucket => is_setup
            +P1/P1 = """
                annotate => upload_features
                quantify => upload_concentrations
            """
    {% endif %}

Other Jinja2 variables are used to define environment variables for tasks:

.. code-block:: jinja
    :caption: Allowing the user to set the number of scans to trim
    :emphasize-lines: 9-10
    
    [runtime]
        [[trim_spectra]]
            inherit = None, CONDA_OPENMS
            script = """
                trimms ${mzml} ${n_start} ${n_end}
            """
            [[[environment]]]
                mzml = ${MAIN_RESULTS_DIR}/${RAWFILE_STEM}.mzML
                n_start = {{ cfg__trim_values[0] }}
                n_end = {{ cfg__trim_values[1] }}
            [[[meta]]]
                title = Trim Spectra
                description = """
                    Remove the first `n_start` and last `n_end` scans from the mzML file. This is useful
                    if the shape of the flowgram is not stable at the beginning or end of the run.
                """
                categories = bioinformatics

.. seealso:: 
    :ref:`cylc:user guide jinja2` in Cylc's documentation.

Rose for configuration management
=================================

Rose is used for its :ref:`rose:rose suites` capabilities. It interfaces with our workflow using the
:ref:`cylc:cylc rose` plugin. 

Just think of it as workflow configuration being outsourced to another package, since Cylc doesn't
have it built-in (yet?)

User configuration options are stored in the :rose:file:`rose-suite.conf` file at the root of the
workflow directory. They are passed down to the workflow as Jinja2 variables.

.. seealso::  
    * :ref:`tutorial.user-config`
    * :ref:`reference.user-config`