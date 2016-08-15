***REMOVED***!/bin/sh
***REMOVED***
***REMOVED*** Copyright (C) 1998-2013 VMware, Inc.  All Rights Reserved.
***REMOVED***
***REMOVED*** This script manages the services needed to run VMware software

***REMOVED******REMOVED***VMWARE_INIT_INFO***REMOVED******REMOVED***


***REMOVED*** BEGINNING_OF_UTIL_DOT_SH
***REMOVED***!/bin/sh
***REMOVED***
***REMOVED*** Copyright 2005-2013 VMware, Inc.  All rights reserved.
***REMOVED***
***REMOVED*** A few utility functions used by our shell scripts.  Some expect the settings
***REMOVED*** database to already be loaded and evaluated.

vmblockmntpt="/proc/fs/vmblock/mountPoint"

vmware_failed() {
  if [ "`type -t 'echo_failure' 2>/dev/null`" = 'function' ]; then
    echo_failure
  else
    echo -n "$rc_failed"
  fi
}

vmware_success() {
  if [ "`type -t 'echo_success' 2>/dev/null`" = 'function' ]; then
    echo_success
  else
    echo -n "$rc_done"
  fi
}

***REMOVED*** Execute a macro
vmware_exec() {
  local msg="$1"  ***REMOVED*** IN
  local func="$2" ***REMOVED*** IN
  shift 2

  echo -n '   '"$msg"

  ***REMOVED*** On Caldera 2.2, SIGHUP is sent to all our children when this script exits
  ***REMOVED*** I wanted to use shopt -u huponexit instead but their bash version
  ***REMOVED*** 1.14.7(1) is too old
  ***REMOVED***
  ***REMOVED*** Ksh does not recognize the SIG prefix in front of a signal name
  if [ "$VMWARE_DEBUG" = 'yes' ]; then
    (trap '' HUP; "$func" "$@")
  else
    (trap '' HUP; "$func" "$@") >/dev/null 2>&1
  fi
  if [ "$?" -gt 0 ]; then
    vmware_failed
    echo
    return 1
  fi

  vmware_success
  echo
  return 0
}

***REMOVED*** Execute a macro in the background
vmware_bg_exec() {
  local msg="$1"  ***REMOVED*** IN
  local func="$2" ***REMOVED*** IN
  shift 2

  if [ "$VMWARE_DEBUG" = 'yes' ]; then
    ***REMOVED*** Force synchronism when debugging
    vmware_exec "$msg" "$func" "$@"
  else
    echo -n '   '"$msg"' (background)'

    ***REMOVED*** On Caldera 2.2, SIGHUP is sent to all our children when this script exits
    ***REMOVED*** I wanted to use shopt -u huponexit instead but their bash version
    ***REMOVED*** 1.14.7(1) is too old
    ***REMOVED***
    ***REMOVED*** Ksh does not recognize the SIG prefix in front of a signal name
    (trap '' HUP; "$func" "$@") 2>&1 | logger -t 'VMware[init]' -p daemon.err &

    vmware_success
    echo
    return 0
  fi
}

***REMOVED*** This is a function in case a future product name contains language-specific
***REMOVED*** escape characters.
vmware_product_name() {
  echo 'VMware Tools'
  exit 0
}

***REMOVED*** This is a function in case a future product contains language-specific
***REMOVED*** escape characters.
vmware_product() {
  echo 'tools-for-linux'
  exit 0
}

is_dsp()
{
   ***REMOVED*** This is the current way of indicating it is part of a
   ***REMOVED*** distribution-specific install.  Currently only applies to Tools.
   [ -e "$vmdb_answer_LIBDIR"/dsp ]
}

***REMOVED*** They are a lot of small utility programs to create temporary files in a
***REMOVED*** secure way, but none of them is standard. So I wrote this
make_tmp_dir() {
  local dirname="$1" ***REMOVED*** OUT
  local prefix="$2"  ***REMOVED*** IN
  local tmp
  local serial
  local loop

  tmp="${TMPDIR:-/tmp}"

  ***REMOVED*** Don't overwrite existing user data
  ***REMOVED*** -> Create a directory with a name that didn't exist before
  ***REMOVED***
  ***REMOVED*** This may never succeed (if we are racing with a malicious process), but at
  ***REMOVED*** least it is secure
  serial=0
  loop='yes'
  while [ "$loop" = 'yes' ]; do
    ***REMOVED*** Check the validity of the temporary directory. We do this in the loop
    ***REMOVED*** because it can change over time
    if [ ! -d "$tmp" ]; then
      echo 'Error: "'"$tmp"'" is not a directory.'
      echo
      exit 1
    fi
    if [ ! -w "$tmp" -o ! -x "$tmp" ]; then
      echo 'Error: "'"$tmp"'" should be writable and executable.'
      echo
      exit 1
    fi

    ***REMOVED*** Be secure
    ***REMOVED*** -> Don't give write access to other users (so that they can not use this
    ***REMOVED*** directory to launch a symlink attack)
    if mkdir -m 0755 "$tmp"'/'"$prefix$serial" >/dev/null 2>&1; then
      loop='no'
    else
      serial=`expr $serial + 1`
      serial_mod=`expr $serial % 200`
      if [ "$serial_mod" = '0' ]; then
        echo 'Warning: The "'"$tmp"'" directory may be under attack.'
        echo
      fi
    fi
  done

  eval "$dirname"'="$tmp"'"'"'/'"'"'"$prefix$serial"'
}

