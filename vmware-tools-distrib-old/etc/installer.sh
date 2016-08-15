***REMOVED***!/bin/sh
***REMOVED*** Tar installer object
***REMOVED***
***REMOVED*** This file is saved on the disk when the .tar package is installed by
***REMOVED*** vmware-install.pl. It can be invoked by any installer.

***REMOVED***
***REMOVED*** Tools
***REMOVED***

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

***REMOVED***
***REMOVED*** Implementation of the methods
***REMOVED***

***REMOVED*** Return the human-readable type of the installer
installer_kind() {
  echo 'tar'

  exit 0
}

***REMOVED*** Return the human-readable version of the installer
installer_version() {
  echo '4'

  exit 0
}

***REMOVED*** Return the specific VMware product
vmware_product() {
  echo 'tools-for-linux'

  exit 0
}

***REMOVED*** Set the name of the main /etc/vmware* directory
***REMOVED*** Set up variables depending on the main RegistryDir
initialize_globals() {
  if [ "`vmware_product`" = 'console' ]; then
    gRegistryDir='/etc/vmware-console'
    gUninstaller='vmware-uninstall-console.pl'
  elif [ "`vmware_product`" = 'api' ]; then
    gRegistryDir='/etc/vmware-api'
    gUninstaller='vmware-uninstall-api.pl'
  elif [ "`vmware_product`" = 'mui' ]; then
    gRegistryDir='/etc/vmware-mui'
    gUninstaller='vmware-uninstall-mui.pl'
  elif [ "`vmware_product`" = 'tools-for-linux' ]; then
    gRegistryDir='/etc/vmware-tools'
    gUninstaller='vmware-uninstall-tools.pl'
  elif [ "`vmware_product`" = 'tools-for-freebsd' ]; then
    gRegistryDir='/etc/vmware-tools'
    gUninstaller='vmware-uninstall-tools.pl'
  elif [ "`vmware_product`" = 'tools-for-solaris' ]; then
    gRegistryDir='/etc/vmware-tools'
    gUninstaller='vmware-uninstall-tools.pl'
  elif [ "`vmware_product`" = 'vix' ]; then
    gRegistryDir='/etc/vmware-vix'
    gUninstaller='vmware-uninstall-vix.pl'
  elif [ "`vmware_product`" = 'vix-disklib' ]; then
    gRegistryDir='/etc/vmware-vix-disklib'
    gUninstaller='vmware-uninstall-vix-disklib.pl'
  elif [ "`vmware_product`" = 'viperl' ]; then
    gRegistryDir='/etc/vmware-viperl'
    gUninstaller='vmware-uninstall-viperl.pl'
  elif [ "`vmware_product`" = 'vicli' ]; then
    gRegistryDir='/etc/vmware-vcli'
    gUninstaller='vmware-uninstall-vSphere-CLI.pl'
  elif [ "`vmware_product`" = 'nvdk' ]; then
    gRegistryDir='/etc/vmware-nvdk'
    gUninstaller='vmware-uninstall-nvdk.pl'
  else
    gRegistryDir='/etc/vmware'
    gUninstaller='vmware-uninstall.pl'
  fi
  gInstallerMainDB="$gRegistryDir"'/locations'
}

