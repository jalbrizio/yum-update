***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***

***REMOVED***

***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***

DAY=$(date "+%d")
echo $DAY

if [ "$DAY" -gt "8" -a "$DAY" -lt "14" ]

then

***REMOVED*** This is where we call yum to update the server
***REMOVED***
yum -y update --nogpg > /var/log/yum-update.log

***REMOVED*** now we Give it 30 seconds just in case 
***REMOVED*** before emailing everyone the update status.
***REMOVED***
***REMOVED***

***REMOVED*** Email everyone ***REMOVED******REMOVED*** email are seperated by comas with no spaces***REMOVED******REMOVED***
***REMOVED***
***REMOVED***

***REMOVED*** Make sure iptables is running and will start at boot then ***REMOVED*** the server 
***REMOVED*** Yes, I chose ***REMOVED*** instead of shutdown -r 0
***REMOVED*** 

***REMOVED***
***REMOVED***

***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***

service mysql restart

***REMOVED***

else 

echo "not running today"
exit

fi
