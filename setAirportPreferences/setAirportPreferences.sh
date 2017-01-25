#!/bin/bash
################################################################################
# Author: Scott Blake
# Modified: 2017-01-24
#
# This script sets wireless preferences according to input parameters. Boolean
# settings may be configured using 'YES' and 'NO'. Leave a parameter blank to
# ignore it.
#
# Available preferences from Airport command:
#   DisconnectOnLogout (Boolean)
#   JoinMode (String)
#     Automatic
#     Preferred
#     Ranked
#     Recent
#     Strongest
#   JoinModeFallback (String)
#     Prompt
#     JoinOpen
#     KeepLooking
#     DoNothing
#   RememberRecentNetworks (Boolean)
#   RequireAdmin (Boolean)
#   RequireAdminIBSS (Boolean)
#   RequireAdminNetworkChange (Boolean)
#   RequireAdminPowerToggle (Boolean)
#   WoWEnabled (Boolean)
#
# Default Parameter Mapping:
#   +-----+---------------------------|-------------------------------------------------+
#   | Arg | Parameter Label           | Valid Values                                    |
#   +-----+---------------------------|-------------------------------------------------+
#   |  $4 | DisconnectOnLogout        | YES, NO                                         |
#   |  $5 | JoinMode                  | Automatic, Preferred, Ranked, Recent, Strongest |
#   |  $6 | JoinModeFallback          | Prompt, JoinOpen, KeepLooking, DoNothing        |
#   |  $7 | RememberRecentNetworks    | YES, NO                                         |
#   |  $8 | RequireAdmin              | YES, NO                                         |
#   |  $9 | RequireAdminIBSS          | YES, NO                                         |
#   | $10 | RequireAdminNetworkChange | YES, NO                                         |
#   | $11 | RequireAdminPowerToggle   | YES, NO                                         |
#   | ~~$12~~ | ~~WoWEnabled~~        | ~~YES, NO~~                                     |
#   +-----+---------------------------|-------------------------------------------------+
#
################################################################################
# Changelog
#
# Version 1.0 - Scott Blake
#   Initial script
#
################################################################################
# Variables
#

# To only configure one network, enter a number here. This corresponds to the
# line that is returned in the `service` command. For instance, if you have
# "Wi-Fi" and "Wi-Fi 2", entering 1 will only return "Wi-Fi", entering 2 will
# only return "Wi-Fi 2", and leaving it empty will return all services.
nth='1'

# Jamf doesn't give enough parameters, so `WOWEnabled` has been left out. If you
# have a need to set this variable, you'll need to change the parameter mapping.
# The rest of the code should continue to work.

# Check to see if a value was passed in parameter 4. If so, assign to "DisconnectOnLogout".
if [ "$4" != "" ]; then
  DisconnectOnLogout=$4
fi

# Check to see if a value was passed in parameter 5. If so, assign to "JoinMode".
if [ "$5" != "" ]; then
  JoinMode=$5
fi

# Check to see if a value was passed in parameter 6. If so, assign to "JoinModeFallback".
if [ "$6" != "" ]; then
  JoinModeFallback=$6
fi

# Check to see if a value was passed in parameter 7. If so, assign to "RememberRecentNetworks".
if [ "$7" != "" ]; then
  RememberRecentNetworks=$7
fi

# Check to see if a value was passed in parameter 8. If so, assign to "RequireAdmin".
if [ "$8" != "" ]; then
  RequireAdmin=$8
fi

# Check to see if a value was passed in parameter 9. If so, assign to "RequireAdminIBSS".
if [ "$9" != "" ]; then
  RequireAdminIBSS=$9
fi

# Check to see if a value was passed in parameter 10. If so, assign to "RequireAdminNetworkChange".
if [ "${10}" != "" ]; then
  RequireAdminNetworkChange=${10}
fi

# Check to see if a value was passed in parameter 11. If so, assign to "RequireAdminPowerToggle".
if [ "${11}" != "" ]; then
  RequireAdminPowerToggle=${11}
fi

# Check to see if a value was passed in parameter 12. If so, assign to "WoWEnabled".
if [ "${12}" != "" ]; then
  WoWEnabled=${12}
fi

################################################################################
# Additional Variables - Do Not Edit
#

# Path to the airport binary
airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport'

# List of services that match either wi-fi or airport (case insensitive)
services=$(/usr/sbin/networksetup -listallnetworkservices | grep -Ei '(Wi-Fi|AirPort)' | sed -n "${nth}p")

# List of interfaces on the system
interfaces=$(/usr/sbin/networksetup -listallhardwareports)

################################################################################
# Code
#

function NormalizeBooleans() {
  DisconnectOnLogout=$(to_upper_boolean ${DisconnectOnLogout})
  RememberRecentNetworks=$(to_upper_boolean ${RememberRecentNetworks})
  RequireAdmin=$(to_upper_boolean ${RequireAdmin})
  RequireAdminIBSS=$(to_upper_boolean ${RequireAdminIBSS})
  RequireAdminNetworkChange=$(to_upper_boolean ${RequireAdminNetworkChange})
  RequireAdminPowerToggle=$(to_upper_boolean ${RequireAdminPowerToggle})
  WoWEnabled=$(to_upper_boolean ${WoWEnabled})
}

function to_upper_boolean() {
  local str="$@"
  local output

  # Convert to uppercase
  output=$(tr '[:lower:]' '[:upper:]'<<<"${str}")

  # If value entered is shorthand, convert to full word
  case ${output} in
    'Y')
      output="YES";;
    'N')
      output="NO";;
    *)
      output="";;
  esac

  echo ${output}
}

function SetPreferences() {
  # Set preferences for each service found
  for service in "${services}"; do
    # Find the interface for the given service (en0, en1, etc.)
    local interface=$(echo "${interfaces}" | awk "/${service}/,/Ethernet Address/" | awk 'NR==2 {print $2}')

    # Make sure an interface was returned
    if [ -z "${interface}" ]; then
      echo "No interface found for ${service}"
      continue
    fi

    # Set the preference for each setting. The function ignores blank values, so
    # there is no need to modify this list if you aren't setting everything.
    SetPreference "${interface}" "DisconnectOnLogout" "${DisconnectOnLogout}"
    SetPreference "${interface}" "JoinMode" "${JoinMode}"
    SetPreference "${interface}" "JoinModeFallback" "${JoinModeFallback}"
    SetPreference "${interface}" "RememberRecentNetworks" "${RememberRecentNetworks}"
    SetPreference "${interface}" "RequireAdmin" "${RequireAdmin}"
    SetPreference "${interface}" "RequireAdminIBSS" "${RequireAdminIBSS}"
    SetPreference "${interface}" "RequireAdminNetworkChange" "${RequireAdminNetworkChange}"
    SetPreference "${interface}" "RequireAdminPowerToggle" "${RequireAdminPowerToggle}"
    SetPreference "${interface}" "WoWEnabled" "${WoWEnabled}"
  done
}

function SetPreference() {
  local interface=$1
  local key=$2
  local val=$3

  # If a value was passed, set the preference
  if [ ! -z "${val}" ]; then
    echo "Interface '${interface}', setting '${key}' to '${val}'"
    "${airport}" "${interface}" prefs "${key}"="${val}"
  fi
}

function main() {
  NormalizeBooleans
  SetPreferences
}

main
