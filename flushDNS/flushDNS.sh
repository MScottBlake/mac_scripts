#!/bin/bash
################################################################################
# Author: Scott Blake
# Modified: 2017-01-23
#
# Script to flush the DNS caches in macOS. The script checks the version of
# macOS and then issues the appropriate command to flush the DNS cache.
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

prod_ver=$(/usr/bin/sw_vers -productVersion)
os_major=$(echo ${prod_ver} | awk -F . '{print $1}')
os_minor=$(echo ${prod_ver} | awk -F . '{print $2}')
os_patch=$(echo ${prod_ver} | awk -F . '{print $3}')

################################################################################
# Code
#

# Not macOS 10.x
if [ "${os_major}" -ne "10" ]; then
  echo "ERROR: OS not supported"
  exit 1
fi

# El Capitan and Sierra
if [ "${os_minor}" -ge "11" ]; then
  killall -HUP mDNSResponder

# Yosemite
elif [ "${os_minor}" -eq "10" ]; then
  # 10.10.0 - 10.10.3
  if [ "${os_patch}" -ge "0" ] && [ "${os_patch}" -le "3" ]; then
    discoveryutil mdnsflushcache
  # 10.10.4+
  elif [ "${os_patch}" -ge "4" ]; then
    killall -HUP mDNSResponder
  fi

# Lion, Mountain Lion, and Mavericks
elif [ "${os_minor}" -ge "7" ] && [ "${os_minor}" -le "9" ]; then
  killall -HUP mDNSResponder

# Tiger, Leopard, and Snow Leopard
elif [ "${os_minor}" -ge "4" ] && [ "${os_minor}" -le "6" ]; then
  dscacheutil -flushcache
fi
