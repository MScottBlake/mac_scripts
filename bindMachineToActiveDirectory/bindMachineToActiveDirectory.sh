################################################################################
# Author: Scott Blake
# Modified: 2017-01-25
#
# SBind the machine to an Active Directory Domain using the first 5 or 6
# characters of the Computer Name to determine what OU to use and adding
# administrative groups where necessary.
#
################################################################################
# Changelog
#
# Version 1.0 - Scott Blake
#   Initial script
# Version 1.1 - Scott Blake
#   Update styling to match other scripts in the repository
#
################################################################################
# Variables
#

# Active Directory domain
domain="domainname.pretendco.com"

# Username/Password used to perform binding
username=""
password=""

# Default OU to put machines when there is no matching prefix
ou="OU=Computers"

# Define groups array - groups will be given admin privileges
groups=("Central-IT-Technicians")

################################################################################
# Additional Variables - Do Not Edit
#

olddomain=$( dsconfigad -show | awk '/Active Directory Domain/{print $NF}' )
computername=$( scutil --get ComputerName )
adcomputerid=$( echo "${computername}" | tr [:lower:] [:upper:] )
prefix="${adcomputerid:0:6}"

################################################################################
# Code
#

echo "Using computer name '${adcomputerid}'..."
echo ""

## Unbind if already bound

# If the domain is correct
if [[ "${olddomain}" == "${domain}" ]]; then
  # Check the id of a user
  id -u "${username}" > /dev/null 2>&1

  # If the check was successful...
  if [[ $? == 0 ]]; then
    echo -n "This machine is bound to AD. Unbinding..."

    # Unbind from AD
    dsconfigad -remove -force -u "${username}" -p "${password}"

    # Re-check the id of a user
    id -u "${username}" > /dev/null 2>&1

    # If the check was successful...
    if [[ $? == 0 ]]; then
      echo "Failed (Error code: 1)"
      exit 1
    else
      echo "Success"
      echo ""
    fi
  fi
fi


## Convert ComputerID prefix to OU ####

echo "Checking for '${prefix}' prefix..."

case "${prefix}" in
  # First 6 chars match ABCDEF, ABCDEG, or ABCDEH
  # Also add AlphaBetaCharlie-Technicians security group as admins
  "ABCDEF"|"ABCDEG"|"ABCDEH")
    ou="OU=Computers,OU=DeltaEcho,OU=AlphaBetaCharlie"
    groups+=("AlphaBetaCharlie-Technicians")
    ;;
  # First 6 characters match XYZ123
  # This OU doesn't have secondary on-site support, so don't add a group
  "XYZ123")
    ou="OU=Computers,OU=XrayYankeeZulu"
    ;;
  "XYZLAB")
    ou="OU=Lab,OU=Computers,OU=XrayYankeeZulu"
    ;;
  *)
    # Nothing found, try the prefixes with 5 characters
    prefix="${prefix:0:5}"
    echo "Checking for '${prefix}' prefix..."

    case "${prefix}" in
      "ABCYZ")
        ou="OU=Computers,OU=AlphaBetaCharlie"
        groups+=("AlphaBetaCharlie-Technicians")
        ;;
    esac
esac

# Append domain to $ou and replace all '.' with ',DC='
ou="${ou},DC=${domain//./,DC=}"

# Display OU string
echo "Using '${ou}' OU..."
echo ""

# Display all groups
echo "Adding administrative privileges to..."
for group in "${groups[@]}"; do
  echo $group;
done
echo ""

# Combine array into comma separated list
groupList=$( printf ",%s" "${groups[@]}" )
groupList="${groupList:1}"


## Perform bind

dsconfigad -add "${domain}" -username "${username}" -password "${password}" \
  -computer "${adcomputerid}" -useuncpath enable -mobile enable \
    -mobileconfirm disable -shell /bin/bash -ou "${ou}" -force \
    -groups "${groupList}"
