# RTMet: Real-Time Metabolomics using Mass Spectrometry

🏗 **[WORK IN PROGRESS]** 🏗

## ⏱ What is RTMet ?

**RTMet is a scientific software which aims to facilitate real-time monitoring of metabolites and reaction rates in a fermenter.**

At its core, it is a data pipeline for targeted metabolomics that automatically processes raw data coming from a mass spectrometer, find metabolites, estimate fluxes, and send a feedback command to the fermenter.

The main goals are:
- Allowing researchers to monitor in real time what is happening in the fermenter, at the chemical level.
- Better control over the growth of micro-organisms and the bioprocesses at play, by automatically changing the fermenter parameters.

![Workflow Diagram](/workflow.png?raw=true "RTMet Workflow")

## ⭐️ Planned key features

[🔴Todo] [🟠WIP] [🟢Done]

- 🟠 Automatically fetch `.raw` files produced by the spectrometer,
- 🟠 Process mass spectrometry data to find present metabolites and quantify them,
- 🔴 Estimate extra-cellular and intra-cellular reaction rates and metabolic fluxes,
- 🟢 Upload results to an InfluxDB instance (optional) to allow real-time plotting and easy query,
- 🔴 Send a feedback command to the fermenter.

## 📥 Quick Install

RTMet runs on Unix-like systems including Linux and MacOS.

```bash
# Install your favorite conda distribution. We'll choose miniforge
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh

# Download the latest release of RTMet (TODO).
curl -L -O "https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet/releases/latest/download/workflow.tar.gz"
# Or clone this repository default branch.
git clone https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet.git
cd RTMet

# Create a symbolic link for Cylc to find the workflow
mkdir ~/cylc-src
ln -s cylc-src/bioreactor-workflow ~/cylc-src/bioreactor-workflow 

# Install Cylc and setup the wrapper scripts
cd cylc-src/bioreactor-workflow/environments
conda env create -f cylc.yml
WRAPPER_DIR='/usr/local/bin' # Or somewhere else in your $PATH
conda activate cylc
cylc get-resources cylc ${WRAPPER_DIR}/cylc
conda deactivate
chmod +x ${WRAPPER_DIR}/cylc
ln -s ${WRAPPER_DIR}/cylc ${WRAPPER_DIR}/rose

# Cylc requires `bash`, GNU `coreutils` and `mail` (optional), which are not installed by Conda.
# You may already have them on your system.
# On MacOS, you can install them using brew.
brew install bash coreutils gnu-sed

# Create Conda environments used by workflow tasks
for file in wf-*.yml; do conda env create -n $env_name -f $file; done
conda activate wf-binner
Rscript -e 'remotes::install_github('aberHRML/binneR')'
conda deactivate
```

If you plan to use InfluxDB to store and visualize the results, you can find the installation instructions [here] (RTMet documentation, TODO).

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

RTMet uses [Cylc](https://github.com/cylc/cylc-flow) as a workflow manager. So launching a run of the workflow (e.g. for a fed-batch run of your fermenter) is simply launching a run of the `bioreactor-workflow` with Cylc.

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


## 🚀 Roadmap

- Implement the automatic polling of the spectrometer computer filesystem for new `.raw` files,
- Continuous integration with GitHub Actions,
- Try building a [Docker](https://www.docker.com/) image for the whole workflow,
- Validate user input when launching the workflow (and assume it is clean in subsequent tasks),
- ...
