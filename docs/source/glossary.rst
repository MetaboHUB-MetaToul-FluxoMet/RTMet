========
Glossary
========

.. glossary::
    :sorted:
    
    workflow run
    run directory
    run
        | A work copy of the workflow source files, located in :file:`~/cylc-run/{workflow name}/{run name}`.
          Workflow runs can be configured individually.
        | In a production setting, each run of the workflow would correspond to a single batch of the
          bioreactor.
          
        .. seealso:: 
          `run directory <run-directory>`__ in Cylc glossary.

    workflow source
    source directory
        | A directory containing a :file:`cylc.flow` file defining a workflow. The directory is used
          as a reference when installing a new :term:`workflow run`.

        .. seealso:: 
          `source directory <source-directory>`__ in Cylc glossary.

    cycle
        | A repeating sequence of tasks. Each cycle correspond to a spectrometer .raw file.

        .. seealso:: 
          `cycle <cycle>`__ in Cylc glossary.

    task
        | An atomic activity of the workflow, for example transforming a .raw file into a .mzML one.
        | A workflow is defined by setting the commands run by tasks, and setting the logical
          dependencies bewteen tasks.

        .. seealso:: 
          `task <task>`__ in Cylc glossary.


.. External links to Cylc glossary:
.. _run-directory: https://cylc.github.io/cylc-doc/8.2.4/html/glossary.html#term-run-directory
.. _source-directory: https://cylc.github.io/cylc-doc/8.2.4/html/glossary.html#term-source-directory
.. _cycle: https://cylc.github.io/cylc-doc/8.2.4/html/glossary.html#term-cycle
.. _task: https://cylc.github.io/cylc-doc/8.2.4/html/glossary.html#term-task