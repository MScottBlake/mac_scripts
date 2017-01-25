#!/bin/bash
################################################################################
# Author: Scott Blake
# Modified: 2017-01-18
#
# This script takes arguments 4-11 to install a printer from a designated print
# server. If anything is passed to $6 (Driver Policy Trigger), it will be used
# as a custom trigger for a Jamf policy designated to install the driver. Using
# normal Jamf scoping mechanisms, you can avoid this policy being re-run when it
# is not necessary.
#
# Also, make sure to set printserver_protocol, printserver_name, and
# printserver_fqdn (lines 41-43) to correspond to your print server. Jamf
# doesn't give enough parameters, so if you have more than 1 print server,
# duplicate this script for each server.
#
#  +-----+-----------------------+-----------------------------------------------------------------+
#  | Arg | Parameter Label       | Example Policy Values                                           |
#  +-----+-----------------------+-----------------------------------------------------------------+
#  |  $4 | Printer Name          | ITS-Printer1                                                    |
#  |  $5 | Printer Location      | 5127 OWP                                                        |
#  |  $6 | Driver Policy Trigger | printDrivers-Bizhub_C224_C284_C364_C454_C554                    |
#  |  $7 | Driver PPD Path       | /Library/Printers/PPDs/Contents/Resources/KONICAMINOLTAC224e.gz |
#  |  $8 | Option 1              | PaperSources=PC204                                              |
#  |  $9 | Option 2              | Finisher=FS519                                                  |
#  | $10 | Option 3              | SelectColor=Grayscale                                           |
#  | $11 | Option 4              | ColorModel=Gray                                                 |
#  +-----+-----------------------+-----------------------------------------------------------------+
#
################################################################################
# Changelog
#
# Version 1.0 - Scott Blake
#   Initial script
#
################################################################################
#
# VARIABLES
#

printserver_protocol="smb"
printserver_name="PRINTSERVERNAME"
printserver_fqdn="printServerName.domain.com"

################################################################################
#
# ADDITIONAL VARIABLES - Do Not Edit
#

printername="${printserver_name}_${printer_shortname}"
gui_display_name="${printer_shortname} on ${printserver_name}"
address="${printserver_protocol}://${printserver_fqdn}/${printer_shortname}"

# Check to see if a value was passed in parameter 4. If so, assign to "printer_shortname".
if [ "$4" != "" ]; then
  printer_shortname=$4
fi

# Check to see if a value was passed in parameter 5. If so, assign to "printer_location".
if [ "$5" != "" ]; then
  printer_location=$5
fi

# Check to see if a value was passed in parameter 6. If so, assign to "driver_policy_trigger".
if [ "$6" != "" ]; then
  driver_policy_trigger=$6
fi

# Check to see if a value was passed in parameter 7. If so, assign to "driver_ppd".
if [ "$7" != "" ]; then
  driver_ppd=$7
fi

# Check to see if a value was passed in parameter 8. If so, assign to "option_1".
if [ "$8" != "" ]; then
  option_1=$8
fi

# Check to see if a value was passed in parameter 9. If so, assign to "option_2".
if [ "$9" != "" ]; then
  option_2=$9
fi

# Check to see if a value was passed in parameter 10. If so, assign to "option_3".
if [ "${10}" != "" ]; then
  option_3=${10}
fi

# Check to see if a value was passed in parameter 11. If so, assign to "option_4".
if [ "${11}" != "" ]; then
  option_4=${11}
fi

################################################################################
#
# Code
#

function CheckBinary() {
  # Identify location of jamf binary.
  jamf_binary=$(/usr/bin/which jamf)

  if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/sbin/jamf"
  elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
  elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
  fi
}

function DriverInstall() {
  # Trigger JAMF policy to (re)install drivers
  if [ ! -z "${driver_policy_trigger}" ]; then
    $jamf_binary policy -event "${driver_policy_trigger}"
  fi

  # If driver PPD does not exist, fail and exit
  if [ ! -e "${driver_ppd}" ]; then
    echo "Driver PPD not found at ${driver_ppd}."
    exit 1
  fi
}

function PrinterDelete() {
  # If printer already exists, remove it first
  /usr/bin/lpstat -p "${printername}" > /dev/null 2>1
  if [[ $? -eq 0 ]]; then
    echo "Existing printer found. Removing..."
    /usr/sbin/lpadmin -x "${printername}"
  fi
}

function PrinterInstall() {
  # Now we can install the printer.
  /usr/sbin/lpadmin \
    -p "${printername}" \
    -L "${printer_location}" \
    -D "${gui_display_name}" \
    -v "${address}" \
    -P "${driver_ppd}" \
    -o "${option_1}" \
    -o "${option_2}" \
    -o "${option_3}" \
    -o "${option_4}" \
    -o auth-info-required=negotiate \
    -o printer-is-shared=false \
    -E

  result=$?
  if [ "${result}" -eq 0 ]; then
    echo "${printername} installed successfully."
  else
    exit "${result}"
  fi
}

function PrinterEnable() {
  # Enable and start the printer on the system (so it's not paused).
  echo "Making sure ${printername} is enabled..."
  /usr/sbin/cupsenable "${printername}"
}

function main() {
  CheckBinary
  DriverInstall
  PrinterDelete
  PrinterInstall
  PrinterEnable
}

main
