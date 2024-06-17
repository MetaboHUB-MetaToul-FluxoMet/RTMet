Glossary
========

.. glossary::
    :sorted:

    workflow run
    run directory
        | A work copy of the workflow source files, located in :file:`~/cylc-run`. In a production setting, each run of the workflow would correspond to a single batch of the bioreactor.
        | See corresponding `Cylc glossary entry <https://cylc.github.io/cylc-doc/8.2.4/html/glossary.html#term-run-directory>`__.

    cycle
        | A repeating sequence of tasks. Each cycle correspond to a spectrometer .raw file.
        | See corresponding `Cylc glossary entry <https://cylc.github.io/cylc-doc/8.2.4/html/glossary.html#term-cycle>`__.
    
    task
        | An atomic activity of the workflow, for example transforming a .raw file into a .mzML one.
        | See corresponding `Cylc glossary entry <https://cylc.github.io/cylc-doc/8.2.4/html/glossary.html#term-task>`__.