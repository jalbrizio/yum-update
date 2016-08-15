***REMOVED***!/bin/sh
***REMOVED***
***REMOVED*** Copyright 2007-2013 VMware, Inc.  All rights reserved.
***REMOVED***
***REMOVED*** This script is run in two instances:
***REMOVED***   1.  It was hooked into XDM via twiddling xdm-config.
***REMOVED***   2.  It was hooked into legacy GDM via inserting a script in
***REMOVED***       /etc/X11/xinitrc.d.
***REMOVED***
***REMOVED*** This script's responsibility is primarily to launch vmware-user during
***REMOVED*** X session startup.  In the XDM case, after launching vmware-user, we
***REMOVED*** resume executing the original, system Xsession script.  In the GDM
***REMOVED*** case, we do nothing else.
***REMOVED***
***REMOVED*** usage: xsession-xdm.sh [-gdm]
***REMOVED***    -gdm: Indicates caller is the GDM helper (xsession-gdm); run
***REMOVED***          vmware-user -only-, then exit.

***REMOVED*** BEGINNING_OF_DB_DOT_SH
***REMOVED***!/bin/sh

***REMOVED***
***REMOVED*** Manage an installer database
***REMOVED***

***REMOVED*** Add an answer to a database in memory
db_answer_add() {
  local dbvar="$1" ***REMOVED*** IN/OUT
  local id="$2"    ***REMOVED*** IN
  local value="$3" ***REMOVED*** IN
  local answers
  local i

  eval "$dbvar"'_answer_'"$id"'="$value"'

  eval 'answers="$'"$dbvar"'_answers"'
  ***REMOVED*** There is no double quote around $answers on purpose
  for i in $answers; do
    if [ "$i" = "$id" ]; then
      return
    fi
  done
  answers="$answers"' '"$id"
  eval "$dbvar"'_answers="$answers"'
}

***REMOVED*** Remove an answer from a database in memory
db_answer_remove() {
  local dbvar="$1" ***REMOVED*** IN/OUT
  local id="$2"    ***REMOVED*** IN
  local new_answers
  local answers
  local i

  eval 'unset '"$dbvar"'_answer_'"$id"

  new_answers=''
  eval 'answers="$'"$dbvar"'_answers"'
  ***REMOVED*** There is no double quote around $answers on purpose
  for i in $answers; do
    if [ "$i" != "$id" ]; then
      new_answers="$new_answers"' '"$i"
    fi
  done
  eval "$dbvar"'_answers="$new_answers"'
}

***REMOVED*** Load all answers from a database on stdin to memory (<dbvar>_answer_*
***REMOVED*** variables)
db_load_from_stdin() {
  local dbvar="$1" ***REMOVED*** OUT

  eval "$dbvar"'_answers=""'

  ***REMOVED*** read doesn't support -r on FreeBSD 3.x. For this reason, the following line
  ***REMOVED*** is patched to remove the -r in case of FreeBSD tools build. So don't make
  ***REMOVED*** changes to it.
  while read -r action p1 p2; do
    if [ "$action" = 'answer' ]; then
      db_answer_add "$dbvar" "$p1" "$p2"
    elif [ "$action" = 'remove_answer' ]; then
      db_answer_remove "$dbvar" "$p1"
    fi
  done
}

***REMOVED*** Load all answers from a database on disk to memory (<dbvar>_answer_*
***REMOVED*** variables)
db_load() {
  local dbvar="$1"  ***REMOVED*** OUT
  local dbfile="$2" ***REMOVED*** IN

  db_load_from_stdin "$dbvar" < "$dbfile"
}

***REMOVED*** Iterate through all answers in a database in memory, calling <func> with
***REMOVED*** id/value pairs and the remaining arguments to this function
db_iterate() {
  local dbvar="$1" ***REMOVED*** IN
  local func="$2"  ***REMOVED*** IN
  shift 2
  local answers
  local i
  local value

  eval 'answers="$'"$dbvar"'_answers"'
  ***REMOVED*** There is no double quote around $answers on purpose
  for i in $answers; do
    eval 'value="$'"$dbvar"'_answer_'"$i"'"'
    "$func" "$i" "$value" "$@"
  done
}

***REMOVED*** If it exists in memory, remove an answer from a database (disk and memory)
db_remove_answer() {
  local dbvar="$1"  ***REMOVED*** IN/OUT
  local dbfile="$2" ***REMOVED*** IN
  local id="$3"     ***REMOVED*** IN
  local answers
  local i

  eval 'answers="$'"$dbvar"'_answers"'
  ***REMOVED*** There is no double quote around $answers on purpose
  for i in $answers; do
    if [ "$i" = "$id" ]; then
      echo 'remove_answer '"$id" >> "$dbfile"
      db_answer_remove "$dbvar" "$id"
      return
    fi
  done
}

