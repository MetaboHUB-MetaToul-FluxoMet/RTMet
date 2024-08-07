.. _glossary:

========
Glossary
========

.. Uses intersphinx mapping to reference Cylc glossary terms.

.. glossary::
    :sorted:
    
    workflow run
    run directory
    run
        | A work copy of the workflow source files, located in :file:`~/cylc-run/{workflow name}/{run name}`.
          Workflow runs can be configured individually.
        | In a production setting, each run of the workflow would correspond to a single batch of the
          bioreactor.
          
        .. seealso:: :term:`cylc:run directory` in Cylc glossary.

    workflow source
    source directory
        | A directory containing a :file:`cylc.flow` file defining a workflow. The directory is used
          as a reference when installing a new :term:`workflow run`.

        .. seealso:: :term:`cylc:source directory` in Cylc glossary.

    cycle
        | A repeating sequence of tasks. Each cycle correspond to a spectrometer .raw file.

        .. seealso:: :term:`cylc:cycle` in Cylc glossary.

    task
        | An atomic activity of the workflow, for example transforming a .raw file into a .mzML one.
        | A workflow is defined by setting the commands run by tasks, and setting the logical
          dependencies bewteen tasks.

        .. seealso:: :term:`cylc:task` in Cylc glossary.
    
    flowgram
        Elution profile in :term:`FIA-MS`, by analogy with the 'chromatogram' in LC-MS. There is no
        column chromatography in FIA-MS
    
    FIA-MS
    FIE-MS
    FIA-HRMS
        | Flow Injection Analysis - High Resolution Mass Spectrometry.
        | A technique based on the injection of a sample into a flow of solvent, which is then 
          directly analyzed by a mass spectrometer.
        
        .. seealso:: `Flow injection analysis  <fia_>`__ on Wikipedia.
