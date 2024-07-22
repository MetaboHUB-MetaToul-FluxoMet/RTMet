# RTMet: Real-Time Metabolomics using Mass Spectrometry
[![Documentation Status](https://readthedocs.org/projects/rtmet/badge/?version=latest)](https://rtmet.readthedocs.io/en/latest/?badge=latest) ![GitHub last commit (branch)](https://img.shields.io/github/last-commit/MetaboHUB-MetaToul-FluxoMet/RTMet/main)


🏗 **[WORK IN PROGRESS]** 🏗

## ⏱ What is RTMet ?

**RTMet is a scientific software which aims to facilitate real-time monitoring of metabolites and reaction rates in a bioreactor.**

At its core, it is a data pipeline for targeted metabolomics that automatically processes raw data coming from a mass spectrometer, find metabolites, estimate fluxes, and send a feedback command to the bioreactor.

The main goals are:
- Allowing researchers to monitor in real time what is happening in the bioreactor, at the chemical level.
- Better control over the growth of micro-organisms and the bioprocesses at play, by automatically changing the bioreactor parameters.

![Workflow Diagram](/workflow.png?raw=true "RTMet Workflow")

## ⭐️ Planned key features

[🔴Todo] [🟠WIP] [🟢Done]

- 🟢 Automatically fetch `.raw` files produced by the spectrometer,
- 🟢 Upload results to an InfluxDB instance (optional) to allow real-time plotting and easy query of the data,
- 🟠 Process mass spectrometry data to find present metabolites and quantify them,
- 🔴 Estimate extra-cellular and intra-cellular reaction rates and metabolic fluxes,
- 🔴 Send a feedback command to the bioreactor.

## 📥 Installation

RTMet runs on Unix-like systems including Linux and MacOS. You can find instructions on [how to install it](https://rtmet.readthedocs.io/en/latest/getting_started/installation.html) in the docs.

## 📝 Configuration

User configuration is in the `rose-suite.conf` file at the root of the workflow directory :

```ini
[template variables]
# Fraction of max(TIC). Only scans above it will be kept by binneR.
cfg__tic_threshold=0.50
# Tolerance (ppm) for metabolite identification.
cfg__ppm_tol=10
# ...
```

The `compounds_db.csv` file in `config/` contains metabolites *m/z* for ions to be matched against. It should also be edited depending on the metabolome you study.

See [Configuring the workflow](https://rtmet.readthedocs.io/en/latest/getting_started/user_config.html) for more info.

## 🕹 How to use

RTMet uses [Cylc](https://github.com/cylc/cylc-flow) as a workflow manager. So launching a run of the workflow (e.g. for a fed-batch run of your bioreactor) is simply launching a run of the `bioreactor-workflow` with Cylc.

```bash
# Validate, install, and run the workflow
cylc vip bioreactor-workflow
```

It will copy most of the files contained in `~/cylc-src/bioreactor-workflow/` (source directory) to `~/cylc-run/bioreactor-workflow/run1/` (run directory).

You can monitor the workflow using the Cylc GUI (web interface) or TUI (terminal user interface).
```bash
# Launch Jupyter Server and open the GUI in your browser
cylc gui bioreactor-workflow

# Or use the TUI
cylc tui bioreactor-workflow
```

The workflow is awaiting for `.raw` files. Right now, it simply looks for them in the `raws/` folder of the run directory.
The raws files you provide should be numbered that way: 

|          |
| -------- |
| yourexperimentname_1.raw  |
| yourexperimentname_2.raw  |
| ...                       |
| yourexperimentname_14.raw |
| ...                       |


The workflow will automatically detect the files and process them. Results (metabolites, concentrations, etc) are in `share/cycle/N/` of the run directory. 

For a more detailed guide, see the [Tutorial](https://rtmet.readthedocs.io/en/latest/getting_started/basic_tutorial.html) in the docs.

## 🪲 Bugs and feature requests

If you have an idea on how we could improve RTMet please submit a new issue
to [our GitHub issue tracker](https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet/issues).

## 📧 Contact

Elliot Fontaine, fontain@insa-toulouse.fr
