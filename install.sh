#!/usr/bin/env bash
#
# RTMet Installer script
#
# Copyright (c) 2024 MetaboHUB-MetaToul-FluxoMet
# Author: Elliot Fontaine
# GNU General Public License v3.0
# https://www.gnu.org/licenses/gpl-3.0.html
#
# Based on 'shell-scripting-templates' by Nathaniel Landau
# https://github.com/natelandau/shell-scripting-templates
# MIT License
# Copyright (c) 2021 Nathaniel Landau
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

_mainScript_() {

    # Replace everything in _mainScript_() with your script's code
    # header "Showing alert colors"
    # debug "This is debug text"
    # info "This is info text"
    # notice "This is notice text"
    # dryrun "This is dryrun text"
    # warning "This is warning text"
    # error "This is error text"
    # success "This is success text"
    # input "This is input text"

    echo
    header "Welcome to RTMet's installer script !"

    debug "OS: $(_detectOS_)"
    if [[ $(_detectOS_) == "windows" ]]; then
        error "RTMet does not support Windows. Exiting."
        return 1
    fi

    if ! _isInternetAvailable_; then
        error "No internet connection detected. Exiting."
        return 1
    fi

    if _rootAvailable_; then
        debug "Root access available."
    else
        info "No root access available."
        warning "Root access is required to install Cylc's wrapper script to /usr/local/bin."
        if ! _seekConfirmation_ "Do you wish to proceed anyway?"; then
            return 1
        fi
    fi

    # if _detectInteractiveguard_ "${HOME}/.bashrc"; then
    #     error "Interactive guard detected in ${HOME}/.bashrc. Exiting."
    #     return 1
    # fi

    info "Checking for local Conda installation:"
    # force miniforge install (to fix Github Actions shenanigans)
    #if _commandExists_ conda; then
    if false; then
        info "↪ Conda is already installed."
        local _conda
        _conda=$(command -v conda)
    else
        notice "Conda is not installed."
        if ! _seekConfirmation_ "Do you want to install Miniforge3?"; then
            error "Conda is required to install and run RTMet. Exiting."
            return 1
        fi
        local _conda="${DEFAULT_MINIFORGE_PREFIX}/condabin/conda"
        _installMiniforge_ "${DEFAULT_MINIFORGE_PREFIX}"
        info "↪ The miniforge distribution has been installed to ${DEFAULT_MINIFORGE_PREFIX}."
    fi

    debug "$(${_conda} info)"
    _execute_ "${_conda} config --set auto_activate_base false ${VFLAG}"

    info "Downloading Workflow from GitHub repository..."
    _downloadFile_ ${WORKFLOW_ZIP}
    workflow=$(basename ${WORKFLOW_ZIP} .zip)
    info "Moving workflow to ${HOME}/cylc-src/"
    _execute_ "unzip \"${workflow}\".zip"
    _execute_ "rm \"${workflow}\".zip"
    _execute_ "mkdir ${HOME}/cylc-src"
    _execute_ "mv \"${workflow}\" ${HOME}/cylc-src/"

    local _envTemplates=${HOME}/cylc-src/"${workflow}"/envs
    info "Creating Cylc conda environment."
    _createCondaEnv_ "${_envTemplates}"/cylc.yml

    info "Setting up Cylc wrapper script."
    if _rootAvailable_; then
        # _runAsRoot_ _setupCylcWrapper_ "${DEFAULT_WRAPPERS_DIR_SYS}"
        _setupCylcWrapper_ "${DEFAULT_WRAPPERS_DIR_SYS}"
    else
        _setupCylcWrapper_ "${DEFAULT_WRAPPERS_DIR_USR}"
        if ! _inUserPath_ "${DEFAULT_WRAPPERS_DIR_USR}"; then
            debug "The user's PATH does not contain ${DEFAULT_WRAPPERS_DIR_USR}."
            if [[ $(_detectOS_) == "mac" ]]; then
                _execute_ "echo 'export PATH=\"${DEFAULT_WRAPPERS_DIR_USR}:\$PATH\"' >> ${HOME}/.bash_profile"
            else
                _execute_ "echo 'export PATH=\"${DEFAULT_WRAPPERS_DIR_USR}:\$PATH\"' >> ${HOME}/.bashrc"
            fi
        fi
    fi

    # For now, do dryrun check instead of wrapping in _execute_
    info "Installing tasks' conda environments."
    if ! ${DRYRUN}; then
        local _taskEnvs
        local _envCount
        _taskEnvs=$(_listFiles_ glob "wf-*.yml" "${_envTemplates}")
        info "Task environments: ${_taskEnvs}"
        _envCount=$(echo "${_taskEnvs}" | wc -l)
        for env in ${_taskEnvs}; do
            _createCondaEnv_ "${env}"
            _progressBar_ "${_envCount}" "${env}"
        done
    else
        dryrun "Dry-run mode enabled. Skipping task environments installation."
    fi

    if ${DRYRUN}; then
        dryrun "RTMet would (could?) have been successfully installed."
        return 0
    fi
    success "RTMet has been successfully installed."
}
# end _mainScript_

# ################################## Flags and defaults
# Required variables
LOGFILE="${HOME}/logs/$(basename "$0").log"
QUIET=false
LOGLEVEL=ERROR
VERBOSE=false
FORCE=false
DRYRUN=false
declare -a ARGS=()

# Script specific
VFLAG=""
[[ ${VERBOSE} == true ]] && VFLAG="--verbose"
# FFLAG=""
# [[ ${FORCE} == true ]] && FFLAG="--force"
#RTMET_VERSION=0.1.0
WORKFLOW_ZIP=https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet/releases/download/alpha/bioreactor-workflow.zip
DEFAULT_MINIFORGE_PREFIX=${HOME}/miniforge3
DEFAULT_WRAPPERS_DIR_USR=${HOME}/.local/bin
DEFAULT_WRAPPERS_DIR_SYS=/usr/local/bin

# ################################## Custom utility functions (RTMet)

