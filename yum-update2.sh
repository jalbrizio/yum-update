#!/bin/bash
# This script updates the server Via Yum
# Then emails the Admins the status of the updates
# Then reboots the server in that order

# Script written by Jeremi Albrizio on Feb 5th.

# This is where we make sure it only runs on the second sunday 
# since cron can only be scheduled to run every sunday.
#
#!/bin/bash



# This is where we call yum to update the server
#
yum -y update --nogpg --skip-broken > /var/log/yum-update.log

# now we Give it 30 seconds just in case 
# before emailing everyone the update status.
#
sleep 30

# Email everyone ## email are seperated by comas with no spaces##
#
cat /var/log/yum-update.log | mail -s "yum update log for `date`" exampleemail@yourserver.com         # replace with 'examplePass' instead,exampleemail@yourserver.com         # replace with 'examplePass' instead,exampleemail@yourserver.com         # replace with 'examplePass' instead,exampleemail@yourserver.com         # replace with 'examplePass' instead

# Make sure iptables is running and will start at boot then reboot the server 
# Yes, I chose reboot instead of shutdown -r 0
# 

chkconfig iptables on
service iptables restart

service mysql start --wsrep-cluster-address=gcomm://
mysql_upgrade -u root -pexamplePass --force
cd /usr/local/src/vmware-tools/galera
semodule -i /usr/local/src/vmware-tools/galera/galera.pp

service mysql stop
killall -9 mysqld
service mysql start

reboot