***REMOVED*** Removes "stale" device node
***REMOVED*** On udev-based systems, this is never needed.
***REMOVED*** On older systems, after an unclean shutdown, we might end up with
***REMOVED*** a stale device node while the kernel driver has a new major/minor.
vmware_rm_stale_node() {
   local node="$1"  ***REMOVED*** IN
   if [ -e "/dev/$node" -a "$node" != "" ]; then
      local node_major=`ls -l "/dev/$node" | awk '{print \$5}' | sed -e s/,//`
      local node_minor=`ls -l "/dev/$node" | awk '{print \$6}'`
      if [ "$node_major" = "10" ]; then
         local real_minor=`cat /proc/misc | grep "$node" | awk '{print \$1}'`
         if [ "$node_minor" != "$real_minor" ]; then
            rm -f "/dev/$node"
         fi
      else
         local node_name=`echo $node | sed -e s/[0-9]*$//`
         local real_major=`cat /proc/devices | grep "$node_name" | awk '{print \$1}'`
         if [ "$node_major" != "$real_major" ]; then
            rm -f "/dev/$node"
         fi
      fi
   fi
}

***REMOVED*** Checks if the given pid represents a live process.
***REMOVED*** Returns 0 if the pid is a live process, 1 otherwise
vmware_is_process_alive() {
  local pid="$1" ***REMOVED*** IN

  ps -p $pid | grep $pid > /dev/null 2>&1
}

***REMOVED*** Check if the process associated to a pidfile is running.
***REMOVED*** Return 0 if the pidfile exists and the process is running, 1 otherwise
vmware_check_pidfile() {
  local pidfile="$1" ***REMOVED*** IN
  local pid

  pid=`cat "$pidfile" 2>/dev/null`
  if [ "$pid" = '' ]; then
    ***REMOVED*** The file probably does not exist or is empty. Failure
    return 1
  fi
  ***REMOVED*** Keep only the first number we find, because some Samba pid files are really
  ***REMOVED*** trashy: they end with NUL characters
  ***REMOVED*** There is no double quote around $pid on purpose
  set -- $pid
  pid="$1"

  vmware_is_process_alive $pid
}

***REMOVED*** Note:
***REMOVED***  . Each daemon must be started from its own directory to avoid busy devices
***REMOVED***  . Each PID file doesn't need to be added to the installer database, because
***REMOVED***    it is going to be automatically removed when it becomes stale (after a
***REMOVED***    ***REMOVED***). It must go directly under /var/run, or some distributions
***REMOVED***    (RedHat 6.0) won't clean it
***REMOVED***

***REMOVED*** Terminate a process synchronously
vmware_synchrone_kill() {
   local pid="$1"    ***REMOVED*** IN
   local signal="$2" ***REMOVED*** IN
   local second

   kill -"$signal" "$pid"

   ***REMOVED*** Wait a bit to see if the dirty job has really been done
   for second in 0 1 2 3 4 5 6 7 8 9 10; do
      vmware_is_process_alive "$pid"
      if [ "$?" -ne 0 ]; then
         ***REMOVED*** Success
         return 0
      fi

      sleep 1
   done

   ***REMOVED*** Timeout
   return 1
}

***REMOVED*** Kill the process associated to a pidfile
vmware_stop_pidfile() {
   local pidfile="$1" ***REMOVED*** IN
   local pid

   pid=`cat "$pidfile" 2>/dev/null`
   if [ "$pid" = '' ]; then
      ***REMOVED*** The file probably does not exist or is empty. Success
      return 0
   fi
   ***REMOVED*** Keep only the first number we find, because some Samba pid files are really
   ***REMOVED*** trashy: they end with NUL characters
   ***REMOVED*** There is no double quote around $pid on purpose
   set -- $pid
   pid="$1"

   ***REMOVED*** First try a nice SIGTERM
   if vmware_synchrone_kill "$pid" 15; then
      return 0
   fi

   ***REMOVED*** Then send a strong SIGKILL
   if vmware_synchrone_kill "$pid" 9; then
      return 0
   fi

   return 1
}

***REMOVED*** Determine if SELinux is enabled
isSELinuxEnabled() {
   if [ "`cat /selinux/enforce 2> /dev/null`" = "1" ]; then
      echo "yes"
   else
      echo "no"
   fi
}

***REMOVED*** Runs a command and retries under the provided SELinux context if it fails
vmware_exec_selinux() {
   local command="$1"
   ***REMOVED*** XXX We should probably ask the user at install time what context to use
   ***REMOVED*** when we retry commands.  unconfined_t is the correct choice for Red Hat.
   local context="unconfined_t"
   local retval

   $command
   retval=$?
   if [ $retval -ne 0 -a "`isSELinuxEnabled`" = 'yes' ]; then
      runcon -t $context -- $command
      retval=$?
   fi

   return $retval
}

***REMOVED*** Start the blocking file system.  This consists of loading the module and
***REMOVED*** mounting the file system.
vmware_start_vmblock() {
   mkdir -p -m 1777 /tmp/VMwareDnD

   ***REMOVED*** Try FUSE first, fall back on in-kernel module.
   vmware_start_vmblock_fuse && return 0

   vmware_exec 'Loading module' vmware_load_module $vmblock
   exitcode=`expr $exitcode + $?`
   ***REMOVED*** Check to see if the file system is already mounted.
   if grep -q " $vmblockmntpt vmblock " /etc/mtab; then
       ***REMOVED*** If it is mounted, do nothing
       true;
   else
       ***REMOVED*** If it's not mounted, mount it
       vmware_exec_selinux "mount -t vmblock none $vmblockmntpt"
   fi
}