***REMOVED*** Add an answer to a database (disk and memory)
db_add_answer() {
  local dbvar="$1"  ***REMOVED*** IN/OUT
  local dbfile="$2" ***REMOVED*** IN
  local id="$3"     ***REMOVED*** IN
  local value="$4"  ***REMOVED*** IN

  db_remove_answer "$dbvar" "$dbfile" "$id"
  echo 'answer '"$id"' '"$value" >> "$dbfile"
  db_answer_add "$dbvar" "$id" "$value"
}

***REMOVED*** Add a file to a database on disk
***REMOVED*** 'file' is the file to put in the database (it may not exist on the disk)
***REMOVED*** 'tsfile' is the file to get the timestamp from, '' if no timestamp
db_add_file() {
  local dbfile="$1" ***REMOVED*** IN
  local file="$2"   ***REMOVED*** IN
  local tsfile="$3" ***REMOVED*** IN
  local date

  if [ "$tsfile" = '' ]; then
    echo 'file '"$file" >> "$dbfile"
  else
    date=`date -r "$tsfile" '+%s' 2> /dev/null`
    if [ "$date" != '' ]; then
      date=' '"$date"
    fi
    echo 'file '"$file$date" >> "$dbfile"
  fi
}

***REMOVED*** Remove file from database
db_remove_file() {
  local dbfile="$1" ***REMOVED*** IN
  local file="$2"   ***REMOVED*** IN

  echo "remove_file $file" >> "$dbfile"
}

***REMOVED*** Add a directory to a database on disk
db_add_dir() {
  local dbfile="$1" ***REMOVED*** IN
  local dir="$2"    ***REMOVED*** IN

  echo 'directory '"$dir" >> "$dbfile"
}
***REMOVED*** END_OF_DB_DOT_SH

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH=${PATH}:/usr/X11R6/bin

Xsession=""
vmware_user=""
vmware_etc_dir="/etc/vmware-tools"
vmware_db=""

failsafe()
{
   ***REMOVED*** Old school -- X11 ports/packages used to be installed under $X11BASE.
   exec /usr/X11R6/lib/X11/xdm/Xsession
   ***REMOVED*** New school -- recent X11 ports/packages installed under $LOCALBASE.
   exec /usr/local/lib/X11/xdm/Xsession
   ***REMOVED*** Linux school
   exec /etc/X11/xdm/Xsession
}

open_db()
{
   vmware_etc_dir="/etc/vmware-tools"
   vmware_db="${vmware_etc_dir}/locations"
   ***REMOVED*** Load up the install-time database
   if [ ! -r "$vmware_db" ]; then
      ***REMOVED*** XXX
      return
   fi
   db_load 'vmdb' "$vmware_db"
}

run_vmware_user()
{
   vmware_user="${vmdb_answer_BINDIR}/vmware-user"

   ***REMOVED*** BINDIR/vmware-user is really a symlink to the setuid wrapper,
   ***REMOVED*** and said wrapper will fork on its own, so there's no need to
   ***REMOVED*** background the process here.
   if [ -n "$vmware_user" -a -x "$vmware_user" ]; then
      "$vmware_user"
   fi
}

exec_xsession()
{
   local x11_base="$vmdb_answer_X11DIR"
   local xrdb="$x11_base/bin/xrdb"
   local xdmConfig="$x11_base/lib/X11/xdm/xdm-config"

   [ -r "$xdmConfig" ] || xdmConfig="/etc/X11/xdm/xdm-config"
   [ -r "$xdmConfig" ] || return

   ***REMOVED*** Determine an Xsession script to run.
   ***REMOVED***
   ***REMOVED*** XXX Even though we require Perl to install and configure the Tools, we
   ***REMOVED*** can't be sure that it's present in the PATH defined above.  If this turns
   ***REMOVED*** out to be a problem, this script can be massaged at config time.
   Xsession=$("$xrdb" -n -DVMWARE_USER_AUTOSTART "$xdmConfig" |
              perl "${vmware_etc_dir}/xsession-xdm.pl")
   exec "$Xsession"
}


main()
{
   if open_db; then
      run_vmware_user

      if [ $***REMOVED*** -ge 1 -a "$1" = "-gdm" ]; then
         exit;
      fi

      exec_xsession
   fi
   failsafe
}

main "$@"