_downloadFile_() {
    local _url=$1
    if _commandExists_ curl; then
        _execute_ "curl -LO \"${_url}\" ${VFLAG}"
    elif _commandExists_ wget; then
        _execute_ "wget \"${_url}\" ${VFLAG}"
    else
        error "Neither curl nor wget is installed. Exiting."
        return 1
    fi
}

_installMiniforge_() {
    local _prefix
    local _miniforgeScript
    local _scriptUrl
    _prefix=$1
    _miniforgeScript="Miniforge3-$(uname)-$(uname -m).sh"
    _scriptUrl="https://github.com/conda-forge/miniforge/releases/latest/download/${_miniforgeScript}"
    _downloadFile_ "${_scriptUrl}"
    if [ "$FORCE" = true ]; then
        _execute_ "bash \"${_miniforgeScript}\" -p \"${_prefix}\" ${VFLAG} -b"
    else
        _execute_ "bash \"${_miniforgeScript}\" -p \"${_prefix}\" ${VFLAG}"
    fi
    _execute_ "rm \"${_miniforgeScript}\""
    _execute_ "${_conda} init ${VFLAG}"
}

_createCondaEnv_() {
    local _envFile=$1
    _execute_ "${_conda} env create -f \"${_envFile}\" ${VFLAG}"
}

_setupCylcWrapper_() {
    local _targetDir
    local _condaEnvsPrefix
    _targetDir="$1"
    _condaEnvsPrefix="$(${_conda} info --base)/envs"
    _execute_ "mkdir -p ${_targetDir}"
    _execute_ "${_conda} run -n cylc cylc get-resources cylc ${_targetDir}"
    _execute_ "chmod +x ${_targetDir}/cylc"
    _execute_ "sed -i \"s|^CYLC_HOME_ROOT=.*|CYLC_HOME_ROOT=${_condaEnvsPrefix}|\" ${_targetDir}/cylc"
    _execute_ "ln -s ${_targetDir}/cylc ${_targetDir}/rose"
}

_detectInteractiveguard_() {
    # DESC:
    #         Detect if a rc file contains the interactive guard.
    # ARGS:
    #         $1 (Required) - The rc file to search
    # OUTS:
    #         0 if true
    #         1 if false
    # USAGE:
    #         _detectInteractiveguard
    local _rcFile="$1"

    if [ ! -f "$_rcFile" ]; then
        warning "File not found: $_rcFile"
        return 1
    fi

    # Define the code block to search for
    local _codeBlock="# If not running interactively, don't do anything
case \$- in
    *i*) ;;
      *) return;;
esac"

    # Search for the code block in the .bashrc file
    if grep -qF "$_codeBlock" "$_rcFile"; then
        warning "Interactive block detected in $_rcFile"
        debug "Interactive block: $_codeBlock"
        debug "$(cat "${_rcFile}")"
        return 0
    else
        debug "Interactive block not found in $_rcFile"
        return 1
    fi
}

_inUserPath_() {
    # DESC:
    #         Check if the given directory is in the user's PATH
    # ARGS:
    #         $1 (required): The directory to check
    # OUTS:
    #         Returns 0 if the directory is in the PATH, 1 otherwise

    local dir="$1"

    if [[ -z "$dir" ]]; then
        echo "Missing required argument: directory path"
        return 1
    fi

    # Loop through each element in the PATH
    IFS=":" read -r -a path_array <<<"$PATH"
    for path in "${path_array[@]}"; do
        if [[ "$path" == "$dir" ]]; then
            return 0
        fi
    done

    return 1
}

# ################################## Custom utility functions (Pasted from official repository)

_detectOS_() {
    # DESC:
    #					Identify the OS the script is run on
    # ARGS:
    #					None
    # OUTS:
    #					0 - Success
    #					1 - Failed to detect OS
    #					stdout: One of 'mac', 'linux', 'windows'
    # USAGE:
    #					_detectOS_
    # CREDIT:
    #         https://github.com/labbots/bash-utility

    local _uname
    local _os
    if _uname=$(command -v uname); then
        case $("${_uname}" | tr '[:upper:]' '[:lower:]') in
        linux*)
            _os="linux"
            ;;
        darwin*)
            _os="mac"
            ;;
        msys* | cygwin* | mingw* | nt | win*)
            # or possible 'bash on windows'
            _os="windows"
            ;;
        *)
            return 1
            ;;
        esac
    else
        return 1
    fi
    printf "%s" "${_os}"

}