***REMOVED*** Stop the blocking file system
vmware_stop_vmblock() {
    ***REMOVED*** Check if the file system is mounted and only unmount if so.
    ***REMOVED*** Start with FUSE-based version first, then legacy one
    if grep -q " /tmp/vmblock-fuse fuse\.vmware-vmblock " /etc/mtab; then
       ***REMOVED*** if it's mounted, then unmount it
       vmware_exec_selinux "umount /tmp/vmblock-fuse"
    fi
    if grep -q " $vmblockmntpt vmblock " /etc/mtab; then
       ***REMOVED*** if it's mounted, then unmount it
       vmware_exec_selinux "umount $vmblockmntpt"
    fi

    ***REMOVED*** Unload the kernel module
    vmware_unload_module $vmblock
}

***REMOVED*** This is necessary to allow udev time to create a device node.  If we don't
***REMOVED*** wait then udev will override the permissions we choose when it creates the
***REMOVED*** device node after us.
vmware_delay_for_node() {
   local node="$1"
   local delay="$2"

   while [ ! -e $node -a ${delay} -gt 0 ]; do
      delay=`expr $delay - 1`
      sleep 1
   done
}

***REMOVED*** starts after vmci is loaded
vmware_start_vsock() {
  if [ "`isLoaded "$vmci"`" = 'no' ]; then
    ***REMOVED*** vsock depends on vmci
    return 1
  fi
  vmware_load_module $vsock
  vmware_rm_stale_node vsock
  ***REMOVED*** Give udev 5 seconds to create our node
  vmware_delay_for_node "/dev/vsock" 5
  if [ ! -e /dev/vsock ]; then
     local minor=`cat /proc/misc | grep vsock | awk '{print $1}'`
     mknod --mode=666 /dev/vsock c 10 "$minor"
  else
     chmod 666 /dev/vsock
  fi

  return 0
}

***REMOVED*** unloads before vmci
vmware_stop_vsock() {
  vmware_unload_module $vsock
  rm -f /dev/vsock
}

is_ESX_running() {
  if [ ! -f "$vmdb_answer_SBINDIR"/vmware-checkvm ] ; then
    echo no
    return
  fi
  if "$vmdb_answer_SBINDIR"/vmware-checkvm -p | grep -q ESX; then
    echo yes
  else
    echo no
  fi
}

***REMOVED***
***REMOVED*** Start vmblock only if ESX is not running and the config script
***REMOVED*** built/loaded it (kernel is >= 2.4.0 and  product is tools-for-linux).
***REMOVED***
is_vmblock_needed() {
  if [ "`is_ESX_running`" = 'yes' ]; then
    echo no
  else
    if [ "$vmdb_answer_VMBLOCK_CONFED" = 'yes' ]; then
      echo yes
    else
      echo no
    fi
  fi
}

VMUSR_PATTERN="(vmtoolsd.*vmusr|vmware-user)"

vmware_signal_vmware_user() {
***REMOVED*** Signal all running instances of the user daemon.
***REMOVED*** Our pattern ensures that we won't touch the system daemon.
   pkill -$1 -f "$VMUSR_PATTERN"
   return 0
}

***REMOVED*** A USR1 causes vmware-user to release any references to vmblock or
***REMOVED*** /proc/fs/vmblock/mountPoint, allowing vmblock to unload, but vmware-user
***REMOVED*** to continue running. This preserves the user context vmware-user is
***REMOVED*** running within.
vmware_unblock_vmware_user() {
  vmware_signal_vmware_user 'USR1'
}

***REMOVED*** A USR2 causes vmware-user to relaunch itself, picking up vmblock anew.
***REMOVED*** This preserves the user context vmware-user is running within.
vmware_restart_vmware_user() {
  vmware_signal_vmware_user 'USR2'
}

***REMOVED*** Checks if there an instance of vmware-user process exists in the system.
is_vmware_user_running() {
  if pgrep -f "$VMUSR_PATTERN" > /dev/null 2>&1; then
    echo yes
  else
    echo no
  fi
}

wrap () {
  AMSG="$1"
  while [ `echo $AMSG | wc -c` -gt 75 ] ; do
    AMSG1=`echo $AMSG | sed -e 's/\(.\{1,75\} \).*/\1/' -e 's/  [ 	]*/  /'`
    AMSG=`echo $AMSG | sed -e 's/.\{1,75\} //' -e 's/  [ 	]*/  /'`
    echo "  $AMSG1"
  done
  echo "  $AMSG"
  echo " "
}

***REMOVED***---------------------------------------------------------------------------
***REMOVED***
***REMOVED*** load_settings
***REMOVED***
***REMOVED*** Load VMware Installer Service settings
***REMOVED***
***REMOVED*** Returns:
***REMOVED***    0 on success, otherwise 1.
***REMOVED***
***REMOVED*** Side Effects:
***REMOVED***    vmdb_* variables are set.
***REMOVED***---------------------------------------------------------------------------

load_settings() {
  local settings=`$DATABASE/vmis-settings`
  if [ $? -eq 0 ]; then
    eval "$settings"
    return 0
  else
    return 1
  fi
}

***REMOVED***---------------------------------------------------------------------------
***REMOVED***
***REMOVED*** launch_binary
***REMOVED***
***REMOVED*** Launch a binary with resolved dependencies.
***REMOVED***
***REMOVED*** Returns:
***REMOVED***    None.
***REMOVED***
***REMOVED*** Side Effects:
***REMOVED***    Process is replaced with the binary if successful,
***REMOVED***    otherwise returns 1.
***REMOVED***---------------------------------------------------------------------------

