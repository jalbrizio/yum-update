#!/bin/bash
# This script updates the server Via Yum
# Then emails the Admins the status of the updates
# Then reboots the server in that order

# Script written by Jeremi Albrizio on Feb 5th.

# This is where we make sure it only runs on the second sunday 
# since cron can only be scheduled to run every sunday.
#
#!/bin/bash
# Make sure you have the latest vmware tools package
cd /usr/local/src/vmware-tool
git fetch
git reset --hard origin/master
# run the vmware tool update
sed -i '/^answer\ VMMEMCTL_CONFED\ yes/c\answer\ VMMEMCTL_CONFED\ no' /etc/vmware-tools/locations
sed -i '/^answer\ PVSCSI_CONFED\ yes/c\answer\ PVSCSI_CONFED\ no' /etc/vmware-tools/locations
/usr/local/src/vmware-tools/vmware-tools-distrib/vmware-install.pl --default --clobber-kernel-modules=vmxnet3
# Make sure iptables will autostart at boot and restart iptables so that thecorrect rules are in place
chkconfig iptables on
service iptables restart

