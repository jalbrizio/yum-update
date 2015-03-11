cd /usr/local/src/vmware-tools/vmware-tools-distrib
git fetch
git reset --hard origin/master
/usr/local/src/vmware-tools/vmware-tools-distrib/vmware-install.pl --default --clobber-kernel-modules=vmxnet3 --clobber-kernel-modules=pvscsi --clobber-kernel-modules=vmmemctl