launch_binary() {
  local component="$1"		***REMOVED*** IN: component name
  shift
  local binary="$2"		***REMOVED*** IN: binary name
  shift
  local args="$@"		***REMOVED*** IN: arguments
  shift

  ***REMOVED*** Convert -'s in component name to _ and lookup its libdir
  local component=`echo $component | tr '-' '_'`
  local libdir="vmdb_$component_libdir"

  exec "$libdir"'/bin/launcher.sh'		\
       "$libdir"'/lib'				\
       "$libdir"'/bin/'"$binary"		\
       "$libdir"'/libconf' "$args"
  return 1
}
***REMOVED*** END_OF_UTIL_DOT_SH

vmware_etc_dir=/etc/vmware-tools

***REMOVED*** Since this script is installed, our main database should be installed too and
***REMOVED*** should contain the basic information
vmware_db="$vmware_etc_dir"/locations
if [ ! -r "$vmware_db" ]; then
    echo 'Warning: Unable to find '"`vmware_product_name`""'"'s main database '"$vmware_db"'.'
    echo

    exit 1
fi

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

db_load 'vmdb' "$vmware_db"

***REMOVED*** This comment is a hack to prevent RedHat distributions from outputing
***REMOVED*** "Starting <basename of this script>" when running this startup script.
***REMOVED*** We just need to write the word daemon followed by a space --hpreg.

***REMOVED*** This defines echo_success() and echo_failure() on RedHat
if [ -r "$vmdb_answer_INITSCRIPTSDIR"'/functions' ]; then
    . "$vmdb_answer_INITSCRIPTSDIR"'/functions'
fi

***REMOVED*** This defines $rc_done and $rc_failed on S.u.S.E.
if [ -f /etc/rc.config ]; then
   ***REMOVED*** Don't include the entire file: there could be conflicts
   rc_done=`(. /etc/rc.config; echo "$rc_done")`
   rc_failed=`(. /etc/rc.config; echo "$rc_failed")`
else
   ***REMOVED*** Make sure the ESC byte is literal: Ash does not support echo -e
   rc_done='[71G done'
   rc_failed='[71Gfailed'
fi

***REMOVED***
***REMOVED*** Global variables
***REMOVED***
vmmemctl="vmmemctl"
vmxnet="vmxnet"
vmxnet3="vmxnet3"
vmhgfs="vmhgfs"
subsys="vmware-tools"
vmblock="vmblock"
vmci="vmci"
vsock="vsock"
vmsync="vmsync"
acpi="acpiphp"
pvscsi="pvscsi"

vmhgfs_mnt="/mnt/hgfs"

***REMOVED***
***REMOVED*** Utilities
***REMOVED***

***REMOVED*** BEGINNING_OF_IPV4_DOT_SH
***REMOVED***!/bin/sh

***REMOVED***
***REMOVED*** IPv4 address functions
***REMOVED***
***REMOVED*** Thanks to Owen DeLong <owen@delong.com> for pointing me at bash's arithmetic
***REMOVED*** expansion ability, which is a lot faster than using 'expr'
***REMOVED***

***REMOVED*** Compute the subnet address associated to a couple IP/netmask
ipv4_subnet() {
  local ip="$1"
  local netmask="$2"

  ***REMOVED*** Split quad-dotted addresses into bytes
  ***REMOVED*** There is no double quote around the back-quoted expression on purpose
  ***REMOVED*** There is no double quote around $ip and $netmask on purpose
  set -- `IFS='.'; echo $ip $netmask`

  echo $(($1 & $5)).$(($2 & $6)).$(($3 & $7)).$(($4 & $8))
}

***REMOVED*** Compute the broadcast address associated to a couple IP/netmask
ipv4_broadcast() {
  local ip="$1"
  local netmask="$2"

  ***REMOVED*** Split quad-dotted addresses into bytes
  ***REMOVED*** There is no double quote around the back-quoted expression on purpose
  ***REMOVED*** There is no double quote around $ip and $netmask on purpose
  set -- `IFS='.'; echo $ip $netmask`

  echo $(($1 | (255 - $5))).$(($2 | (255 - $6))).$(($3 | (255 - $7))).$(($4 | (255 - $8)))
}
***REMOVED*** END_OF_IPV4_DOT_SH

upperCase() {
  echo "`echo $1|tr '[:lower:]' '[:upper:]'`"
}

kernAsKey() {
  uname -r | tr -d '+-.'
}

vmware_getModName() {
  local module=`upperCase $1`
  local var='vmdb_answer_'"${module}_`kernAsKey`"'_NAME'

  ***REMOVED*** Indirect references in sh.  Oh sh, how I love thee...
  eval result=\$$var
  if [ "$result" != '' ]; then
     echo "$result"
  else
     echo "$1"
  fi
}

vmware_getModPath() {
  local module=`upperCase $1`
  local var='vmdb_answer_'"${module}_`kernAsKey`"'_PATH'

  eval result=\$$var
  if [ "$result" != '' ]; then
     echo "$result"
  else
     echo "$1"
  fi
}

if [ -e "$vmdb_answer_SBINDIR"/vmtoolsd ]; then
   SYSTEM_DAEMON=vmtoolsd
else
   SYSTEM_DAEMON=vmware-guestd
fi

***REMOVED*** Are we running in a VM?
vmware_inVM() {
  "$vmdb_answer_SBINDIR"/vmware-checkvm >/dev/null 2>&1
}

vmware_hwVersion() {
  "$vmdb_answer_SBINDIR"/vmware-checkvm -h | grep hw | cut -d ' ' -f 5
}

***REMOVED*** Is a given module loaded?
isLoaded() {
  ***REMOVED*** Check for both the original module name and the newer module name

  local module="$1"
  local module_name="`vmware_getModName $1`"

  /sbin/lsmod | awk 'BEGIN {n = "no";} {if ($1 == "'"$module"'") n = "yes";} {if ($1 == "'"$module_name"'") n = "yes";} END {print n;}'
}

