#!/bin/bash
################################################################################
# Author: Scott Blake
# Modified: 2016-11-11
#
# Set this script to run at login to perform inventory with "User and Location"
# information. This script skips users with an ID less than 1000 (local users).
#
################################################################################
# Changelog
#
# Version 1.0 - Scott Blake
#   Initial script
# Version 1.1 - Scott Blake
#   Added username logic to skip local accounts
#
################################################################################
# Variables
#

# Check to see if a value was passed in parameter 3 and if so, assign to "username"
if [ "$3" != "" ]; then
  username=$3
else
  echo "ERROR: No username provided"
  exit 1
fi

################################################################################
# Code
#

CheckBinary() {
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

PerformRecon() {
  # If username is not local, perform recon.
  if [ $(/usr/bin/id -u "${username}") -ge 1000 ]; then
    echo "Login from user: ${username}"
    echo "Performing recon..."
    $jamf_binary recon -endUsername "${username}"
  else
    echo "Login from local user: ${username}"
    echo "Recon skipped."
  fi
}

main() {
  CheckBinary
  PerformRecon
}

main
