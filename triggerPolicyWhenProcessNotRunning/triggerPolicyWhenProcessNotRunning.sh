#!/bin/bash
################################################################################
# Author: Scott Blake
# Modified: 2017-01-23
#
# This script takes arguments in $4 (Process) and $5 (Trigger). It checks to
# see if the process from $4 is running and if not, calls a Jamf policy with a
# custom trigger from $5.
#
################################################################################
# Changelog
#
# Version 1.0 - Scott Blake
#   Initial script
#
################################################################################
#

process="$4"
processrunning=$( ps axc | grep "${process}$" )

CheckBinary (){
  # Identify location of jamf binary.
  jamf_binary=`/usr/bin/which jamf`

  if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/sbin/jamf"
  elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
  elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
  fi
}

CheckBinary

if [ "${processrunning}" != "" ]; then
  echo "$process IS running, try again later."
else
  echo "${process} IS NOT running, will try to update it now."
  $jamf_binary policy -event "$5" -verbose
fi
