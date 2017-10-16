# since cron can only be scheduled to run every sunday.
#
#!/bin/bash

WEEKDAY1=$(date "+%a"|grep Sun )
WEEKDAY2=$(date "+%a"|grep Wed )
DAY=$(date "+%d")
 
#verify its sunday 
if [ -n "$WEEKDAY1" ]
 then
#verify its the second sunday
        if [ "$DAY" -gt "8" -a "$DAY" -lt "14" ]
         then
# Pull the latest update script before running updates
          cd /usr/local/src/vmware-tools
          git fetch
          git reset --hard origin/master
#run the update script
          /usr/local/src/vmware-tools/yum-update2.sh
        else
          echo "not running today"
          exit
        fi
#verify its wednesday
elif [ -n "$WEEKDAY2" ]
then
#verify its the wednesday following the second sunday
        if [ "$DAY" -gt "11" -a "$DAY" -lt "17" ]
         then
# Pull the latest update script before running updates
          cd /usr/local/src/vmware-tools
          git fetch
          git reset --hard origin/master
#run the update script
          /usr/local/src/vmware-tools/yum-update2.sh
        else
          echo "not running today"
          exit
        fi
else
        echo "not running today"
fi
yum clean all