_commandExists_() {
    # DESC:
    #         Check if a binary exists in the search PATH
    # ARGS:
    #         $1 (Required) - Name of the binary to check for existence
    # OUTS:
    #         0 if true
    #         1 if false
    # USAGE:
    #         (_commandExists_ ffmpeg ) && [SUCCESS] || [FAILURE]

    [[ $# == 0 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    if ! command -v "$1" >/dev/null 2>&1; then
        debug "Did not find dependency: '${1}'"
        return 1
    fi
    return 0
}

_execute_() {
    # DESC:
    #         Executes commands while respecting global DRYRUN, VERBOSE, LOGGING, and QUIET flags
    # ARGS:
    #         $1 (Required) - The command to be executed.  Quotation marks MUST be escaped.
    #         $2 (Optional) - String to display after command is executed
    # OPTS:
    #         -v    Always print output from the execute function to STDOUT
    #         -n    Use NOTICE level alerting (default is INFO)
    #         -p    Pass a failed command with 'return 0'.  This effectively bypasses set -e.
    #         -e    Bypass _alert_ functions and use 'printf RESULT'
    #         -s    Use '_alert_ success' for successful output. (default is 'info')
    #         -q    Do not print output (QUIET mode)
    # OUTS:
    #         stdout: Configurable output
    # USE :
    #         _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message"
    #         _execute_ -sv "mkdir \"some/dir\""
    # NOTE:
    #         If $DRYRUN=true, no commands are executed and the command that would have been executed
    #         is printed to STDOUT using dryrun level alerting
    #         If $VERBOSE=true, the command's native output is printed to stdout. This can be forced
    #         with '_execute_ -v'

    local _localVerbose=false
    local _passFailures=false
    local _echoResult=false
    local _echoSuccessResult=false
    local _quietMode=false
    local _echoNoticeResult=false
    local opt

    local OPTIND=1
    while getopts ":vVpPeEsSqQnN" opt; do
        case ${opt} in
        v | V) _localVerbose=true ;;
        p | P) _passFailures=true ;;
        e | E) _echoResult=true ;;
        s | S) _echoSuccessResult=true ;;
        q | Q) _quietMode=true ;;
        n | N) _echoNoticeResult=true ;;
        *)
            {
                error "Unrecognized option '$1' passed to _execute_. Exiting."
                _safeExit_
            }
            ;;
        esac
    done
    shift $((OPTIND - 1))

    [[ $# == 0 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local _command="${1}"
    local _executeMessage="${2:-$1}"

    local _saveVerbose=${VERBOSE}
    if "${_localVerbose}"; then
        VERBOSE=true
    fi

    if "${DRYRUN:-}"; then
        if "${_quietMode}"; then
            VERBOSE=${_saveVerbose}
            return 0
        fi
        if [ -n "${2:-}" ]; then
            dryrun "${1} (${2})" "$(caller)"
        else
            dryrun "${1}" "$(caller)"
        fi
    elif ${VERBOSE:-}; then
        if eval "${_command}"; then
            if "${_quietMode}"; then
                VERBOSE=${_saveVerbose}
            elif "${_echoResult}"; then
                printf "%s\n" "${_executeMessage}"
            elif "${_echoSuccessResult}"; then
                success "${_executeMessage}"
            elif "${_echoNoticeResult}"; then
                notice "${_executeMessage}"
            else
                info "${_executeMessage}"
            fi
        else
            if "${_quietMode}"; then
                VERBOSE=${_saveVerbose}
            elif "${_echoResult}"; then
                printf "%s\n" "warning: ${_executeMessage}"
            else
                warning "${_executeMessage}"
            fi
            VERBOSE=${_saveVerbose}
            "${_passFailures}" && return 0 || return 1
        fi
    else
        if eval "${_command}" >/dev/null 2>&1; then
            if "${_quietMode}"; then
                VERBOSE=${_saveVerbose}
            elif "${_echoResult}"; then
                printf "%s\n" "${_executeMessage}"
            elif "${_echoSuccessResult}"; then
                success "${_executeMessage}"
            elif "${_echoNoticeResult}"; then
                notice "${_executeMessage}"
            else
                info "${_executeMessage}"
            fi
        else
            if "${_quietMode}"; then
                VERBOSE=${_saveVerbose}
            elif "${_echoResult}"; then
                printf "%s\n" "error: ${_executeMessage}"
            else
                warning "${_executeMessage}"
            fi
            VERBOSE=${_saveVerbose}
            "${_passFailures}" && return 0 || return 1
        fi
    fi
    VERBOSE=${_saveVerbose}
    return 0
}

# shellcheck disable=SC2120
_rootAvailable_() {
    # DESC:
    #         Validate we have superuser access as root (via sudo if requested)
    # ARGS:
    #         $1 (optional): Set to any value to not attempt root access via sudo
    # OUTS:
    #         0 if true
    #         1 if false
    # CREDIT:
    #         https://github.com/ralish/bash-script-template

    local _superuser

    if [[ ${EUID} -eq 0 ]]; then
        _superuser=true
    elif [[ -z ${1-} ]]; then
        debug 'Sudo: Updating cached credentials ...'
        if sudo -v; then
            if [[ $(sudo -H -- "${BASH}" -c 'printf "%s" "$EUID"') -eq 0 ]]; then
                _superuser=true
            else
                _superuser=false
            fi
        else
            _superuser=false
        fi
    fi

    if [[ ${_superuser} == true ]]; then
        debug 'Successfully acquired superuser credentials.'
        return 0
    else
        debug 'Unable to acquire superuser credentials.'
        return 1
    fi
}

_runAsRoot_() {
    # DESC:
    #         Run the requested command as root (via sudo if requested)
    # ARGS:
    #         $1 (optional): Set to zero to not attempt execution via sudo
    #         $@ (required): Passed through for execution as root user
    # OUTS:
    #         Runs the requested command as root
    # CREDIT:
    #         https://github.com/ralish/bash-script-template

    [[ $# == 0 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local _skip_sudo=false

    if [[ ${1} =~ ^0$ ]]; then
        _skip_sudo=true
        shift
    fi

    if [[ ${EUID} -eq 0 ]]; then
        "$@"
    elif [[ -z ${_skip_sudo} ]]; then
        sudo -H -- "$@"
    else
        fatal "Unable to run requested command as root: $*"
    fi
}

_seekConfirmation_() {
    # DESC:
    #         Seek user input for yes/no question
    # ARGS:
    #         $1 (Required) - Question being asked
    # OUTS:
    #         0 if answer is "yes"
    #         1 if answer is "no"
    # USAGE:
    #         _seekConfirmation_ "Do something?" && printf "okay" || printf "not okay"
    #         OR
    #         if _seekConfirmation_ "Answer this question"; then
    #           something
    #         fi

    [[ $# == 0 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local _yesNo
    input "${1}"
    if "${FORCE:-}"; then
        debug "Forcing confirmation with '--force' flag set"
        printf "%s\n" " "
        return 0
    else
        while true; do
            read -r -p " (y/n) " _yesNo
            case ${_yesNo} in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) input "Please answer yes or no." ;;
            esac
        done
    fi
}

_isInternetAvailable_() {
    # DESC:
    #         Check if internet connection is available
    # ARGS:
    #         None
    # OUTS:
    #					0 - Success: Internet connection is available
    #					1 - Failure: Internet connection is not available
    #					stdout:
    # USAGE:
    #					_isInternetAvailable_

    local _checkInternet
    if [[ -t 1 || -z ${TERM} ]]; then
        _checkInternet="$(sh -ic 'exec 3>&1 2>/dev/null; { curl --compressed -Is google.com 1>&3; kill 0; } | { sleep 10; kill 0; }' || :)"
    else
        _checkInternet="$(curl --compressed -Is google.com -m 10)"
    fi
    if [[ -z ${_checkInternet-} ]]; then
        return 1
    fi
}

_listFiles_() {
    # DESC:
    #         Find files in a directory.  Use either glob or regex
    # ARGS:
    #         $1 (Required) - 'g|glob' or 'r|regex'
    #         $2 (Required) - pattern to match
    #         $3 (Optional) - directory (defaults to .)
    # OUTS:
    #         0: if files found
    #         1: if no files found
    #         stdout: List of files
    # NOTE:
    #         Searches are NOT case sensitive and MUST be quoted
    # USAGE:
    #         _listFiles_ glob "*.txt" "some/backup/dir"
    #         _listFiles_ regex ".*\.[sha256|md5|txt]" "some/backup/dir"
    #         readarray -t array < <(_listFiles_ g "*.txt")

    [[ $# -lt 2 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local _searchType="${1}"
    local _pattern="${2}"
    local _directory="${3:-.}"
    local _fileMatch
    declare -a _matchedFiles=()

    case "${_searchType}" in
    [Gg]*)
        while read -r _fileMatch; do
            _matchedFiles+=("$(realpath "${_fileMatch}")")
        done < <(find "${_directory}" -maxdepth 1 -iname "${_pattern}" -type f | sort)
        ;;
    [Rr]*)
        while read -r _fileMatch; do
            _matchedFiles+=("$(realpath "${_fileMatch}")")
        done < <(find "${_directory}" -maxdepth 1 -regextype posix-extended -iregex "${_pattern}" -type f | sort)
        ;;
    *)
        fatal "_listFiles_: Could not determine if search was glob or regex"
        ;;
    esac

    if [[ ${#_matchedFiles[@]} -gt 0 ]]; then
        printf "%s\n" "${_matchedFiles[@]}"
        return 0
    else
        return 1
    fi
}

_progressBar_() {
    # DESC:
    #         Prints a progress bar within a for/while loop. For this to work correctly you
    #         MUST know the exact number of iterations. If you don't know the exact number use _spinner_
    # ARGS:
    #         $1 (Required) - The total number of items counted
    #         $2 (Optional) - The optional title of the progress bar
    # OUTS:
    #         stdout: progress bar
    # USAGE:
    #         for i in $(seq 0 100); do
    #             sleep 0.1
    #             _progressBar_ "100" "Counting numbers"
    #         done

    [[ $# == 0 ]] && return   # Do nothing if no arguments are passed
    (${QUIET:-}) && return    # Do nothing in quiet mode
    (${VERBOSE:-}) && return  # Do nothing if verbose mode is enabled
    [ ! -t 1 ] && return      # Do nothing if the output is not a terminal
    [[ ${1} == 1 ]] && return # Do nothing with a single element

    local _n="${1}"
    local _width=30
    local _barCharacter="#"
    local _percentage
    local _num
    local _bar
    local _progressBarLine
    local _barTitle="${2:-Running Process}"

    ((_n = _n - 1))

    # Reset the count
    [ -z "${PROGRESS_BAR_PROGRESS:-}" ] && PROGRESS_BAR_PROGRESS=0

    # Hide the cursor
    tput civis

    if [[ ! ${PROGRESS_BAR_PROGRESS} -eq ${_n} ]]; then

        # Compute the percentage.
        _percentage=$((PROGRESS_BAR_PROGRESS * 100 / $1))

        # Compute the number of blocks to represent the percentage.
        _num=$((PROGRESS_BAR_PROGRESS * _width / $1))

        # Create the progress bar string.
        _bar=""
        if [[ ${_num} -gt 0 ]]; then
            _bar=$(printf "%0.s${_barCharacter}" $(seq 1 "${_num}"))
        fi

        # Print the progress bar.
        _progressBarLine=$(printf "%s [%-${_width}s] (%d%%)" "  ${_barTitle}" "${_bar}" "${_percentage}")
        printf "%s\r" "${_progressBarLine}"

        PROGRESS_BAR_PROGRESS=$((PROGRESS_BAR_PROGRESS + 1))

    else
        # Replace the cursor
        tput cnorm

        # Clear the progress bar when complete
        printf "\r\033[0K"

        unset PROGRESS_BAR_PROGRESS
    fi

}

# ################################## Functions required for this template to work

_setColors_() {
    # DESC:
    #         Sets colors use for alerts.
    # ARGS:
    #         None
    # OUTS:
    #         None
    # USAGE:
    #         printf "%s\n" "${blue}Some text${reset}"

    if tput setaf 1 >/dev/null 2>&1; then
        bold=$(tput bold)
        underline=$(tput smul)
        reverse=$(tput rev)
        reset=$(tput sgr0)

        if [[ $(tput colors) -ge 256 ]] >/dev/null 2>&1; then
            white=$(tput setaf 231)
            blue=$(tput setaf 38)
            yellow=$(tput setaf 11)
            green=$(tput setaf 82)
            red=$(tput setaf 9)
            purple=$(tput setaf 171)
            gray=$(tput setaf 250)
        else
            white=$(tput setaf 7)
            blue=$(tput setaf 38)
            yellow=$(tput setaf 3)
            green=$(tput setaf 2)
            red=$(tput setaf 9)
            purple=$(tput setaf 13)
            gray=$(tput setaf 7)
        fi
    else
        bold="\033[4;37m"
        reset="\033[0m"
        underline="\033[4;37m"
        # shellcheck disable=SC2034
        reverse=""
        white="\033[0;37m"
        blue="\033[0;34m"
        yellow="\033[0;33m"
        green="\033[1;32m"
        red="\033[0;31m"
        purple="\033[0;35m"
        gray="\033[0;37m"
    fi
}

_alert_() {
    # DESC:
    #         Controls all printing of messages to log files and stdout.
    # ARGS:
    #         $1 (required) - The type of alert to print
    #                         (success, header, notice, dryrun, debug, warning, error,
    #                         fatal, info, input)
    #         $2 (required) - The message to be printed to stdout and/or a log file
    #         $3 (optional) - Pass '${LINENO}' to print the line number where the _alert_ was triggered
    # OUTS:
    #         stdout: The message is printed to stdout
    #         log file: The message is printed to a log file
    # USAGE:
    #         [_alertType] "[MESSAGE]" "${LINENO}"
    # NOTES:
    #         - The colors of each alert type are set in this function
    #         - For specified alert types, the funcstac will be printed

    local _color
    local _alertType="${1}"
    local _message="${2}"
    local _line="${3:-}" # Optional line number

    [[ $# -lt 2 ]] && fatal 'Missing required argument to _alert_'

    if [[ -n ${_line} && ${_alertType} =~ ^(fatal|error) && ${FUNCNAME[2]} != "_trapCleanup_" ]]; then
        _message="${_message} ${gray}(line: ${_line}) $(_printFuncStack_)"
    elif [[ -n ${_line} && ${FUNCNAME[2]} != "_trapCleanup_" ]]; then
        _message="${_message} ${gray}(line: ${_line})"
    elif [[ -z ${_line} && ${_alertType} =~ ^(fatal|error) && ${FUNCNAME[2]} != "_trapCleanup_" ]]; then
        _message="${_message} ${gray}$(_printFuncStack_)"
    fi

    if [[ ${_alertType} =~ ^(error|fatal) ]]; then
        _color="${bold}${red}"
    elif [ "${_alertType}" == "info" ]; then
        _color="${gray}"
    elif [ "${_alertType}" == "warning" ]; then
        _color="${red}"
    elif [ "${_alertType}" == "success" ]; then
        _color="${green}"
    elif [ "${_alertType}" == "debug" ]; then
        _color="${purple}"
    elif [ "${_alertType}" == "header" ]; then
        _color="${bold}${white}${underline}"
    elif [ "${_alertType}" == "notice" ]; then
        _color="${bold}"
    elif [ "${_alertType}" == "input" ]; then
        _color="${bold}${underline}"
    elif [ "${_alertType}" = "dryrun" ]; then
        _color="${blue}"
    else
        _color=""
    fi

    _writeToScreen_() {
        ("${QUIET}") && return 0 # Print to console when script is not 'quiet'
        [[ ${VERBOSE} == false && ${_alertType} =~ ^(debug|verbose) ]] && return 0

        if ! [[ -t 1 || -z ${TERM:-} ]]; then # Don't use colors on non-recognized terminals
            _color=""
            reset=""
        fi

        if [[ ${_alertType} == header ]]; then
            printf "${_color}%s${reset}\n" "${_message}"
        else
            printf "${_color}[%7s] %s${reset}\n" "${_alertType}" "${_message}"
        fi
    }
    _writeToScreen_

    _writeToLog_() {
        [[ ${_alertType} == "input" ]] && return 0
        [[ ${LOGLEVEL} =~ (off|OFF|Off) ]] && return 0
        if [ -z "${LOGFILE:-}" ]; then
            LOGFILE="$(pwd)/$(basename "$0").log"
        fi
        [ ! -d "$(dirname "${LOGFILE}")" ] && mkdir -p "$(dirname "${LOGFILE}")"
        [[ ! -f ${LOGFILE} ]] && touch "${LOGFILE}"

        # Don't use colors in logs
        local _cleanmessage
        _cleanmessage="$(printf "%s" "${_message}" | sed -E 's/(\x1b)?\[(([0-9]{1,2})(;[0-9]{1,3}){0,2})?[mGK]//g')"
        # Print message to log file
        printf "%s [%7s] %s %s\n" "$(date +"%b %d %R:%S")" "${_alertType}" "[$(/bin/hostname)]" "${_cleanmessage}" >>"${LOGFILE}"
    }

    # Write specified log level data to logfile
    case "${LOGLEVEL:-ERROR}" in
    ALL | all | All)
        _writeToLog_
        ;;
    DEBUG | debug | Debug)
        _writeToLog_
        ;;
    INFO | info | Info)
        if [[ ${_alertType} =~ ^(error|fatal|warning|info|notice|success) ]]; then
            _writeToLog_
        fi
        ;;
    NOTICE | notice | Notice)
        if [[ ${_alertType} =~ ^(error|fatal|warning|notice|success) ]]; then
            _writeToLog_
        fi
        ;;
    WARN | warn | Warn)
        if [[ ${_alertType} =~ ^(error|fatal|warning) ]]; then
            _writeToLog_
        fi
        ;;
    ERROR | error | Error)
        if [[ ${_alertType} =~ ^(error|fatal) ]]; then
            _writeToLog_
        fi
        ;;
    FATAL | fatal | Fatal)
        if [[ ${_alertType} =~ ^fatal ]]; then
            _writeToLog_
        fi
        ;;
    OFF | off)
        return 0
        ;;
    *)
        if [[ ${_alertType} =~ ^(error|fatal) ]]; then
            _writeToLog_
        fi
        ;;
    esac

} # /_alert_

error() { _alert_ error "${1}" "${2:-}"; }
warning() { _alert_ warning "${1}" "${2:-}"; }
notice() { _alert_ notice "${1}" "${2:-}"; }
info() { _alert_ info "${1}" "${2:-}"; }
success() { _alert_ success "${1}" "${2:-}"; }
dryrun() { _alert_ dryrun "${1}" "${2:-}"; }
input() { _alert_ input "${1}" "${2:-}"; }
header() { _alert_ header "${1}" "${2:-}"; }
debug() { _alert_ debug "${1}" "${2:-}"; }
fatal() {
    _alert_ fatal "${1}" "${2:-}"
    _safeExit_ "1"
}

_printFuncStack_() {
    # DESC:
    #         Prints the function stack in use. Used for debugging, and error reporting.
    # ARGS:
    #         None
    # OUTS:
    #         stdout: Prints [function]:[file]:[line]
    # NOTE:
    #         Does not print functions from the alert class
    local _i
    declare -a _funcStackResponse=()
    for ((_i = 1; _i < ${#BASH_SOURCE[@]}; _i++)); do
        case "${FUNCNAME[${_i}]}" in
        _alert_ | _trapCleanup_ | fatal | error | warning | notice | info | debug | dryrun | header | success)
            continue
            ;;
        *)
            _funcStackResponse+=("${FUNCNAME[${_i}]}:$(basename "${BASH_SOURCE[${_i}]}"):${BASH_LINENO[_i - 1]}")
            ;;
        esac

    done
    printf "( "
    printf %s "${_funcStackResponse[0]}"
    printf ' < %s' "${_funcStackResponse[@]:1}"
    printf ' )\n'
}

_safeExit_() {
    # DESC:
    #       Cleanup and exit from a script
    # ARGS:
    #       $1 (optional) - Exit code (defaults to 0)
    # OUTS:
    #       None

    if [[ -d ${SCRIPT_LOCK:-} ]]; then
        if command rm -rf "${SCRIPT_LOCK}"; then
            debug "Removing script lock"
        else
            warning "Script lock could not be removed. Try manually deleting ${yellow}'${SCRIPT_LOCK}'"
        fi
    fi

    if [[ -n ${TMP_DIR:-} && -d ${TMP_DIR:-} ]]; then
        if [[ ${1:-} == 1 && -n "$(ls "${TMP_DIR}")" ]]; then
            command rm -r "${TMP_DIR}"
        else
            command rm -r "${TMP_DIR}"
            debug "Removing temp directory"
        fi
    fi

    trap - INT TERM EXIT
    exit "${1:-0}"
}

# shellcheck disable=SC2317
_trapCleanup_() {
    # DESC:
    #         Log errors and cleanup from script when an error is trapped.  Called by 'trap'
    # ARGS:
    #         $1:  Line number where error was trapped
    #         $2:  Line number in function
    #         $3:  Command executing at the time of the trap
    #         $4:  Names of all shell functions currently in the execution call stack
    #         $5:  Scriptname
    #         $6:  $BASH_SOURCE
    # USAGE:
    #         trap '_trapCleanup_ ${LINENO} ${BASH_LINENO} "${BASH_COMMAND}" "${FUNCNAME[*]}" "${0}" "${BASH_SOURCE[0]}"' EXIT INT TERM SIGINT SIGQUIT SIGTERM ERR
    # OUTS:
    #         Exits script with error code 1

    local _line=${1:-} # LINENO
    local _linecallfunc=${2:-}
    local _command="${3:-}"
    local _funcstack="${4:-}"
    local _script="${5:-}"
    local _sourced="${6:-}"

    # Replace the cursor in-case 'tput civis' has been used
    tput cnorm

    if declare -f "fatal" &>/dev/null && declare -f "_printFuncStack_" &>/dev/null; then

        _funcstack="'$(printf "%s" "${_funcstack}" | sed -E 's/ / < /g')'"

        if [[ ${_script##*/} == "${_sourced##*/}" ]]; then
            fatal "${7:-} command: '${_command}' (line: ${_line}) [func: $(_printFuncStack_)]"
        else
            fatal "${7:-} command: '${_command}' (func: ${_funcstack} called at line ${_linecallfunc} of '${_script##*/}') (line: ${_line} of '${_sourced##*/}') "
        fi
    else
        printf "%s\n" "Fatal error trapped. Exiting..."
    fi

    if declare -f _safeExit_ &>/dev/null; then
        _safeExit_ 1
    else
        exit 1
    fi
}

# shellcheck disable=SC2317
_makeTempDir_() {
    # DESC:
    #         Creates a temp directory to house temporary files
    # ARGS:
    #         $1 (Optional) - First characters/word of directory name
    # OUTS:
    #         Sets $TMP_DIR variable to the path of the temp directory
    # USAGE:
    #         _makeTempDir_ "$(basename "$0")"

    [ -d "${TMP_DIR:-}" ] && return 0

    if [ -n "${1:-}" ]; then
        TMP_DIR="${TMPDIR:-/tmp/}${1}.${RANDOM}.${RANDOM}.$$"
    else
        TMP_DIR="${TMPDIR:-/tmp/}$(basename "$0").${RANDOM}.${RANDOM}.${RANDOM}.$$"
    fi
    (umask 077 && mkdir "${TMP_DIR}") || {
        fatal "Could not create temporary directory! Exiting."
    }
    debug "\$TMP_DIR=${TMP_DIR}"
}

# shellcheck disable=SC2120
_acquireScriptLock_() {
    # DESC:
    #         Acquire script lock to prevent running the same script a second time before the
    #         first instance exits
    # ARGS:
    #         $1 (optional) - Scope of script execution lock (system or user)
    # OUTS:
    #         exports $SCRIPT_LOCK - Path to the directory indicating we have the script lock
    #         Exits script if lock cannot be acquired
    # NOTE:
    #         If the lock was acquired it's automatically released in _safeExit_()

    local _lockDir
    if [[ ${1:-} == 'system' ]]; then
        _lockDir="${TMPDIR:-/tmp/}$(basename "$0").lock"
    else
        _lockDir="${TMPDIR:-/tmp/}$(basename "$0").${UID}.lock"
    fi

    if command mkdir "${_lockDir}" 2>/dev/null; then
        readonly SCRIPT_LOCK="${_lockDir}"
        debug "Acquired script lock: ${yellow}${SCRIPT_LOCK}${purple}"
    else
        if declare -f "_safeExit_" &>/dev/null; then
            error "Unable to acquire script lock: ${yellow}${_lockDir}${red}"
            fatal "If you trust the script isn't running, delete the lock dir"
        else
            printf "%s\n" "ERROR: Could not acquire script lock. If you trust the script isn't running, delete: ${_lockDir}"
            exit 1
        fi

    fi
}

# shellcheck disable=SC2317
_setPATH_() {
    # DESC:
    #         Add directories to $PATH so script can find executables
    # ARGS:
    #         $@ - One or more paths
    # OPTS:
    #         -x - Fail if directories are not found
    # OUTS:
    #         0: Success
    #         1: Failure
    #         Adds items to $PATH
    # USAGE:
    #         _setPATH_ "/usr/local/bin" "${HOME}/bin" "$(npm bin)"

    [[ $# == 0 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local opt
    local OPTIND=1
    local _failIfNotFound=false

    while getopts ":xX" opt; do
        case ${opt} in
        x | X) _failIfNotFound=true ;;
        *)
            {
                error "Unrecognized option '${1}' passed to _backupFile_" "${LINENO}"
                return 1
            }
            ;;
        esac
    done
    shift $((OPTIND - 1))

    local _newPath

    for _newPath in "$@"; do
        if [ -d "${_newPath}" ]; then
            if ! printf "%s" "${PATH}" | grep -Eq "(^|:)${_newPath}($|:)"; then
                if PATH="${_newPath}:${PATH}"; then
                    debug "Added '${_newPath}' to PATH"
                else
                    debug "'${_newPath}' already in PATH"
                fi
            else
                debug "_setPATH_: '${_newPath}' already exists in PATH"
            fi
        else
            debug "_setPATH_: can not find: ${_newPath}"
            if [[ ${_failIfNotFound} == true ]]; then
                return 1
            fi
            continue
        fi
    done
    return 0
}

# shellcheck disable=SC2317
_useGNUutils_() {
    # DESC:
    #					Add GNU utilities to PATH to allow consistent use of sed/grep/tar/etc. on MacOS
    # ARGS:
    #					None
    # OUTS:
    #					0 if successful
    #         1 if unsuccessful
    #         PATH: Adds GNU utilities to the path
    # USAGE:
    #					# if ! _useGNUUtils_; then exit 1; fi
    # NOTES:
    #					GNU utilities can be added to MacOS using Homebrew

    ! declare -f "_setPATH_" &>/dev/null && fatal "${FUNCNAME[0]} needs function _setPATH_"

    if _setPATH_ \
        "/usr/local/opt/gnu-tar/libexec/gnubin" \
        "/usr/local/opt/coreutils/libexec/gnubin" \
        "/usr/local/opt/gnu-sed/libexec/gnubin" \
        "/usr/local/opt/grep/libexec/gnubin" \
        "/usr/local/opt/findutils/libexec/gnubin" \
        "/opt/homebrew/opt/findutils/libexec/gnubin" \
        "/opt/homebrew/opt/gnu-sed/libexec/gnubin" \
        "/opt/homebrew/opt/grep/libexec/gnubin" \
        "/opt/homebrew/opt/coreutils/libexec/gnubin" \
        "/opt/homebrew/opt/gnu-tar/libexec/gnubin"; then
        return 0
    else
        return 1
    fi

}

# shellcheck disable=SC2317
_homebrewPath_() {
    # DESC:
    #					Add homebrew bin dir to PATH
    # ARGS:
    #					None
    # OUTS:
    #					0 if successful
    #         1 if unsuccessful
    #         PATH: Adds homebrew bin directory to PATH
    # USAGE:
    #					# if ! _homebrewPath_; then exit 1; fi

    ! declare -f "_setPATH_" &>/dev/null && fatal "${FUNCNAME[0]} needs function _setPATH_"

    if _uname=$(command -v uname); then
        if "${_uname}" | tr '[:upper:]' '[:lower:]' | grep -q 'darwin'; then
            if _setPATH_ "/usr/local/bin" "/opt/homebrew/bin"; then
                return 0
            else
                return 1
            fi
        fi
    else
        if _setPATH_ "/usr/local/bin" "/opt/homebrew/bin"; then
            return 0
        else
            return 1
        fi
    fi
}

_parseOptions_() {
    # DESC:
    #					Iterates through options passed to script and sets variables. Will break -ab into -a -b
    #         when needed and --foo=bar into --foo bar
    # ARGS:
    #					$@ from command line
    # OUTS:
    #					Sets array 'ARGS' containing all arguments passed to script that were not parsed as options
    # USAGE:
    #					_parseOptions_ "$@"

    # Iterate over options
    local _optstring=h
    declare -a _options
    local _c
    local i
    while (($#)); do
        case $1 in
        # If option is of type -ab
        -[!-]?*)
            # Loop over each character starting with the second
            for ((i = 1; i < ${#1}; i++)); do
                _c=${1:i:1}
                _options+=("-${_c}") # Add current char to options
                # If option takes a required argument, and it's not the last char make
                # the rest of the string its argument
                if [[ ${_optstring} == *"${_c}:"* && -n ${1:i+1} ]]; then
                    _options+=("${1:i+1}")
                    break
                fi
            done
            ;;
        # If option is of type --foo=bar
        --?*=*) _options+=("${1%%=*}" "${1#*=}") ;;
        # add --endopts for --
        --) _options+=(--endopts) ;;
        # Otherwise, nothing special
        *) _options+=("$1") ;;
        esac
        shift
    done
    set -- "${_options[@]:-}"
    unset _options

    # Read the options and set stuff
    # shellcheck disable=SC2034
    while [[ ${1:-} == -?* ]]; do
        case $1 in
        # Custom options

        # Common options
        -h | --help)
            _usage_
            _safeExit_
            ;;
        --loglevel)
            shift
            LOGLEVEL=${1}
            ;;
        --logfile)
            shift
            LOGFILE="${1}"
            ;;
        -n | --dryrun) DRYRUN=true ;;
        -v | --verbose) VERBOSE=true ;;
        -q | --quiet) QUIET=true ;;
        --force) FORCE=true ;;
        --endopts)
            shift
            break
            ;;
        *)
            if declare -f _safeExit_ &>/dev/null; then
                fatal "invalid option: $1"
            else
                printf "%s\n" "ERROR: Invalid option: $1"
                exit 1
            fi
            ;;
        esac
        shift
    done

    if [[ -z ${*} || ${*} == null ]]; then
        ARGS=()
    else
        ARGS+=("$@") # Store the remaining user input as arguments.
    fi
}

