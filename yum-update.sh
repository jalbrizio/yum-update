***REMOVED***
***REMOVED***
***REMOVED***

WEEKDAY1=$(date "+%a"|grep Sun )
WEEKDAY2=$(date "+%a"|grep Wed )
DAY=$(date "+%d")
 

if [ -n "$WEEKDAY1" ]
 then
        if [ "$DAY" -gt "8" -a "$DAY" -lt "14" ]
         then
          cd /usr/local/src/vmware-tools
          git fetch
          git reset --hard origin/master
          /usr/local/src/vmware-tools/yum-update2.sh
        else
          echo "not running today"
          exit
        fi
elif [ -n "$WEEKDAY2" ]
then
        if [ "$DAY" -gt "11" -a "$DAY" -lt "17" ]
         then
          cd /usr/local/src/vmware-tools
          git fetch
          git reset --hard origin/master
          /usr/local/src/vmware-tools/yum-update2.sh
        else
          echo "not running today"
          exit
        fi
else
        echo "not running today"
fi