***REMOVED*** Convert the installer database format to formats used by older installers
***REMOVED*** The output should be a .tar.gz containing enough information to allow a
***REMOVED*** clean "upgrade" (which will actually be a downgrade) by an older installer
installer_convertdb() {
  local format="$1"
  local output="$2"
  local tmpdir

  case "$format" in
    rpm4|tar4)
      if [ "$format" = 'tar4' ]; then
        echo 'Keeping the tar4 installer database format.'
      else
        echo 'Converting the tar4 installer database format'
        echo '        to the rpm4 installer database format.'
      fi
      echo
      ***REMOVED*** The next installer uses the same database format. Backup a full
      ***REMOVED*** database state that it can use as a fresh new database.
      ***REMOVED***
      ***REMOVED*** Everything should go in:
      ***REMOVED***  /etc/vmware*/
      ***REMOVED***              state/
      ***REMOVED***
      ***REMOVED*** But those directories do not have to be referenced,
      ***REMOVED*** the next installer will do it just after restoring the backup
      ***REMOVED*** because only it knows if those directories have been created.
      ***REMOVED***
      ***REMOVED*** Also, do not include those directories in the backup, because some
      ***REMOVED*** versions of tar (1.13.17+ are ok) do not untar directory permissions
      ***REMOVED*** as described in their documentation.
      make_tmp_dir 'tmpdir' 'vmware-installer'
      mkdir -p "$tmpdir""$gRegistryDir"
      db_add_file "$tmpdir""$gInstallerMainDB" "$gInstallerMainDB" ''
      db_load 'db' "$gInstallerMainDB"
      write() {
        local id="$1"
        local value="$2"
        local dbfile="$3"

        ***REMOVED*** No database conversions are necessary

        echo 'answer '"$id"' '"$value" >> "$dbfile"
      }
      db_iterate 'db' 'write' "$tmpdir""$gInstallerMainDB"
      files='./'"$gInstallerMainDB"
      
      ***REMOVED*** The Bourne shell (Solaris' default) doesn't support -e so use -f
      ***REMOVED*** instead.  We only need to worry about this for tar4 and tar3 since the
      ***REMOVED*** Solaris Tools did not exist before the tar3 database version was
      ***REMOVED*** created.
      configExists='no'
      if [ "`vmware_product`" = 'tools-for-solaris' ]; then
         if [ -f "$gRegistryDir"/config ]; then
            configExists='yes'
         fi
      elif [ -e "$gRegistryDir"/config ]; then
         configExists='yes'
      fi
      if [ "$configExists" = 'yes' ]; then
         mkdir -p "$tmpdir""$gRegistryDir"'/state'
         cp "$gRegistryDir"/config "$tmpdir""$gRegistryDir"'/state/config'
         db_add_file "$tmpdir""$gInstallerMainDB" "$gRegistryDir"'/state/config' "$tmpdir""$gRegistryDir"'/state/config'
         files="$files"' .'"$gRegistryDir"'/state/config'
      fi
      ***REMOVED*** There is no double quote around $files on purpose
      if [ "`vmware_product`" = 'tools-for-solaris' ]; then
         ***REMOVED*** Solaris' tar(1) does not support gnu tar's -C and -z options.
         origDir=`pwd`
         cd "$tmpdir" && tar -copf - $files | gzip > "$output"
         cd $origDir
      else
         tar -C "$tmpdir" -czopf "$output" $files 2> /dev/null
      fi
      rm -rf "$tmpdir"

      exit 0;
      ;;
    rpm3|tar3)
      echo 'Converting the tar4 installer database format'
      echo '        to the '"$format"' installer database format.'
      echo
      ***REMOVED*** The next installer uses the same database format. Backup a full
      ***REMOVED*** database state that it can use as a fresh new database.
      ***REMOVED***
      ***REMOVED*** Everything should go in:
      ***REMOVED***  /etc/vmware*/
      ***REMOVED***              state/
      ***REMOVED***
      ***REMOVED*** But those directories do not have to be referenced,
      ***REMOVED*** the next installer will do it just after restoring the backup
      ***REMOVED*** because only it knows if those directories have been created.
      ***REMOVED***
      ***REMOVED*** Also, do not include those directories in the backup, because some
      ***REMOVED*** versions of tar (1.13.17+ are ok) do not untar directory permissions
      ***REMOVED*** as described in their documentation.
      make_tmp_dir 'tmpdir' 'vmware-installer'
      mkdir -p "$tmpdir""$gRegistryDir"
      db_add_file "$tmpdir""$gInstallerMainDB" "$gInstallerMainDB" ''
      db_load 'db' "$gInstallerMainDB"
      write() {
        local id="$1"
        local value="$2"
        local dbfile="$3"

        ***REMOVED*** The tar4|rpm4 added two keywords that are not supported by earlier
        ***REMOVED*** installers.   These are removed here so that they don't propagate
        ***REMOVED*** back through on a subsequent upgrade (with perhaps no longer correct
        ***REMOVED*** values)
        ***REMOVED***
        ***REMOVED***    VNET_n_DHCP            -> <nothing>
        ***REMOVED***    VNET_n_HOSTONLY_SUBNET -> <nothing>
        ***REMOVED***
        if echo $id | grep 'VNET_[[:digit:]]\+_DHCP' &>/dev/null; then
           return;
        elif echo $id | grep 'VNET_[[:digit:]]\+_HOSTONLY_SUBNET' &>/dev/null; then
           return;
        fi

        echo 'answer '"$id"' '"$value" >> "$dbfile"
      }
      db_iterate 'db' 'write' "$tmpdir""$gInstallerMainDB"
      files='./'"$gInstallerMainDB"
      
      ***REMOVED*** The Bourne shell (Solaris' default) doesn't support -e so use -f
      ***REMOVED*** instead.  We only need to worry about this for tar4 and tar3 since the
      ***REMOVED*** Solaris Tools did not exist before the tar3 database version was
      ***REMOVED*** created.
      configExists='no'
      if [ "`vmware_product`" = 'tools-for-solaris' ]; then
         if [ -f "$gRegistryDir"/config ]; then
            configExists='yes'
         fi
      elif [ -e "$gRegistryDir"/config ]; then
         configExists='yes'
      fi
      if [ "$configExists" = 'yes' ]; then
        mkdir -p "$tmpdir""$gRegistryDir"'/state'
        cp "$gRegistryDir"/config "$tmpdir""$gRegistryDir"'/state/config'
        db_add_file "$tmpdir""$gInstallerMainDB" "$gRegistryDir"'/state/config' "$tmpdir""$gRegistryDir"'/state/config'
        files="$files"' .'"$gRegistryDir"'/state/config'
      fi
      ***REMOVED*** There is no double quote around $files on purpose
      if [ "`vmware_product`" = 'tools-for-solaris' ]; then
         ***REMOVED*** Solaris' tar(1) does not support gnu tar's -C and -z options.
         origDir=`pwd`
         cd "$tmpdir" && tar -copf - $files | gzip > "$output"
         cd $origDir
      else
         tar -C "$tmpdir" -czopf "$output" $files 2> /dev/null
      fi
      rm -rf "$tmpdir"

      exit 0
      ;;

    tar2|rpm2)
      echo 'Converting the tar4 installer database format'
      echo '        to the '"$format"' installer database format.'
      echo
      ***REMOVED*** The next installer uses the same database format. Backup a full
      ***REMOVED*** database state that it can use as a fresh new database.
      ***REMOVED***
      ***REMOVED*** Everything should go in:
      ***REMOVED***  /etc/vmware/
      ***REMOVED***              state/
      ***REMOVED***
      ***REMOVED*** But those directories do not have to be referenced,
      ***REMOVED*** the next installer will do it just after restoring the backup
      ***REMOVED*** because only it knows if those directories have been created.
      ***REMOVED***
      ***REMOVED*** Also, do not include those directories in the backup, because some
      ***REMOVED*** versions of tar (1.13.17+ are ok) do not untar directory permissions
      ***REMOVED*** as described in their documentation.
      make_tmp_dir 'tmpdir' 'vmware-installer'
      mkdir -p "$tmpdir""$gRegistryDir"
      db_add_file "$tmpdir""$gInstallerMainDB" "$gInstallerMainDB" ''
      db_load 'db' "$gInstallerMainDB"
      write() {
        local id="$1"
        local value="$2"
        local dbfile="$3"

        ***REMOVED*** For the rpm3|tar3 format, a number of keywords were removed.  In their 
        ***REMOVED*** place a more flexible scheme was implemented for which each has a semantic
        ***REMOVED*** equivalent:
	***REMOVED***
        ***REMOVED***   VNET_HOSTONLY          -> VNET_1_HOSTONLY
        ***REMOVED***   VNET_HOSTONLY_HOSTADDR -> VNET_1_HOSTONLY_HOSTADDR
        ***REMOVED***   VNET_HOSTONLY_NETMASK  -> VNET_1_HOSTONLY_NETMASK
        ***REMOVED***   VNET_INTERFACE         -> VNET_0_INTERFACE
        ***REMOVED***
        ***REMOVED*** Note that we no longer use the samba variables, so these entries are
        ***REMOVED*** not converted.  These were removed on the upgrade case, so it is not
        ***REMOVED*** necessary to remove them here.
        ***REMOVED***   VNET_SAMBA             -> VNET_1_SAMBA
        ***REMOVED***   VNET_SAMBA_MACHINESID  -> VNET_1_SAMBA_MACHINESID
        ***REMOVED***   VNET_SAMBA_SMBPASSWD   -> VNET_1_SAMBA_SMBPASSWD
	***REMOVED*** 
        ***REMOVED*** Also note that we perform the conversions needed above (rpm3|tar3
        ***REMOVED*** case) since we are downgrading two versions.
	***REMOVED*** 
	***REMOVED*** We undo the changes from rpm2|tar2 to rpm3|tar3 and rpm4|tar4.
        if [ "$id" = 'VNET_1_HOSTONLY' ]; then
          id='VNET_HOSTONLY'
        elif [ "$id" = 'VNET_1_HOSTONLY_HOSTADDR' ]; then
          id='VNET_HOSTONLY_HOSTADDR'
        elif [ "$id" = 'VNET_1_HOSTONLY_NETMASK' ]; then
          id='VNET_HOSTONLY_NETMASK'
        elif [ "$id" = 'VNET_0_INTERFACE' ]; then
          id='VNET_INTERFACE'
        elif echo $id | grep 'VNET_[[:digit:]]\+_DHCP' &>/dev/null; then
           return;
        elif echo $id | grep 'VNET_[[:digit:]]\+_HOSTONLY_SUBNET' &>/dev/null; then
           return;
        fi

        echo 'answer '"$id"' '"$value" >> "$dbfile"
      }
      db_iterate 'db' 'write' "$tmpdir""$gInstallerMainDB"
      files='.'"$gInstallerMainDB"
      if [ -e "$gRegistryDir"/config ]; then
        mkdir -p "$tmpdir""$gRegistryDir"'/state'
        cp "$gRegistryDir"/config "$tmpdir""$gRegistryDir"'/state/config'
        db_add_file "$tmpdir""$gInstallerMainDB" "$gRegistryDir"'/state/config' "$tmpdir""$gRegistryDir"'/state/config'
        files="$files"' .'"$gRegistryDir"'/state/config'
      fi
      ***REMOVED*** There is no double quote around $files on purpose
      tar -C "$tmpdir" -czopf "$output" $files 2> /dev/null
      rm -rf "$tmpdir"

      exit 0
      ;;

    tar|rpm)
      echo 'Converting the tar4 installer database format'
      echo '        to the '"$format"'  installer database format.'
      echo
      ***REMOVED*** Backup only the main database file. The next installer ignores
      ***REMOVED*** new keywords as well as file and directory statements, and deals
      ***REMOVED*** properly with remove_ statements
      tar -C '/' -czopf "$output" '.'"$gInstallerMainDB" 2> /dev/null

      exit 0
      ;;

    *)
      echo 'Unknown '"$format"' installer database format.'
      echo

      exit 1
      ;;
  esac
}