***REMOVED*** Build a Linux kernel integer version
kernel_version_integer() {
  echo $(((($1 * 256) + $2) * 256 + $3))
}

***REMOVED*** Get the running kernel integer version
get_version_integer() {
  local version_uts
  local v1
  local v2
  local v3

  version_uts=`uname -r`

  ***REMOVED*** There is no double quote around the back-quoted expression on purpose
  ***REMOVED*** There is no double quote around $version_uts on purpose
  set `IFS='.'; echo $version_uts`
  v1="$1"
  v2="$2"
  v3="$3"
  ***REMOVED*** There is no double quote around the back-quoted expression on purpose
  ***REMOVED*** There is no double quote around $v3 on purpose
  set `IFS='-ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz'; echo $v3`
  v3="$1"

  kernel_version_integer "$v1" "$v2" "$v3"
}

***REMOVED***
***REMOVED*** We exit on failure because these functions are called within the
***REMOVED*** context of vmware_exec, which sets up a trap that causes exit to jump
***REMOVED*** back to vmware_exec, like an exception handler. On success, we return
***REMOVED*** because our caller may want to perform additional instructions.
***REMOVED***
***REMOVED*** XXX: This really belongs in util.sh but that requires reconciling
***REMOVED*** the hosted scripts as well.  It would also allow it to be easily
***REMOVED*** overriden by the DSP init script.
vmware_load_module() {
   local moduleName=`vmware_getModName $1`
   vmware_unload_module $1
   vmware_insmod $1
   return 0
}

vmware_insmod() {
   local module_path="`vmware_getModPath $1`"
   local module_name="`vmware_getModName $1`"
   if [ -e "$module_path.o" ]; then
      /sbin/insmod -s -f "$module_path.o" >/dev/null 2>&1 || \
         /sbin/insmod -s -f "$module_name" >/dev/null 2>&1 || exit 1
   elif [ -e "$module_path.ko" ]; then
      /sbin/insmod -s -f "$module_path.ko" >/dev/null 2>&1 || \
         /sbin/insmod -s -f "$module_name" >/dev/null 2>&1 || exit 1
   fi
   return 0
}

vmware_unload_module() {
   local module="$1"
   local module_name="`vmware_getModName $1`"
   if [ "`isLoaded "$1"`" = 'yes' ]; then
      /sbin/rmmod "$module" >/dev/null 2>&1 || \
         /sbin/rmmod "$module_name" >/dev/null 2>&1 || exit 1
   fi
   return 0
}

***REMOVED***
***REMOVED*** Note:
***REMOVED***  . Each daemon must be started from its own directory to avoid busy devices
***REMOVED***  . Each PID file doesn't need to be added to the installer database, because
***REMOVED***    it is going to be automatically removed when it becomes stale (after a
***REMOVED***    ***REMOVED***). It must go directly under /var/run, or some distributions
***REMOVED***    (RedHat 6.0) won't clean it
***REMOVED***

vmware_start_daemon() {
   [ ! -d $vmdb_answer_SBINDIR ] && return 1

   command="$vmdb_answer_SBINDIR/$1 --background /var/run/$1.pid"
   vmware_exec_selinux "$command"
}

vmware_stop_daemon() {
   local pidfile="/var/run/$1.pid"
   if vmware_stop_pidfile $pidfile; then
     rm -f $pidfile
   fi
}

vmware_daemon_status() {
   echo -n "$1 "
   if vmware_check_pidfile "/var/run/$1.pid"; then
      echo 'is running'
   else
      echo 'is not running'
      exitcode=$(($exitcode + 1))
   fi
}

***REMOVED*** Start the virtual ethernet kernel service
vmware_start_vmxnet() {
   ***REMOVED*** only load vmxnet if it's not already loaded
   if [ "`isLoaded "$vmxnet"`" = 'no' ]; then
     vmware_load_module $vmxnet
   fi
}

vmware_start_vmxnet3() {
   ***REMOVED*** only load vmxnet3 if it's not already loaded
   if [ "`isLoaded "$vmxnet3"`" = 'no' ]; then
     vmware_load_module $vmxnet3
   fi
}

vmware_switch() {
  "$vmdb_answer_BINDIR"/vmware-config-tools.pl --switch
  return 0
}

***REMOVED*** Start the guest virtual memory manager
vmware_start_vmmemctl() {
  vmware_load_module $vmmemctl
}

***REMOVED*** Stop the guest virtual memory manager
vmware_stop_vmmemctl() {
  vmware_unload_module $vmmemctl
}

***REMOVED*** Start the guest vmci driver
vmware_start_vmci() {
  ***REMOVED*** only load vmci if it's not already loaded
  if [ "`isLoaded "$vmci"`" = 'no' ]; then
    vmware_load_module $vmci
  fi
  if [ ! -e /dev/vmci ]; then
    local major=`cat /proc/devices | grep vmci | awk '{print $1}'`
    mknod --mode=600 /dev/vmci c $major 0
  else
    chmod 600 /dev/vmci
  fi
}

***REMOVED*** unmount it
vmware_stop_vmci() {
  if [ "`isLoaded "$vsock"`" = 'yes' ]; then
    vmware_stop_vsock
  fi

  vmware_unload_module $vmci
  rm -f /dev/vmci
}

