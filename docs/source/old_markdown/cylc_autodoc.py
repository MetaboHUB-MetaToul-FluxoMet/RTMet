"""
Script to automatically generate documentation for Cylc workflow tasks.
"""

import json
from optparse import Values
from cylc.flow.config import WorkflowConfig, OrderedDictWithDefaults

workflow_config = WorkflowConfig(
    "bioreactor-workflow",
    "/Users/elliotfontaine/cylc-src/bioreactor-workflow/flow.cylc",
    Values(),
)

# for task, config in workflow_config.cfg.get("runtime").items():
#     print(task, ": ", str(config["meta"]["title"]))

# task, config = next(iter(workflow_config.cfg.get("runtime").items()))
# print(task, str(config["environment"]))

# task = workflow_config.cfg.get("runtime")["convert_raw"]
# print(task["environment"]["metadata"])

runtime: OrderedDictWithDefaults = workflow_config.cfg.get("runtime")["convert_raw"]
jsoned = json.dumps(runtime)
print(jsoned)
