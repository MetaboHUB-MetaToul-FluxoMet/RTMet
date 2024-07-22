.. _development.add-config_option:

====================================
Adding an item to user configuration
====================================

.. note:: 
    Prerequisites:
      * :ref:`tutorial.user-config`
      * :ref:`reference.user-config`
      * :ref:`development.add-task`

Write a new item in :rose:file:`rose-suite.conf`
================================================

ThermoRawFileParser can output the metadata in text or json format. Right now, the workflow only
outputs metadata in json. We can give the user the option to choose between the two formats.

At the end of the :strong:`[template variables]` section, add the following line:

.. code-block:: ini
    :caption: :file:`rose-suite.conf`

    # ...
    cfg__raw_meta_format = txt

Use the template variable in the workflow definition
====================================================

In the :strong:`[validate_cfg]` task, change the :strong:`metadata` environment variable to:

.. code-block:: jinja
    :caption: :file:`flow.cylc`

    [runtime]
        [[convert_raw]]
            [[[environment]]]
    -           metadata = json
    +           metadata = {{ cfg__raw_meta_format }}

During run installation, the value will now be replaced by the one set in :rose:file:`rose-suite.conf`.
If you want to change the value at runtime, you can follow the instructions in :ref:`tutorial.user-config`.

Validate the new configuration item
===================================

Rose (the configuration manager) allows us to validate the user configuration. It is done at runtime
at cyclepoint 0 with the :strong:`[validate_cfg]` task. Let's add a new validation rule for our item.
Locate the :file:`meta/rose-meta.conf` file in the workflow source directory, and add the following:

.. code-block:: ini

    [template variables=cfg__raw_meta_format]
    compulsory=true
    type=character
    values='json', 'txt'

The :strong:`[validate_cfg]` will now check that the value of :strong:`cfg__raw_meta_format` is
either 'json' or 'txt', and that the item is indeed present.

