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

- 🟠 Automatically fetch `.raw` files produced by the spectrometer,
- 🟠 Process mass spectrometry data to find present metabolites and quantify them,
- 🔴 Estimate extra-cellular and intra-cellular reaction rates and metabolic fluxes,
- 🟢 Upload results to an InfluxDB instance (optional) to allow real-time plotting and easy query,
- 🔴 Send a feedback command to the bioreactor.

## 📥 Installation

RTMet runs on Unix-like systems including Linux and MacOS. You can find instructions on how to install it [here](https://rtmet.readthedocs.io/en/latest/installation.html).

## 📝 Configuration

User configuration is located in the `config/` directory of the workflow. User-defined variables can be changed in `config.ini`:

```ini
[template variables]
# Necessary parameters
cfg__mol_database='molecules_db.csv'
cfg__spectrometer_id='orbitrap_01'
cfg__tic_threshold=0.50
cfg__ppm_tol=10

# Optional InfluxDB Setup
cfg__toggle_influxdb=False
...
```

The file (`molecules_db.csv`) containing metabolites *m/z* for ions to be matched against should also be edited depending on the metabolome you study.

## 🕹 How to use

RTMet uses [Cylc](https://github.com/cylc/cylc-flow) as a workflow manager. So launching a run of the workflow (e.g. for a fed-batch run of your bioreactor) is simply launching a run of the `bioreactor-workflow` with Cylc.

```bash
# Validate, install, and run the workflow
cylc vip bioreactor-workflow
```

It will copy most of the files contained in `~/cylc-src/bioreactor-workflow/` (source directory) to `~/cylc-run/bioreactor-workflow/run1/` (run directory).

You can monitor the workflow using the Cylc GUI or TUI (terminal user interface).
```bash
# Launch Jupyter Server and open the GUI in your browser
cylc gui bioreactor-workflow

# Or use the TUI
cylc tui bioreactor-workflow
```

The workflow is awaiting for `.raw` files. Right now, it simply looks for them in the `raws/` folder of the run directory.
The raws files you provide should be numbered that way: 
- `yourexperimentname_1.raw`,
- `yourexperimentname_2.raw`,
- ...
- `yourexperimentname_17.raw`
- ...

The workflow will automatically detect the files and process them. Results (metabolites, concentrations, etc) are in `share/cycle/N/` of the run directory. 

## 🪲 Bugs and feature requests

If you have an idea on how we could improve RTMet please submit a new *issue*
to [our GitHub issue tracker](https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet/issues).

## 🚀 Roadmap

- Implement the automatic polling of the spectrometer computer filesystem for new `.raw` files,
- Continuous integration with GitHub Actions,
- Try building a [Docker](https://www.docker.com/) image for the whole workflow,
- Validate user input when launching the workflow (and assume it is clean in subsequent tasks),
- ...

## 📧 Contact

Elliot Fontaine, fontain@insa-toulouse.fr
