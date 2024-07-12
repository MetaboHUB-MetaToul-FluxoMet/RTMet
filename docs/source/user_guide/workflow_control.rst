====================================================
Controlling the workflow using Cylc GUI, TUI and CLI
====================================================

Cylc GUI
--------

:doc:`Cylc GUI <cylc:7-to-8/major-changes/ui>` is a web-based interface that allows
users to interact with the Cylc workflow manager. It provides a graphical representation of the
workflow, allowing users to monitor the progress of tasks, view logs, and control the execution of
the workflow.

.. figure:: /_static/screenshots/cylc-ui-tree-official.png
    :alt: Cylc Graphical User Interface
    :figwidth: 80%
    :align: center

    The GUI displaying a workflow using the "tree" view. @CylcDoc,2024

The GUI is accessible through a web browser, and can be launched by running the ``cylc gui`` command.

    $ cylc gui

This will open a new tab in your default web browser, displaying the Cylc GUI. 

It can be deployed with Jupyter Hub to support remote and multi-user access. This is useful when you
want to access the workflow manager from another computer on the same network. The central server is
started by the ``cylc hub`` command.

.. figure:: /_static/screenshots/cylc-hub-official.png
    :alt: Jupyter Hub authentication page
    :figwidth: 80%
    :align: center

    The Jupyter Hub authentication page in a multi-user setup. @CylcDoc,2024

Cylc TUI
--------

:doc:`Cylc TUI <cylc:7-to-8/major-changes/ui>` is a terminal-based graphical interface
that ports most of Cylc UI's features to the terminal. It provides a beginner-friendly interface when
you're remotely accessing the machine running the workflow, and not exposing a Cylc Hub (JupyterHub)
instance. It requires no setup, and can be opened by running the ``cylc tui`` command.

.. figure:: /_static/screenshots/cylc-tui-preview-official.png
    :alt: Cylc terminal user interface
    :align: center
    :figwidth: 80%

    Tui showing the details of a failed job. @CylcDoc,2024

Cylc CLI
--------

Cylc also provides a command-line interface (CLI) that allows users to interact with the workflow
manager from the terminal. Here's a :ref:`cheat sheet <cylc:user-guide.cheat_sheet>` of major
subcommands.



.. seealso:: 
    :ref:`cylc:Installing-workflows`
    :ref:`cylc:task-job-states`
    :ref:`cylc:user-guide.interventions`
