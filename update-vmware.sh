***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***

***REMOVED***

***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED*** Make sure you have the latest vmware tools package
cd /usr/local/src/vmware-tool
git fetch
git reset --hard origin/master
***REMOVED*** run the vmware tool update
sed -i '/^answer\ VMMEMCTL_CONFED\ yes/c\answer\ VMMEMCTL_CONFED\ no' /etc/vmware-tools/locations
sed -i '/^answer\ PVSCSI_CONFED\ yes/c\answer\ PVSCSI_CONFED\ no' /etc/vmware-tools/locations
/usr/local/src/vmware-tools/vmware-tools-distrib/vmware-install.pl --default --clobber-kernel-modules=vmxnet3
***REMOVED*** Make sure iptables will autostart at boot and restart iptables so that thecorrect rules are in place
***REMOVED***
***REMOVED***