_columns_() {
    # DESC:
    #         Prints a two column output from a key/value pair.
    #         Optionally pass a number of 2 space tabs to indent the output.
    # ARGS:
    #         $1 (required): Key name (Left column text)
    #         $2 (required): Long value (Right column text. Wraps around if too long)
    #         $3 (optional): Number of 2 character tabs to indent the command (default 1)
    # OPTS:
    #         -b    Bold the left column
    #         -u    Underline the left column
    #         -r    Reverse background and foreground colors
    # OUTS:
    #         stdout: Prints the output in columns
    # NOTE:
    #         Long text or ANSI colors in the first column may create display issues
    # USAGE:
    #         _columns_ "Key" "Long value text" [tab level]

    [[ $# -lt 2 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local opt
    local OPTIND=1
    local _style=""
    while getopts ":bBuUrR" opt; do
        case ${opt} in
        b | B) _style="${_style}${bold}" ;;
        u | U) _style="${_style}${underline}" ;;
        r | R) _style="${_style}${reverse}" ;;
        *) fatal "Unrecognized option '${1}' passed to ${FUNCNAME[0]}. Exiting." ;;
        esac
    done
    shift $((OPTIND - 1))

    local _key="${1}"
    local _value="${2}"
    local _tabLevel="${3-}"
    local _tabSize=2
    local _line
    local _rightIndent
    local _leftIndent
    if [[ -z ${3-} ]]; then
        _tabLevel=0
    fi

    _leftIndent="$((_tabLevel * _tabSize))"

    local _leftColumnWidth="$((30 + _leftIndent))"

    if [ "$(tput cols)" -gt 180 ]; then
        _rightIndent=110
    elif [ "$(tput cols)" -gt 160 ]; then
        _rightIndent=90
    elif [ "$(tput cols)" -gt 130 ]; then
        _rightIndent=60
    elif [ "$(tput cols)" -gt 120 ]; then
        _rightIndent=50
    elif [ "$(tput cols)" -gt 110 ]; then
        _rightIndent=40
    elif [ "$(tput cols)" -gt 100 ]; then
        _rightIndent=30
    elif [ "$(tput cols)" -gt 90 ]; then
        _rightIndent=20
    elif [ "$(tput cols)" -gt 80 ]; then
        _rightIndent=10
    else
        _rightIndent=0
    fi

    local _rightWrapLength=$(($(tput cols) - _leftColumnWidth - _leftIndent - _rightIndent))

    local _first_line=0
    while read -r _line; do
        if [[ ${_first_line} -eq 0 ]]; then
            _first_line=1
        else
            _key=" "
        fi
        printf "%-${_leftIndent}s${_style}%-${_leftColumnWidth}b${reset} %b\n" "" "${_key}${reset}" "${_line}"
    done <<<"$(fold -w${_rightWrapLength} -s <<<"${_value}")"
}

