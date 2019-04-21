#!/bin/bash
__MESSAGE="Usage: $0 [OPTIONS]... INSTALL_GOAL SCRIPT...

Required args:

  INSTALL_GOAL              points to a file which existence prevents SCRIPT from activation
                            (e.g. game files)
  SCRIPT points             to the installation script

Options:

  -r                        path to a script which runs on startup and check requirements
                            (e.g. /app/requirements.sh)
  -e                        wildcard to scripts which install extensions
                            (e.g. /app/extensions/*/bin/install.sh)
  -s                        wildcard to scripts which set up or start extensions on every run
                            may be helpful for custom launchers
                            (e.g. /app/extensions/*/bin/start.sh)

this script tries to be helpful during wine setup inside flatpak or any other sandbox.
it starts the main install script for your game,
runs extensions installers and startup scripts,
stops if return value is different than 0,

Basically is used to not reimplement all the time the same code
when experimenting with winepack and/or flatpak

Examples:
$0 \"/app/data/start.exe\" \"/app/bin/install.sh\"
$0 -r \"/app/bin/requirements.sh\" -e \"/app/ext/*/bin/install.sh\" \"/app/data/start.exe\" \"/app/bin/installer.sh\"
"

__OPTARGSCOUNT=0
__INSTALL_SCRIPT=""
__INSTALL_IF_DOESNT_EXIST=""
__REQUIREMENTS_BOOL=false
__REQUIREMENTS_SCRIPT=false
__EXTENSIONS_INST_BOOL=false
__EXTENSIONS_INST_WILD=false
__EXTENSIONS_ON_START_BOOL=false
__EXTENSIONS_ON_START_WILD=false

usage() { printf "${__MESSAGE}" 1>&2; exit 1; }

execute() {
  # requirements
  if ${__REQUIREMENTS_BOOL}; then
    echo "running ${__REQUIREMENTS_SCRIPT}"
    source "${__REQUIREMENTS_SCRIPT}"
    if [[ $? != 0 ]]; then
      echo "${__REQUIREMENTS_SCRIPT} failed with code $?, aborting."
      exit 1
    fi
  fi

  # install if file doesn't exist
  if [[ ! -e ${__INSTALL_IF_DOESNT_EXIST} ]]; then
    echo "${__INSTALL_SCRIPT} is isntalling ${FLATPAK_ID}"
    source "${__INSTALL_SCRIPT}"
    if [[ $? != 0 ]]; then
      echo "${__INSTALL_SCRIPT} failed with code $?, aborting."
      exit 1
    fi
  fi

  # for every extension installer in $VAR[]; if any exists; run it
  if ${__EXTENSIONS_INST_BOOL}; then
    for F in ${__EXTENSIONS_INST_WILD} ; do
      if [[ -f "$F" ]]; then
        echo "installing $F"
        source "$F"
        if [[ $? != 0 ]]; then
          echo "error code $? forced the script to stop."
          exit 1
        fi
      fi
    done
  fi

  # start extensions
  if ${__EXTENSIONS_ON_START_BOOL}; then
    for F in ${__EXTENSIONS_ON_START_WILD} ; do
      if [[ -f "$F" ]]; then
        echo "setting $F"
        source "$F"
      fi
    done
  fi
}

# save optional args
while getopts ":r:e:s:h:" ARG; do
    case "${ARG}" in
        r)
            __REQUIREMENTS_SCRIPT=${OPTARG}
            __REQUIREMENTS_BOOL=true
            ((++__OPTARGSCOUNT))
            ;;
        e)
            __EXTENSIONS_INST_WILD=${OPTARG}
            __EXTENSIONS_INST_BOOL=true
            ((++__OPTARGSCOUNT))
            ;;
        s)
            __EXTENSIONS_ON_START_WILD=${OPTARG}
            __EXTENSIONS_ON_START_BOOL=true
            ((++__OPTARGSCOUNT))
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# check/save required args
if [[ -z "$2" ]]; then
  usage
  exit 1
fi
__INSTALL_SCRIPT=$2
__INSTALL_IF_DOESNT_EXIST=$1

# run
execute

