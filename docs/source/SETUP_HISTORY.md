## Commands used to install the project to the Debian virtual machine

```bash
# Basic utilities not installed by default
sudo apt update && sudo apt upgrade
sudo apt-get install -y git curl
# Additional utilities (optional)
sudo apt-get install -y htop tree tmux tldr
```
### Miniforge Installation
```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"

bash Miniforge3-$(uname)-$(uname -m).sh
# > Miniforge3 will now be installed into this location: /home/fontain/miniforge3
# > installation finished. Do you wish to update your shell profile to automatically initialize conda? >>> [yes]

conda config --set auto_activate_base false
```

### Project Installation
```bash
mkdir ~/github && cd $_
git clone https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet.git
cd RTMet
# Cylc will look for workflows in ~/cylc-src. Linking is advised.
mkdir ~/cylc-src
ln -s $(pwd)/cylc-src/bioreactor-workflow ~/cylc-src/bioreactor-workflow
```

### Cylc setup
```bash
cd cylc-src/bioreactor-workflow/envs # And not environments, to correct in repo README
conda env create -f cylc.yml
conda activate cylc
WRAPPER_DIR='/usr/local/bin'
# As user isn't admin, sudo is required to write in /usr/local/bin
# Issue: when sudo, cylc command not found. -> aliasing using which
CYLC_BIN=$(which cylc)
sudo ${CYLC_BIN} get-resources cylc ${WRAPPER_DIR}
conda deactivate
sudo nano ${WRAPPER_DIR}/cylc # manually uncomment: CYLC_HOME_ROOT_ALT=${HOME}/miniforge3/envs
sudo chmod +x ${WRAPPER_DIR}/cylc
sudo ln -s ${WRAPPER_DIR}/cylc ${WRAPPER_DIR}/rose
sudo chmod +x ${WRAPPER_DIR}/rose
```

### Tasks environments setup
```bash	
for file in wf-*.yml; do conda env create -f $file; done
```
...


## Installation InfluxDB
[See official Documentation](https://docs.influxdata.com/influxdb/v2/install/?t=Linux#install-influxdb-as-a-service-with-systemd)
```bash	
# Ubuntu/Debian AMD64
curl -LO https://download.influxdata.com/influxdb/releases/influxdb2_2.7.6-1_amd64.deb
sudo dpkg -i influxdb2_2.7.6-1_amd64.deb

sudo service influxdb start
sudo service influxdb status

# Create admin user and password and an organization
```