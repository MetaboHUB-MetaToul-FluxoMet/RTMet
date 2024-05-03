# ⏱ RTMet - Real-Time Metabolomics for Fermenters

🏗 **[WORK IN PROGRESS]** 🏗

RTMet is a data workflow to process FIA-MS data coming from a fermenter, find metabolites and fluxes, and send a feedback command to the fermenter.

![Workflow Diagram](/workflow.png?raw=true "RTMet Workflow")

## 📥 Quick Install

```bash
# install miniforge, or your favorite conda distribution.
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh

# install cylc and setup wrapper script (must be in $PATH)
mamba env create -f environments/cylc.yml
mamba activate cylc
cylc get-resources cylc /usr/local/bin/cylc
chmod +x /usr/local/bin/cylc
ln -s /usr/local/bin/cylc /usr/local/bin/rose
mamba deactivate

# cylc requires `bash`, GNU `coreutils` and `mail` (optional) which are not installed by conda. On MacOS, you can install them using brew
brew install bash coreutils gnu-sed

# install all workflow dependencies
for file in environments/wf-*.yml; do conda env create -n $env_name -f $file; done
mamba activate wf-binner
Rscript -e 'remotes::install_github('aberHRML/binneR')'
mamba deactivate
```

## 📝 User Configuration

Metabolites database `.tsv` file should be put in the `db` directory.

User defined variables are in `external-triggering/flow.cylc` for now :

```ini
[runtime]
    [[root]]
        [[[environment]]]
            BINNER_THRES = 0.85
            DATABASE_FILE = online_12C_NEG_SK_nodup.tsv # should be in the db folder
            MZ_DB = 3 # column number for masses in the database file
            NAMES_DB = 1 # column number for compounds names in the database
            DELTA_TYPE = ppm # either ppm or dalton
            DELTA = 10 # mass tolerance for annotation
```

## 🕹 How to use

**[TO BE WRITTEN]**

## 🚀 Roadmap

- Move user config from `flow.cylc` to a [Rose](https://github.com/cylc/cylc-rose "Cylc-Rose Plugin") Suite Configuration for usability.
- Try building a [Docker](https://www.docker.com/) image for the whole workflow.
- Validate user input when launching the workflow (and assume it is clean in subsequent tasks).
- Clearly define data template for I/O of each tasks, to lower coupling and increase modularity.
