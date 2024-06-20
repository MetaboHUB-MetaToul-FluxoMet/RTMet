=====================
Configuration Options
=====================

.. attention:: 
    🏗 Work in Progress 🏗

User configuration can be found in the :file:`rose-suite.conf` file at the root of the workflow directory.

Change in the :term:`source directory` config file will be passed down to any :term:`workflow run`
that is subsequently installed. Changes in a run directory will only apply to the concerned run after
you use :command:`cylc reload`

.. seealso:: 
    :ref:`user_config_tutorial`

.. rose:file:: rose-suite.conf

    .. autoconfig:: _static/rose-suite.conf