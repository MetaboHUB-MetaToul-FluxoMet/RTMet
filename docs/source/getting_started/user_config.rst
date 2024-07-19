.. _tutorial.user-config:

========================
Configuring the workflow
========================

.. highlight:: console

In this tutorial, we'll see how to configure the workflow to change the parameters of bioinformatics
tools. We'll configure it before starting a new :term:`run`, and then make adjustments at runtime.

Editing the user config
=======================

Go to the workflow :term:`source directory`. It should be at :file:`~/cylc-src/bioreactor-workflow`.
Inside, you'll find :file:`rose-suite.conf`, which is a global configuration file for the user:

.. code-block:: ini
    :caption: rose-suite.conf

    [template variables]
    # Fraction of max(TIC). Only scans above it will be kept by binneR.
    cfg__tic_threshold=0.50
    # Tolerance (ppm) for metabolite identification.
    cfg__ppm_tol=10
    # ...

Actually, you may find a tolerance of 10 ppm to be a bit too high. Open the file in a text editor,
and reduce the value of :rose:conf:`rose-suite.conf[template variables]cfg__ppm_tol` to 1.

.. code-block:: diff

    - cfg__ppm_tol=10
    + cfg__ppm_tol=1

Additional input data configuration
===================================

Back to the root of the source directory, you may notice :file:`config/`. This directory contains
additional input data that can be provided by the user, most notably the table :file:`compounds_db.csv`
which holds the list of metabolites for annotations.

Let's add deoxycytidine to it:

.. code-block:: diff
    :caption: compounds_db.csv
    :lineno-start: 227

    mcitrate;bigg_226;mCitrate;C7H710O7;910.5129;[M-H];-1;0.3;13c-glucose;;
    thiamine;;Thiamine;C12H17N4OS;266.11958;[M+H];1;0.3;thiamine;;
    + dcytidine;bigg_227;dCytidine;C9H12N2O5;241.01824;[M-H];-1;0.3;13c-glucose;;

Now, if there is a signal near *241.01824 m/z*, it will be annotated as **dcytidine**.

Processing data with the modified configuration
===============================================

Now, let's start a new :term:`run` of the workflow. This time, we're gonna use the composed command
:command:`cylc vip` (Validate, Install and Play) which both creates the run and starts it.
Additionally, we'll choose a custom name for our run::

    $ cylc vip bioreactor-workflow --run-name=config-tutorial
    cylc validate ~/cylc-src/bioreactor-workflow
        Valid for cylc-8.2.4
    cylc install ~/cylc-src/bioreactor-workflow
        INSTALLED bioreactor-workflow/config-tutorial from ~/cylc-src/bioreactor-workflow
    cylc play bioreactor-workflow/config-tutorial
        2024-06-18T10:12:14+02:00 INFO - Extracting job.sh to ~/cylc-run/bioreactor-workflow/config-tutorial/.service/etc/job.sh
        bioreactor-workflow/config-tutorial: your-computer.local PID=44662

.. warning:: 
    | This won't work if you still have the :file:`run1/` in :file:`~/cylc-run/bioreactor-workflow/` 
      from the previous tutorial.
    | You have to commit to automatically numbered names (run1, run2, ...) or user-defined names.
      Either way, :file:`~/cylc-run/bioreactor-workflow/` has to be cleaned beforehand.


Make sure this workflow run has the updated configuration::

    $ cylc config bioreactor-workflow/config-tutorial | grep 'ppm_tol ='
    ppm_tol = 1

We're gonna analyse the same raw data we used during the :ref:`tutorial <tutorial-raws>`. As before,
copy :file:`std_30sec_CarboAmmo_10mM_01.raw` into the :file:`raws/` subfolder of the :term:`run directory`.
You can monitor that the file is correctly processed using the TUI.

Once it's done, go look at :file:`std_30sec_CarboAmmo_10mM_01.matches.csv` located in
:file:`./share/cycle/1/dataflow/`. If you look at the values in the *delta_ppm* column, you'll see
that they all in the ]-1,1[ interval.

Maybe a tolerance of 1 ppm was a bit too stringent. We're probably getting a lot of false-negatives.
We're gonna change the configuration while :file:`bioreactor-workflow/config-tutorial` is still running.

Changing the config at runtime
==============================

Reinstalling the source and its config
--------------------------------------

Edit back :file:`rose-suite.conf` from the source directory.

.. code-block:: diff

    - cfg__ppm_tol=1
    + cfg__ppm_tol=5

Then, you can broadcast the change you made in the source to the **config-tutorial** run using the
:command:`cylc vr` composed command::

    $ cylc vr --yes bioreactor-workflow/config-tutorial
    cylc validate --against-source bioreactor-workflow/config-test
      Valid for cylc-8.2.4
    cylc reinstall bioreactor-workflow/config-test
      REINSTALLED bioreactor-workflow/config-test from /Users/elliotfontaine/Documents/github/RTMet/cylc-src/bioreactor-workflow
      Successfully reinstalled.
    cylc reload bioreactor-workflow/config-test
      Done

And verify it has been correctly updated::

    $ cylc config bioreactor-workflow/config-tutorial | grep 'ppm_tol ='
    ppm_tol = 5

.. note:: 
    You can also use the **reinstall-reload** button inside the context menu of the TUI.

Reloading the run config file
-----------------------------

In the run directory, locate the copy of :file:`rose-suite.conf`. Ignoring
the fact that the config options are disordered, find the annotation tolerance and change its value.

.. code-block:: diff

    - cfg__ppm_tol=5
    + cfg__ppm_tol=20

Now, reload the configuration and check that the config is correctly updated::

    $ cylc reload bioreactor-workflow/config-tutorial
    Done
    $ cylc config bioreactor-workflow/config-tutorial | grep 'ppm_tol ='
    ppm_tol = 20

.. note:: 
    You can also use the **reload** button inside the context menu of the TUI.

This will propagate to any new annotation :term:`task`, but it won't redo the one for
:file:`std_30sec_CarboAmmo_10mM_01.raw`.

This edit only applies to the **config-tutorial** run, any new run installed will copy the config
file in the source directory.