***REMOVED*** Identify whether there's a mount mounted on the default hgfs mountpoint
is_vmhgfs_mounted() {
***REMOVED***   if [ `grep -q " $vmhgfs_mnt vmhgfs " /etc/mtab` ];
***REMOVED***   Using this method instead as it is more robust.  The above
***REMOVED***   line has the possibility of ALWAYS returning a failure.
    if grep -q " $vmhgfs_mnt vmhgfs " /etc/mtab; then
        echo "yes"
    else
        echo "no"
    fi
}

***REMOVED*** Mount all hgfs filesystems
vmware_mount_vmhgfs() {
  if [ "`is_vmhgfs_mounted`" = "no" ]; then
    vmware_exec_selinux "mount -t vmhgfs .host:/ $vmhgfs_mnt"
  fi
}

***REMOVED*** Start the guest filesystem driver and mount it
vmware_start_vmhgfs() {
  ***REMOVED*** only load vmhgfs if it's not already loaded
  if [ "`isLoaded "$vmhgfs"`" = 'no' -a "`isLoaded "$vmci"`" = 'yes' ]; then
    vmware_load_module $vmhgfs
  fi
}

***REMOVED*** Unmount all hgfs filesystems left mounted
vmware_unmount_vmhgfs() {
  if [ "`is_vmhgfs_mounted`" = "yes" ]; then
    vmware_exec_selinux "umount $vmhgfs_mnt"
  fi
}

***REMOVED*** Stop the guest filesystem driver
vmware_stop_vmhgfs() {
  vmware_unload_module $vmhgfs
}

***REMOVED*** Setup thinprint serial port and start daemon
vmware_start_thinprint() {
   if [ "$vmdb_answer_THINPRINT_CONFED" = 'yes' ]; then
      ***REMOVED*** set serial port in tpvmlp.conf
      local serialPort=`vmware_thinprint_get_tty`
      mv -f /etc/tpvmlp.conf /etc/tpvmlp.conf.bak
      sed -e "/^\s*vmwcomgw\s*=/s/=.*/= \/dev\/$serialPort/" /etc/tpvmlp.conf.bak \
         > /etc/tpvmlp.conf
      rm -f /etc/tpvmlp.conf.bak

      ***REMOVED*** Find the right CUPS script for this system
      for f in "/etc/init.d/cupsys" "/etc/init.d/cups"; do
         if [ -f $f ]; then
            cupsscript=$f
         fi
      done

      ***REMOVED*** If we found CUPS, start it, wait, then start tpvmlpd
      if [ $cupsscript ]; then
         $cupsscript start
         sleep 2

         export TPVMLP_SVC=global:daemon
         /usr/bin/tpvmlpd
      fi
   fi
}

***REMOVED*** Stop thinprint daemon
vmware_stop_thinprint() {
   vmware_stop_pidfile "/var/run/tpvmlpd.pid"
}

vmware_thinprint_get_tty() {
   "$vmdb_answer_SBINDIR"/$SYSTEM_DAEMON --cmd 'info-get guestinfo.vprint.thinprintBackend' | \
	   sed -e s/serial/ttyS/
}

***REMOVED*** Load the vmsync driver
vmware_start_vmsync() {
   vmware_load_module $vmsync
}

***REMOVED*** Unload the vmsync driver
vmware_stop_vmsync() {
   vmware_unload_module $vmsync
}

vmware_start_acpi_hotplug() {
   if [ `isLoaded $acpi` = 'yes' ]; then
      ***REMOVED*** acpiphp is already loaded.  Success.
      return 0
   fi
   ***REMOVED*** Don't allow pciehp and acpiphp to overlap.  Also don't unload
   ***REMOVED*** pciehp in order to then load acpiphp as this won't avoid acpiphp
   ***REMOVED*** crashing while trying to register a device node pciehp already has.
   ***REMOVED*** All this only before 2.6.17 - since 2.6.17 pciehp and acpiphp can
   ***REMOVED*** coexist.
   if [ `isLoaded pciehp` = 'yes' ]; then
      local ok_kver=`kernel_version_integer '2' '6' '17'`
      local run_kver=`get_version_integer`
      if [ $run_kver -lt $ok_kver ]; then
         return 1
      fi
   fi
   modprobe $acpi
   return 0
}

vmware_stop_acpi_hotplug() {
   vmware_unload_module $acpi
}

***REMOVED*** Don't use vmware_load_module() because it first
***REMOVED*** tries to unload the module which we don't want here.
vmware_start_pvscsi() {
   if ! /sbin/modinfo $pvscsi ; then
      ***REMOVED*** Apparently pvscsi does not exist on this system, so punt.
      return 0
   fi
   if [ `isLoaded $pvscsi` != 'yes' ]; then
      vmware_insmod $pvscsi
   fi
}

vmware_stop_pvscsi() {
   vmware_unload_module $pvscsi
}

is_vmhgfs_needed() {
  local min_kver=`kernel_version_integer '2' '4' '0'`
  local run_kver=`get_version_integer`
  if [ $min_kver -le $run_kver -a "$vmdb_answer_VMHGFS_CONFED" = 'yes' ]; then
    echo yes
  else
    echo no
  fi
}

is_vmmemctl_needed() {
  if [ "$vmdb_answer_VMMEMCTL_CONFED" = 'yes' ]; then
    echo yes
  else
    echo no
  fi
}

is_pvscsi_needed() {
  if [ "$vmdb_answer_PVSCSI_CONFED" = 'yes' ]; then
    echo yes
  else
    echo no
  fi
}