_usage_() {
    cat <<USAGE_TEXT

  ${bold}$(basename "$0") [OPTION]... [FILE]...${reset}

  RTMet Installer script:
  https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet

  ${bold}${underline}Options:${reset}
$(_columns_ -b -- '-h, --help' "Display this help and exit" 2)
$(_columns_ -b -- "--loglevel [LEVEL]" "One of: FATAL, ERROR (default), WARN, INFO, NOTICE, DEBUG, ALL, OFF" 2)
$(_columns_ -b -- "--logfile [FILE]" "Full PATH to logfile.  (Default is '\${HOME}/logs/$(basename "$0").log')" 2)
$(_columns_ -b -- "-n, --dryrun" "[NOT IMPLEMENTED] Non-destructive. Makes no permanent changes." 2)
$(_columns_ -b -- "-q, --quiet" "Quiet (no output)" 2)
$(_columns_ -b -- "-v, --verbose" "Output more information. (Items echoed to 'verbose')" 2)
$(_columns_ -b -- "--force" "[NOT IMPLEMENTED] Skip all user interaction.  Implied 'Yes' to all actions." 2)

  ${bold}${underline}Example Usage:${reset}

    ${gray}# Run the script and specify log level and log file.${reset}
    $(basename "$0") -vn --logfile "/path/to/file.log" --loglevel 'WARN'
USAGE_TEXT
}

