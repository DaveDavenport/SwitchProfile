#!/bin/bash
#
# Written by: Martijn Koedam <m.l.p.j.koedam@tue.nl>
# License: Under GPL, see provided LICENSE file. 
#
# This tool is ment to easily switch between profiles.
# For example prepare your terminal for sdf3, or compsoc toolflow.
#
# Set your prefered shell

# Autocomplete function:
#
#_switch_profile.sh()
#{
#	COMPREPLY=()
#	curw=${COMP_WORDS[COMP_CWORD]}
#	COMPREPLY=($(compgen -W '$(switch_profile.sh -l)' -- $curw))
#}
#complete -F _switch_profile.sh switch_profile.sh
#

BASH=bash
# Config file location (absolute path required)
CONFIG_FILE="${HOME}/.switch_profile.conf"


######################################################################
# Start of script                                                    #
######################################################################
VERSION=0.0.1
REQ_PROFILE=""
REQ_PATH=""
REQ_SOURCE_FILE=""

# Reset
Color_Off='\e[0m'         # Text Reset

# Bold
BBlack='\e[1;30m'      # Black
BRed='\e[1;31m'      # Red
BGreen='\e[0;32m'      # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'      # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'      # Cyan
BWhite='\e[1;37m'      # White


###
# Starts a new shell as child. This child will have
# All the right environments set.
###
function enter_new_profile()
{
	echo -e "${BBlack}Switching to profile:${Color_Off} ${BGreen}${REQ_PROFILE}${Color_Off}"

	# Enter the requested directory
	if [ -d ${REQ_PATH} ]
	then
		pushd ${REQ_PATH} 2&>/dev/null
	fi

	# Source the file
	if [ -n "${REQ_SOURCE_FILE}" ]
	then
		source ${REQ_SOURCE_FILE}
	fi

	# Set profile name
	export SP_PROFILE=${REQ_PROFILE}
	
	# Do it
	${BASH}

	# Go back where we came from. (not realy needed)
	popd 2&>/dev/null	
	#ending message
	echo -e "${BRed}Ending use of profile: ${BGreen}${SP_PROFILE}${Color_Off}"
}

##
# usage
##
function show_usage()
{
	echo -e "${BBlack}Usage:${Color_Off} ${BGreen}./switch_profile.sh <PROFILE>${Color_Off}"
	echo ""
	echo "-l	Get a list of possible profiles."
	echo "-v	Get the version of this tool."
	echo "-h	This message."
	echo ""
	echo "The config file ~/.switch_profile.conf consists of"
	echo "one or more entries:"
	echo "<PROFILE>=<ENABLED>"
	echo "<PROFILE>_PATH=<Path to enter>"
	echo "<PROFILE>_SOURCE_FILE=<File to source>"
	echo ""
	echo "ENABLED             Is either 1 or 0."
	echo "PROFILE_PATH        Should be an absolute path."
	echo "PROFILE_SOURCE_FILE Should be an absolute path";
	echo "                    when PROFILE_PATH is not set or relative to PROFILE_PATH";
}


##
# Check the config file
# * Exists
# * Validate the config file. only {A}={B} allowed.
##
function check_config_file()
{
	# Test if it exists
	if [ ! -f "${CONFIG_FILE}" ]
	then
			echo "Could not find config file: ${CONFIG_FILE}";
		exit 1;
	fi

	# validate config file.
	if egrep -q -v '^$|^#|^[^ ]*=[^;]*' "${CONFIG_FILE}";
	then
		echo -e "${BRed}Config file is unclean.${Color_Off}" >&2;
		exit 1;
	fi
}

##
# Load and validate the input
##
function check_in_profile()
{
	if [ -n "${SP_PROFILE}" ];
	then
		echo -e "${BPurple}You are allready inside a profile:${BGreen} ${SP_PROFILE}.${Color_Off}";
		exit;
	fi
}

function validate_profile()
{
	# Lookup entry in config file
	eval ENABLED=\$${REQ_PROFILE};

	# Check if it exists
	if [ -z "${ENABLED}" ] 
	then
		echo -e "${BRed}Profile: ${REQ_PROFILE} does not exists.${Color_Off}";
		exit 1;
	fi

	# Check enabled
	if [  "${ENABLED}" != 1 ]
	then 
		echo -e "${BRed}Profile: ${REQ_PROFILE} is disabled. ${Color_Off}";
		exit 1;
	fi
	
	eval REQ_PATH=\${${REQ_PROFILE}"_PATH"};
	eval REQ_SOURCE_FILE=\${${REQ_PROFILE}"_SOURCE_FILE"};
}

list_profiles()
{
	# should be able todo this in one command.
	egrep -E "^(.*)=[01]$" ${CONFIG_FILE} | awk -F'=' '{print $1}'
}

##
# option parser
##
while getopts hlvr OPT; do
    case "$OPT" in
        h)
			show_usage
			exit 0
            ;;
        v)
            echo "`basename $0` version ${VERSION}"
            exit 0
            ;;
        l)
           	list_profiles
			exit 0 
            ;;
		r)
			check_config_file
			# Load the config file. (cannot do this from function?)
			source "${CONFIG_FILE}"
			REQ_PROFILE=${SP_PROFILE}
			# Quick and dirty check of the profile file.
			validate_profile

			echo "${REQ_PATH}"
			exit 0
			;;
        \?)
            # getopts issues an error message
			echo -e "See ${BGreen}$(basename $0) -h ${Color_Off} for information about usage"
            exit 1
            ;;
    esac
done
# Remove the switches we parsed above.
shift `expr $OPTIND - 1`

# We want at least one non-option argument.
# Remove this block if you don't need it.
if [ $# -ne 1 ];
then
	echo -e "${BRed}One profile needed, found $# ${Color_Off}"
	echo -e "See ${BGreen}$(basename $0) -h ${Color_Off} for information about usage"
	exit 1
fi

##
# Validate input
##
REQ_PROFILE=$1
check_in_profile

check_config_file
# Load the config file. (cannot do this from function?)
source "${CONFIG_FILE}"

# Quick and dirty check of the profile file.
validate_profile

# enter the new profile.
enter_new_profile
