#!/bin/bash

# /usr/local/sbin/autoinstall-workflow-runs.sh

# FR: ce script permet de créer ("installer") automatiquement un nouveau run
# du workflow cylc quand un nouveau dossier apparait dans le répertoire
# $LOCAL_RUNS_DIR.
# Il doit être lancé en tâche cron régulière, couplé à une autre tâche cron
# qui rsync les données de l'exploris120 vers $LOCAL_RUNS_DIR.

# EN: this script allows to automatically create ("install") a new run of the
# cylc workflow when a new folder appears in the $LOCAL_RUNS_DIR directory.
# It must be launched as a regular cron task, coupled with another cron task
# that rsyncs the exploris120 data to $LOCAL_RUNS_DIR.

# Used as: * * * * * root /usr/local/sbin/autoinstall-workflow-runs.sh >> /var/log/autoinstall-workflow-runs.log 2>&1
# See /etc/crontab

LOCAL_RUNS_DIR="/home/heuillet/documents/exploris120_raws/"
WORKFLOW="bioreactor-workflow"
USER="heuillet"

function install_workflows {
    RUNS_DIR=${1%/}
    WORKFLOW_NAME=${2}
    for dir in "${RUNS_DIR}"/*/; do
        # Checklist: is directory, no whitespace, not already installed.
        if [ -d "${dir}" ] &&
            [[ ! "$dir" =~ (\ ) ]] &&
            [ ! -f "${dir}INSTALLED" ] &&
            [ ! -f "${dir}INSTALL_FAILED" ]; then
            echo "Run to be installed: $(basename ${dir})"
            sudo --login --user=${USER} bash -c "cylc install ${WORKFLOW_NAME} -r $(basename ${dir}) && touch ${dir}INSTALLED || touch ${dir}INSTALL_FAILED"

        fi
    done
}

# For testing
# LOCAL_RUNS_DIR="/home/fontain/documents/exploris120_raws/workflow-runs/"

install_workflows ${LOCAL_RUNS_DIR} ${WORKFLOW}