# ################################## INITIALIZE AND RUN THE SCRIPT
#                                    (Comment or uncomment the lines below to customize script behavior)

trap '_trapCleanup_ ${LINENO} ${BASH_LINENO} "${BASH_COMMAND}" "${FUNCNAME[*]}" "${0}" "${BASH_SOURCE[0]}"' EXIT INT TERM SIGINT SIGQUIT SIGTERM

# Trap errors in subshells and functions
set -o errtrace

# Exit on error. Append '||true' if you expect an error
set -o errexit

# Use last non-zero exit code in a pipeline
set -o pipefail

# Confirm we have BASH greater than v4
[ "${BASH_VERSINFO:-0}" -ge 4 ] || {
    printf "%s\n" "ERROR: BASH_VERSINFO is '${BASH_VERSINFO:-0}'.  This script requires BASH v4 or greater."
    exit 1
}

# Make `for f in *.txt` work when `*.txt` matches zero files
shopt -s nullglob globstar

# Set IFS to preferred implementation
IFS=$' \n\t'

# Run in debug mode
# set -o xtrace

# Initialize color constants
_setColors_

# Disallow expansion of unset variables
set -o nounset

# Force arguments when invoking the script
# [[ $# -eq 0 ]] && _parseOptions_ "-h"

# Parse arguments passed to script
_parseOptions_ "$@"

# Create a temp directory '$TMP_DIR'
# _makeTempDir_ "$(basename "$0")"

# Acquire script lock
_acquireScriptLock_

# Add Homebrew bin directory to PATH (MacOS)
# _homebrewPath_

# Source GNU utilities from Homebrew (MacOS)
# _useGNUutils_

# Run the main logic script
_mainScript_

# Exit cleanly
_safeExit_
