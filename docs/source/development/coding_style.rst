.. _development.coding-style:

==========================================
Coding styles for Python, R, Bash and Cylc
==========================================

Scripts: environment variables or command line arguments?
=========================================================

When writing scripts (Python, R, Bash) for the workflow, you have the choice between loading
environment variables from inside the script, or parsing command line arguments.

On a rule of thumb, use environment variables when you don't expect the script to be reused outside
the workflow, and command line arguments when you want to make the script more portable.

Python
======

Python code should follow the `PEP 8`_ style guide. The `Black`_ code formatter should be used to
automatically format the code.

You should also use a linter / static code analyser like `Pylint`_ to catch potential bugs, commented
out code, code smells, etc.

R 
=
[TODO]

Bash
====
[TODO]

Cylc
====

In general, follow Cylc :doc:`cylc:workflow-design-guide/style-guide`. When creating tasks,
set the :strong:`[meta]` title and description fields to describe what the task does. You can also
add custom field like :strong:`categories` if you want.

Use uppercase for:
    * family tasks (notably the conda ones, e.g. :strong:`CONDA_OPENMS`),
    * global environment variables set in :strong:`[runtime][root]` and broadcasted ones (e.g.
      :strong:`RAWFILE_STEM`).

Use lowercase for:
    * local environment variables set in :strong:`[environment]` blocks inside tasks.
    * task names.

Add :strong:`None` before the name of inherited family tasks to make the task in question appear at
the root when using the TUI or GUI. Otherwise, the task will be nested under the family task. The
exception are InfluxDB tasks, which are always nested under the :strong:`INFLUXDB` family task.


When using global environment variables or Jinja2 template variables to build CLI arguments,
do it in the :strong:`[environment]` block of the task, not in the script itself:

.. code-block:: cylc
    :caption: :file:`flow.cylc`
    :emphasize-lines: 4, 7-9

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
