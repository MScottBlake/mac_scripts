#!/bin/sh
################################################################################
# Author: Scott Blake
# Modified: 2014-12-20
#
# This script utilizes CocoaDialog.app to convert local Mac OS X user accounts
# to mobile accounts.
#
# Based on previous work from:
#   Rich Trouton: https://github.com/rtrouton/rtrouton_scripts/tree/master/rtrouton_scripts/migrate_local_user_to_AD_domain
#   Patrick Gallagher: http://macadmincorner.com/migrate-local-user-to-domain-account/
#
################################################################################
# Changelog
#
# Version 1.0 - Patrick Gallagher
#   Initial script
#
# Version 1.2 - Rich Trouton
#   Added the ability to check if the OS is running on Mac OS X 10.7, and run
#   "killall opendirectoryd" instead of "killall DirectoryService" if it is.
#
# Version 1.3 - Rich Trouton
#   Added the ability to check if the OS is running on Mac OS X 10.7 or higher
#   (including 10.8) and run "killall opendirectoryd" instead of "killall
#   DirectoryService" if it is.
#
# Version 1.4 - Rich Trouton
#   Changed the admin rights function from using dscl append to using
#   dseditgroup.
#
# Version 1.5 - Rich Trouton
#   Fixed the admin rights functionality so that it actually now grants admin
#   rights.
#
# Version 2.0 - Scott Blake
#   Convert user prompts to use cocoaDialog and reorder the logic a bit.
#
################################################################################
# Variables
#

# Set the path to the cocoaDialog application.
# Will be used to display prompts.
CD="/path/to/CocoaDialog.app/Contents/MacOS/CocoaDialog"

# Set an Active Directory username that is not likely to be removed.
# Will be used to check AD connectivity
lookupAccount="EXISTING_AD_USERNAME"

################################################################################
# Other Variables (Should not need to modify)
#

Version=2.0
listUsers=( $(/usr/bin/dscl . list /Users UniqueID | awk '$2 >= 500 && $2 < 1024 { print $1; }') )
FullScriptName=$(basename "${0}")
check4AD=$(/usr/bin/dscl localhost -list . | grep "Active Directory")
osvers=$(/usr/bin/sw_vers -productVersion | awk -F. '{print $2}')

################################################################################
# Functions
#

# Generic failure with reason function
die() {
  rv=$(${CD} ok-msgbox --title "Error" \
  --text "Error" \
  --informative-text "${1}" \
  --no-cancel \
  --float \
  --icon stop)

  if [[ "${rv}" == "1" ]]; then
    echo "Error: ${1}"
    exit 1
  fi
}

# Function to ensure admin privileges
RunAsRoot() {
  ##  Pass in the full path to the executable as $1
  if [[ "$(/usr/bin/id -u)" != "0" ]] ; then
    echo "This application must be run with administrative privileges."
    osascript -e "do shell script \"${1}\" with administrator privileges"
    exit 0
  fi
}

################################################################################

# Clear previous commands from Terminal
clear

# Display version information
echo "********* Running ${FullScriptName} Version ${Version} *********"

# Execute runAsRoot function to ensure administrative privileges
RunAsRoot "${0}"

# Check for cocoaDialog dependency and exit if not found
if [[ ! -f ${CD} ]]; then
  echo "Required dependency not found: ${CD}"
  exit 1
fi

# If the machine is not bound to AD, then there's no purpose going any further.
if [[ "${check4AD}" != "Active Directory" ]]; then
  die "This machine is not bound to Active Directory. Please bind to AD first."
fi

# Lookup a domain account and check exit code for error
/usr/bin/id -u "${lookupAccount}"
if [[ $? -ne 0 ]]; then
  die "It doesn't look like this Mac is communicating with AD correctly. Exiting the script."
fi

