triggerPolicyWhenProcessNotRunning.sh
===========

This script takes arguments in $4 (Process) and $5 (Trigger). It checks to
see if the process from $4 is running and if not, calls a Jamf policy with a
custom trigger from $5.
