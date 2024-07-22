.. _development.workflow-design:

=======================
Workflow design choices
=======================

The choices described here are the ones currently implemented in the RTMet workflow. They are subject
to change, and could be brought up for discussion.

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
:ref:`cylc:cylc rose` plugin. Just think of it as workflow configuration being outsourced to another package, since Cylc doesn't
have it built-in (yet?)

User configuration options are stored in the :rose:file:`rose-suite.conf` file at the root of the
workflow directory. They are in the :strong:`[template variables]` section, which means they are passed
down to the workflow as Jinja2 variables.

The chosen naming convention for configuration items is *cfg__<item_name>*. This is both to avoid
conflicts with other environment variables and to make it clear that these are configuration items.

.. seealso::  
    * :ref:`tutorial.user-config`
    * :ref:`reference.user-config`

Task inheritance to avoid code duplication
==========================================

Workflow tasks can inherit from other tasks, which mean script blocks (:strong:`[script]`,
:strong:`[pre-script]` and :strong:`[post-script]`) but also :strong:`[environment]` variables are taken
from the parent task. Our workflow uses this feature for:

* Conda environment activation (see :ref:`below <development.conda-envs>`)
* Sharing InfluxDB configuration (URL, token, organization, etc.)
* Format some of the intermediary tables in a :strong:`[post-script]` block (adding *datetime*,
  *cycle* and *instrument_id* columns).


.. seealso:: 
    :ref:`cylc:sharing by inheritance` in Cylc's documentation.

Run setup is done at the first cyclepoint
=========================================

This include user configuration validation, input data validation, and other tasks that need to be
done before the main workflow starts:

* :strong:`[validate_cfg]`
* :strong:`[validate_compounds_db]`
* :strong:`[validate_met_model]` (to be implemented)
* :strong:`[[INFLUXDB][create_bucket]]`

Cyclepoint 0 is reserved for setup tasks. processing of .raw files starts at cyclepoint 1.

.. _development.conda-envs:

Tasks can run in specific conda environments
============================================

Conda environments activation is handled by a `pre-script`_. :file:`envs/conda.cylc` defines
family tasks, one for each conda environment:

.. code-block:: cylc
    :lineno-start: 10
    :caption: ``flow.cylc``

    # Create task families for conda environments.
    %include 'envs/conda.cylc'

.. code-block:: jinja
    :caption: ``conda.cylc``

    {% set conda_envs = {
        'CONDA_TRFP': 'wf-trfp',
        'CONDA_BINNER': 'wf-binner',
        'CONDA_DATAMUNGING': 'wf-datamunging',
        'CONDA_INFLUX': 'wf-influx',
        'CONDA_OPENMS': 'wf-pyopenms',
        } %}

    [runtime]
    {% for env, conda_env_name in conda_envs.items() %}
        [[{{env}}]]
            pre-script = """
                set +eu
                conda activate {{ conda_env_name }}
                set -eu
            """
    {% endfor %}

Individual tasks in the workflow can then inherit from these families to run in the desired conda
environment:

.. code-block:: cylc
    :caption: ``flow.cylc``
    :emphasize-lines: 3

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

.. warning:: 
    If you override the `pre-script`_ in a task while inheriting from a conda family task, you will
    lose the conda environment activation.

.. _pre-script: https://cylc.github.io/cylc-doc/8.3.0/html/reference/config/workflow.html#flow.cylc[runtime][%3Cnamespace%3E]pre-script

:file:`dataflow/` and :file:`qc/` directories for results
=========================================================

Our workflow follows the convention described in :ref:`cylc:shared task io paths`. In addition,
the :file:`share/cycle/{{n}}` directories are further divided into :file:`dataflow/` and :file:`qc/`.

* :file:`dataflow/` contains the results of the main workflow tasks. It is used to pass data between
  tasks.
* :file:`qc/` contains quality control results to be analyzed by the user: plots, statistics, etc.

Data tables are stored in plain text CSV files
=======================================================

Intermediary results in :file:`dataflow/` are stored in a delimiter-separated format, using semicolons
as separators. It allows for easy inspection and debugging, as well as compatibility with most
spreadsheet softwares.

Furthermore, they can easily be edited using :command:`awk`/:command:`sed`/:command:`grep`
or :command:`csvkit` without the need to load them as dataframes in Python or R.

Libraries/packages to be favored
================================

* Data wrangling: :bdg-link-success:`csvkit <https://anaconda.org/conda-forge/csvkit>` (CLI),
  :bdg-link-success:`pandas <https://anaconda.org/conda-forge/pandas>` (Python) and
  :bdg-link-success:`tidyverse <https://anaconda.org/conda-forge/r-tidyverse>` (R).
* Data validation: :bdg-link-success:`frictionless <https://anaconda.org/conda-forge/frictionless>`
* Editing/Querying mzML files: :bdg-link-success:`pyopenms <https://anaconda.org/bioconda/pyopenms>`

InfluxDB is an optional dependency
==================================

InfluxDB is used for real-time visualization of the results. It is not a strict requirement for the
workflow to run. It can be enabled by setting
:rose:file:`rose-suite.conf[template variables]cfg__toggle_influxdb` to :strong:`True`.

Data is uploaded to InfluxDB using its Python API. :file:`influx_utils.py` contains functions to
convert our CSV files into the correct upload format.