***REMOVED*** Uninstall what has been installed by the installer.
***REMOVED*** This should never prompt the user, because it can be annoying if invoked
***REMOVED*** from the rpm installer for example.
installer_uninstall() {

  db_load 'db' "$gRegistryDir"'/locations'

  if [ "$db_answer_BINDIR" = '' ]; then
    echo 'Error: Unable to find the binary installation directory (answer BINDIR)'
    echo '       in the installer database file "'"$gRegistryDir"'/locations".'
    echo

    exit 1
  fi

  ***REMOVED*** Remove the package
  if [ ! -x "$db_answer_BINDIR"'/'"$gUninstaller" ]; then
    echo 'Error: Unable to execute "'"$db_answer_BINDIR"'/'"$gUninstaller"'.'
    echo

    exit 1
  fi
  "$db_answer_BINDIR"/"$gUninstaller" "$@" || exit 1

  exit 0
}

***REMOVED***
***REMOVED*** Interface of the methods
***REMOVED***

initialize_globals

case "$1" in
  kind)
    installer_kind
    ;;

  version)
    installer_version
    ;;

  convertdb)
    installer_convertdb "$2" "$3"
    ;;

  uninstall)
    installer_uninstall "$@"
    ;;

  *)
    echo 'Usage: '"`basename "$0"`"' {kind|version|convertdb|uninstall}'
    echo

    exit 1
    ;;
esac