is_acpi_hotplug_needed() {
  ***REMOVED*** Must have DVHP in ACPI tables.  There are now two places we need to check for it.
  dev=''
  for path in /proc/acpi/dsdt /sys/firmware/acpi/tables/DSDT; do
    if [ -e $path ]; then
      dev="$path"
    fi
  done
  ***REMOVED*** If neither of those paths exist, return no
  if [ -z "$dev" ]; then
     echo no
     return
  fi
  ***REMOVED*** Otherwise search for DVHP
  if grep -q DVHP $dev; then
    ***REMOVED*** Look for bridge, PCI-PCI is 0790, PCIe is 07a0.
    cat /proc/bus/pci/devices | grep -qi "^[0-9a-f]*	15ad07[9a]0	"
    if [ "$?" -eq 0 ]; then
      echo yes
      return
    fi
  fi
  echo no
}

is_vmxnet_needed() {

  ***REMOVED*** First try vmxnet's vendor/device ID's
  cat /proc/bus/pci/devices | grep -qi "^[0-9a-f]*	15ad0720	"
  if [ "$?" -eq 0 -a "$vmdb_answer_VMXNET_CONFED" = 'yes' ]; then
    echo yes
  else
    ***REMOVED*** Now try pcnet32's vendor/device ID's...see bug 79352
    ***REMOVED*** We only accept pcnet32 if the HW version of the VM is ws50 or later
    local hwver=`vmware_hwVersion`
    cat /proc/bus/pci/devices | grep -qi "^[0-9a-f]*	10222000	"
    if [ "$?" -eq 0 -a "$vmdb_answer_VMXNET_CONFED" = 'yes' -a \
	 $hwver -ge 4 ]; then
      echo yes
    else
      echo no
    fi
  fi
}

is_vmxnet3_needed() {
  cat /proc/bus/pci/devices | grep -qi "^[0-9a-f]*	15ad07b0	"
  if [ "$?" -eq 0 -a "$vmdb_answer_VMXNET3_CONFED" = 'yes' ]; then
    echo yes
  else
    echo no
  fi
}

is_vmci_needed() {
   if [ "`is_vsock_needed`" = 'yes' -o "`is_vmhgfs_needed`" = 'yes' \
        -o "$vmdb_answer_VMCI_CONFED" = 'yes' ]; then
      echo yes
   else
      echo no
   fi
}

is_vsock_needed() {
   if [ "$vmdb_answer_VSOCK_CONFED" = 'yes' ]; then
      echo yes
   else
      echo no
   fi
}

is_vmsync_needed() {
   local min_kver=`kernel_version_integer '2' '6' '6'`
   local run_kver=`get_version_integer`
   if [ $min_kver -le $run_kver -a "$vmdb_answer_VMSYNC_CONFED" = 'yes' ]; then
      echo yes
   else
      echo no
   fi
}

vmware_start_vmblock_fuse() {
   ***REMOVED*** 2.6.27 is pretty arbitrary but we already  have in-kernel
   ***REMOVED*** vmblock for earlier versions
   local ok_kver=`kernel_version_integer '2' '6' '27'`
   local run_kver=`get_version_integer`
   if [ $run_kver -lt $ok_kver ]; then
      return 1
   fi

   if ! grep -q "fuse" /proc/filesystems; then
      ***REMOVED*** Try to load fuse module if it is not there yet.
      modprobe fuse > /dev/null 2>&1 || return 1
   fi

   if grep -q " /tmp/vmblock-fuse fuse\.vmware-vmblock " /etc/mtab; then
      true;
   else
      mkdir -p /tmp/vmblock-fuse
      vmware_exec_selinux "$vmdb_answer_SBINDIR/vmware-vmblock-fuse \
         -o subtype=vmware-vmblock,default_permissions,allow_other \
         /tmp/vmblock-fuse"
   fi
}

