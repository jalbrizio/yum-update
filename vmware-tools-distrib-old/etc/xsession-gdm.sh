***REMOVED***!/bin/sh
***REMOVED***
***REMOVED*** Copyright (c) 2007-2013 VMware, Inc.  All rights reserved
***REMOVED***

***REMOVED*** This script is -sourced- by one of GDM's "legacy" session scripts.  (Said
***REMOVED*** legacy method is very convenient for us, however!)  As such, it should be
***REMOVED*** kept as simple as possible.  To do so, we make use of the XDM helper and
***REMOVED*** instruct it to stop short of executing an Xsession script.
vmware_xsession_xdm="/etc/vmware-tools/xsession-xdm.sh"
if [ -x "$vmware_xsession_xdm" ]; then
   { sleep 15 && $vmware_xsession_xdm -gdm; } &
fi
