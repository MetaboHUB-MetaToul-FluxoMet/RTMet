# How to autodoc the workflow

`cylc list bioreactor-workflow/test-meta// --all-namespaces --mro --against-source`
will get a list of tasks (one per line) in the source workflow configuration file (`flow.cylc`)

`cylc show --json bioreactor-workflow/test-meta --task-def=_catch_raw --task-def=convert_raw`
Previous list can be used to build this command (many `--task-def`).