main()
{
   ***REMOVED*** See how we were called.
   case "$1" in
      start)

         ***REMOVED*** If the service has already been started exit right away
         [ -f /var/lock/subsys/"$subsys" ] && exit 0

         exitcode='0'
         if [ "`is_acpi_hotplug_needed`" = 'yes' ]; then
            vmware_exec "Checking acpi hot plug" vmware_start_acpi_hotplug
         fi
         if vmware_inVM; then
            if ! is_dsp && [ -e "$vmware_etc_dir"/not_configured ]; then
               echo "`vmware_product_name`"' is installed, but it has not been '
               echo '(correctly) configured for the running kernel.'
               echo 'To (re-)configure it, invoke the following command: '
               echo "$vmdb_answer_BINDIR"'/vmware-config-tools.pl.'
               echo
               exit 1
            fi

            echo 'Starting VMware Tools services in the virtual machine:'
            vmware_exec 'Switching to guest configuration:' vmware_switch
            exitcode=$(($exitcode + $?))

	    if [ "`is_pvscsi_needed`" = 'yes' ]; then
		vmware_exec 'Paravirtual SCSI module:' vmware_start_pvscsi
		exitcode=$(($exitcode + $?))
	    fi

            if [ "`is_vmmemctl_needed`" = 'yes' ]; then
               vmware_exec 'Guest memory manager:' vmware_start_vmmemctl
               exitcode=$(($exitcode + $?))
            fi

            if [ "`is_vmxnet_needed`" = 'yes' ]; then
               vmware_exec 'Guest vmxnet fast network device:' vmware_start_vmxnet
               exitcode=$(($exitcode + $?))
            fi

            if [ "`is_vmxnet3_needed`" = 'yes' ]; then
               vmware_exec 'Driver for the VMXNET 3 virtual network card:' vmware_start_vmxnet3
               exitcode=$(($exitcode + $?))
            fi

            if [ "`is_vmci_needed`" = 'yes' ]; then
               vmware_exec 'VM communication interface:' vmware_start_vmci
            fi

         ***REMOVED*** vsock needs vmci started first
            if [ "`is_vsock_needed`" = 'yes' ]; then
               vmware_exec 'VM communication interface socket family:' vmware_start_vsock
               exitcode=$(($exitcode + $?))
            fi

         ***REMOVED*** vmhgfs needs vmci started first
            if [ "`is_vmhgfs_needed`" = 'yes' -a "`is_ESX_running`" = 'no' ]; then
               vmware_exec 'Guest filesystem driver:' vmware_start_vmhgfs
               exitcode=$(($exitcode + $?))
               vmware_exec 'Mounting HGFS shares:' vmware_mount_vmhgfs
	    ***REMOVED*** Ignore the exitcode. The mount may fail if HGFS is disabled
	    ***REMOVED*** in the host, in which case requiring a rerun of the Tools
	    ***REMOVED*** configurator is useless.
            fi

            if [ "`is_vmblock_needed`" = 'yes' ] ; then
               vmware_exec 'Blocking file system:' vmware_start_vmblock
               exitcode=$(($exitcode + $?))
            fi

            ***REMOVED*** Signal vmware-user to relaunch itself and maybe restore
            ***REMOVED*** contact with the blocking file system.
            if [ "`is_vmware_user_running`" = 'yes' ]; then
               vmware_exec 'VMware User Agent:' vmware_restart_vmware_user
            fi

            if [ "`is_vmsync_needed`" = 'yes' ] ; then
               vmware_exec 'File system sync driver:' vmware_start_vmsync
               exitcode=$(($exitcode + $?))
            fi

            vmware_exec 'Guest operating system daemon:' vmware_start_daemon $SYSTEM_DAEMON
            exitcode=$(($exitcode + $?))

	    if [ "`is_ESX_running`" = 'no' ]; then
	       vmware_exec 'Virtual Printing daemon:' vmware_start_thinprint
	       ***REMOVED*** Ignore the exitcode. The 64bit version of tpvlpd segfault.
	       ***REMOVED*** There is not much we can do about it.
	    fi

         else
            echo 'Starting VMware Tools services on the host:'
            vmware_exec 'Switching to host config:' vmware_switch
            exitcode=$(($exitcode + $?))
         fi

         if ! is_dsp && [ "$exitcode" -gt 0 ]; then
            exit 1
         fi

         [ -d /var/lock/subsys ] || mkdir -p /var/lock/subsys
         touch /var/lock/subsys/"$subsys"
         ;;

      stop)
         exitcode='0'

         if vmware_inVM; then
            echo 'Stopping VMware Tools services in the virtual machine:'
            vmware_exec 'Guest operating system daemon:' vmware_stop_daemon $SYSTEM_DAEMON
            exitcode=$(($exitcode + $?))

	    if [ "`is_ESX_running`" = 'no' ]; then
	       vmware_exec 'Virtual Printing daemon:' vmware_stop_thinprint
               exitcode=$(($exitcode + $?))
	    fi

            if [ "`is_vmblock_needed`" = 'yes' ] ; then
           ***REMOVED*** Signal vmware-user to release any contact with the blocking fs.
               vmware_exec 'VMware User Agent (vmware-user):' vmware_unblock_vmware_user
               rv=$?
               exitcode=$(($exitcode + $rv))
           ***REMOVED*** If unblocking vmware-user fails then stopping and unloading vmblock
           ***REMOVED*** probably will also fail.
               if [ $rv -eq 0 ]; then
                  vmware_exec 'Blocking file system:' vmware_stop_vmblock
                  exitcode=$(($exitcode + $?))
	       fi
	    fi

            vmware_exec 'Unmounting HGFS shares:' vmware_unmount_vmhgfs
            rv=$?
            vmware_exec 'Guest filesystem driver:' vmware_stop_vmhgfs
            rv=$(($rv + $?))
            if [ "`is_vmhgfs_needed`" = 'yes' ]; then
               exitcode=$(($exitcode + $rv))
            fi

            if [ "`is_vmmemctl_needed`" = 'yes' ]; then
               vmware_exec 'Guest memory manager:' vmware_stop_vmmemctl
               exitcode=$(($exitcode + $?))
            fi

         ***REMOVED*** vsock requires vmci to work so it must be unloaded before vmci
            if [ "`is_vsock_needed`" = 'yes' ]; then
               vmware_exec 'VM communication interface socket family:' vmware_stop_vsock
               exitcode=$(($exitcode + $?))
            fi

            if [ "`is_vmci_needed`" = 'yes' ]; then
               vmware_exec 'VM communication interface:' vmware_stop_vmci
               exitcode=$(($exitcode + $?))
            fi

            if [ "`is_vmsync_needed`" = 'yes' ] ; then
               vmware_exec 'File system sync driver:' vmware_stop_vmsync
               exitcode=$(($exitcode + $?))
            fi

         else
            echo -n 'Skipping VMware Tools services shutdown on the host:'
            vmware_success
            echo
         fi
         if [ "$exitcode" -gt 0 ]; then
            exit 1
         fi

         rm -f /var/lock/subsys/"$subsys"
         ;;

      status)
         exitcode='0'

         vmware_daemon_status $SYSTEM_DAEMON
         exitcode=$(($exitcode + $?))

         if [ "$exitcode" -ne 0 ]; then
            exit 1
         fi
         ;;

      restart | force-reload)
         "$0" stop && "$0" start
         ;;
      source)
         ***REMOVED*** Used to source the script so that functions can be
         ***REMOVED*** selectively overriden.
         return 0
         ;;
      *)
         echo "Usage: `basename "$0"` {start|stop|status|restart|force-reload}"
         exit 1
   esac

   exit 0
}

main "$@"