# Loop until 'Finished' button is selected
until [[ "${acctReturn[0]}" == "2" ]]; do

  # Generate User Account Selection dialog to get 'old username'
  acctReturn=( $(${CD} dropdown --title "User Account Selection" \
    --text "Please choose a local user to migrate." \
    --float \
    --items ${listUsers[@]} \
    --button1 "Continue" \
    --button2 "Finish" \
    --icon user) )

  if [[ "${acctReturn[0]}" == "1" ]]; then
    user="${listUsers[${acctReturn[1]}]}"
    echo "Selected '${user}' to migrate."
  elif [[ "${acctReturn[0]}" == "2" ]]; then
    echo "Exiting from 'User Account Selection' dialog."
    exit 0
  fi

  if [[ ! -n "${user}" ]]; then
    die "'${user}' not found."
  elif [[ $(/usr/bin/who | /usr/bin/awk '/console/ {print $1}') == "${user}" ]]; then
    die "This user is logged in. Please log this user out and log in as another admin."
  fi

  # Get AD username
  rv=( $(${CD} standard-inputbox --title "Enter Active Directory Username" \
    --informative-text "Please provide ${user}'s Active Directory username." \
    --text "${user}" \
    --float \
    --icon find) )

  if [[ "${rv[0]}" == "1" ]]; then
    netname="${rv[@]:1}"
    echo "Entered '${netname}' as new Active Directory username."
  elif [[ "${rv[0]}" == "2" ]]; then
    echo "Exiting from 'Enter Active Directory Username' dialog."
    exit 0
  fi

  # Validate AD username against spaces
  if [[ "${netname}" != "${netname%[[:space:]]*}" ]]; then
    die "The Active Directory username cannot contain spaces."
  fi

  # Determine location of the users home folder
  userHome="$(/usr/bin/dscl . read /Users/"${user}" NFSHomeDirectory | /usr/bin/cut -c 19-)"

  # Get list of groups
  echo "Checking group memberships for local user ${user}"
  lgroups="$(/usr/bin/id -Gn ${user})"

  if [[ $? -eq 0 ]] && [[ -n "$(/usr/bin/dscl . -search /Groups GroupMembership "${user}")" ]]; then
    # Delete user from each group it is a member of
    for lg in "${lgroups}"; do
      /usr/bin/dscl . -delete /Groups/"${lg}" GroupMembership "${user}" >&/dev/null
    done
  fi

  # Delete the primary group
  if [[ -n "$(/usr/bin/dscl . -search /Groups name "${user}")" ]]; then
    /usr/sbin/dseditgroup -o delete "${user}"
  fi

  # Get the users guid and set it as a var
  guid="$(/usr/bin/dscl . -read /Users/"${user}" GeneratedUID | /usr/bin/awk '{print $NF;}')"
  if [[ -f /private/var/db/shadow/hash/"${guid}" ]]; then
    /bin/rm -f /private/var/db/shadow/hash/"${guid}"
  fi

  # Delete the user
  /bin/mv "${userHome}" /Users/old_"${user}"
  /usr/bin/dscl . -delete /Users/"${user}"

  # Refresh Directory Services
  if [[ "${osvers}" -ge 7 ]]; then
    /usr/bin/killall opendirectoryd
  else
    /usr/bin/killall DirectoryService
  fi

  # Allow service to restart
  sleep 20
  /usr/bin/id "${netname}"

  # Check if there's a home folder there already, if there is, exit before we wipe it
  if [[ -f /Users/"${netname}" ]]; then
    die "Oops, theres a home folder there already for ${netname}. If you don't want that one, delete it in the Finder first, then run this script again."
  else
    /bin/mv /Users/old_"${user}" /Users/"${netname}"
    echo "Home directory for '${netname}' is now located at '/Users/${netname}'."

    /usr/sbin/chown -R "${netname}" /Users/"${netname}"
    echo "Permissions for '/Users/${netname}' are now set properly."

    /System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount -n "${netname}"
    echo "Account for ${netname} has been created on this computer"
  fi

  # Prompt for admin rights
  rv=( $(${CD} yesno-msgbox --title "Grant Administrative Privileges" \
    --text "Do you want to grant ${netname} administrative privilieges?" \
    --float \
    --no-cancel \
    --icon security) )

  if [[ "${rv}" == "1" ]]; then
    /usr/sbin/dseditgroup -o edit -a "${netname}" -t user admin
    echo "Administrative privileges granted to ${netname}."
  elif [[ "${rv}" == "2" ]]; then
    echo "No administrative privileges granted to ${netname}."
  fi

  # Display success dialog
  rv=$(${CD} ok-msgbox --title "Successful Migration" \
    --text "Successfully migrated local user account (${user}) to Active Directory account (${netname})." \
    --float \
    --no-cancel \
    --icon info)

done
