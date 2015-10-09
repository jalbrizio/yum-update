***REMOVED***
***REMOVED***
***REMOVED***

WEEKDAY1=$(date "+%a"|grep Sun )
WEEKDAY2=$(date "+%a"|grep Wed )
DAY=$(date "+%d")
 
***REMOVED***verify its sunday 
if [ -n "$WEEKDAY1" ]
 then
***REMOVED***verify its the second sunday
        if [ "$DAY" -gt "8" -a "$DAY" -lt "14" ]
         then
***REMOVED*** Pull the latest update script before running updates
          cd /usr/local/src/vmware-tools
          git fetch
          git reset --hard origin/master
***REMOVED***run the update script
          /usr/local/src/vmware-tools/yum-update2.sh
        else
          echo "not running today"
          exit
        fi
***REMOVED***verify its wednesday
elif [ -n "$WEEKDAY2" ]
then
***REMOVED***verify its the wednesday following the second sunday
        if [ "$DAY" -gt "11" -a "$DAY" -lt "17" ]
         then
***REMOVED*** Pull the latest update script before running updates
          cd /usr/local/src/vmware-tools
          git fetch
          git reset --hard origin/master
***REMOVED***run the update script
          /usr/local/src/vmware-tools/yum-update2.sh
        else
          echo "not running today"
          exit
        fi
else
        echo "not running today"
fi
