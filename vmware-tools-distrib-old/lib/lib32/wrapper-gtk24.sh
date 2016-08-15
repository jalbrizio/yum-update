***REMOVED***!/bin/sh
libs="$1"
shift
binary="$1"
shift
confs="$1"
shift

***REMOVED*** Need to test this for unresolved symbols too
libvmwareui="$libs/libvmwareui.so.0/libvmwareui.so.0"

***REMOVED*** For the sake of simplicity, we only check the first arg for the gdb/valgrind
***REMOVED*** flag.
valgrind=0
debugger=0
if [ "$1" = '--valgrind' ] ; then
   ***REMOVED*** Pop --valgrind.
   shift
   valgrind=1
elif [ "$1" = '-G' ] ; then
   ***REMOVED*** Pop -G.
   shift
   debugger=1
fi

libpath=

***REMOVED*** Take a full path to a lib directory containing a lib of the same name
***REMOVED*** and return the adjusted name.
vm_translate_lib_name() {
   local libroot=`echo $1 | sed -e 's/\.so.*/\.so/'`
   local new_name=`ls -d $libroot* 2>/dev/null`
   if [ "$new_name" = "" ]; then
      new_name=$1
   fi
   echo "`basename $new_name`"
}

***REMOVED*** Apppend a directory to LD_LIBRARY_PATH
vm_append_lib() {
   local lib="$1" ***REMOVED*** IN: The library to append
   local path="$libs"'/'"$lib"

   ***REMOVED*** translate given lib to the same name in the
   ***REMOVED*** package that may be a different version
   if [ "$VMWARE_USE_SHIPPED_GTK" = 'force' ]; then
      local mlib=`vm_translate_lib_name $path`
      path="$libs"'/'"$mlib"
      ***REMOVED*** Don't add missing libs
      if [ ! -d $path ]; then
         return
      fi
   fi

   if [ "$VMWARE_USE_SHIPPED_GTK" = 'force' ]; then
      path="$path"'/'"$mlib"
   fi

   if [ "$libpath" = '' ]; then
      libpath="$path"
   else
      libpath="$libpath":"$path"
   fi
}

vm_append_cplusplus() {
   vm_append_lib 'libstdc++.so.6'
   vm_append_lib 'libgcc_s.so.1'
   vm_append_lib 'libsigc-2.0.so.0'
   vm_append_lib 'libgiomm-2.4.so.1'
   vm_append_lib 'libglibmm-2.4.so.1'
   vm_append_lib 'libglibmm_generate_extra_defs-2.4.so.1'
   vm_append_lib 'libatkmm-1.6.so.1'
   vm_append_lib 'libpangomm-1.4.so.1'
   vm_append_lib 'libgdkmm-2.4.so.1'
   vm_append_lib 'libgtkmm-2.4.so.1'
   vm_append_lib 'libcairomm-1.0.so.1'
   vm_append_lib 'libgnomecanvasmm-2.6.so.1'
   vm_append_lib 'libview.so.2'
   vm_append_lib 'libsexymm.so.2'
}

***REMOVED*** Append the GTK+ libraries to LD_LIBRARY_PATH
vm_fix_gtk() {
   ***REMOVED*** GLib
   vm_append_lib 'libgio-2.0.so.0'
   vm_append_lib 'libglib-2.0.so.0'
   vm_append_lib 'libiconv.so.0'
   vm_append_lib 'libintl.so.0'
   vm_append_lib 'libgmodule-2.0.so.0'
   vm_append_lib 'libgobject-2.0.so.0'
   vm_append_lib 'libgthread-2.0.so.0'

   ***REMOVED*** ATK
   vm_append_lib 'libatk-1.0.so.0'
   vm_append_lib 'libgailutil.so.18'
   vm_append_lib 'libspi.so.0'

   ***REMOVED*** Pango
   vm_append_lib 'libpango-1.0.so.0'
   vm_append_lib 'libpangoft2-1.0.so.0'
   vm_append_lib 'libpangoxft-1.0.so.0'
   vm_append_lib 'libpangox-1.0.so.0'
   vm_append_lib 'libpangocairo-1.0.so.0'

   ***REMOVED*** GTK+
   vm_append_lib 'libgdk-x11-2.0.so.0'
   vm_append_lib 'libgdk_pixbuf-2.0.so.0'
   vm_append_lib 'libgtk-x11-2.0.so.0'

   ***REMOVED*** Cairo
   vm_append_lib 'libpixman-1.so.0'
   vm_append_lib 'libcairo.so.2'

   ***REMOVED*** librsvg
   vm_append_lib 'librsvg-2.so.2'

   ***REMOVED*** libsexy
   vm_append_lib 'libsexy.so.2'

   ***REMOVED*** GnomeCanvas
   ***REMOVED*** We use gnomecanvas 2.6. Apparently 2.4 is symbol compatible but not
   ***REMOVED*** compatible enough to avoid crashing at times, so consider gnomecanvas to
   ***REMOVED*** be part of the base Gtk set.
   vm_append_lib 'libgnomecanvas-2.so.0'

   ***REMOVED*** libglade
   ***REMOVED*** libglade has a similar potential for trouble as GnomeCanvas
   vm_append_lib 'libglade-2.0.so.0'

   ***REMOVED*** These are not a direct dependency of GTK+, but they keep breaking
   ***REMOVED*** binary compatibility in both directions, so use ours.
   vm_append_lib 'libfreetype.so.6'
   vm_append_lib 'libXinerama.so.1'
   vm_append_lib 'libXfixes.so.3'
   vm_append_lib 'libXcursor.so.1'
   vm_append_lib 'libXrandr.so.2'
   vm_append_lib 'libXrender.so.1'
   vm_append_lib 'libXft.so.2'
   vm_append_lib 'libXcomposite.so.1'
   vm_append_lib 'libXdamage.so.1'

   ***REMOVED*** Needed for XScreenSaverSuspend; appeared in libXScrnSaver 1.1.0.
   vm_append_lib 'libXss.so.1'

   ***REMOVED*** We have observed cases of incompatibility between system gtk and our
   ***REMOVED*** libpng and system libpng and our gtk. So they should be considered
   ***REMOVED*** part of the same set.
   vm_append_lib 'libpng12.so.0'

   ***REMOVED*** This is technically not needed here but it makes things simpler than
   ***REMOVED*** having to handle 'force' separately for libxml2.
   vm_append_lib 'libxml2.so.2'
   vm_append_lib 'libz.so.1'

   ***REMOVED*** C++ libs better match the base gtk ones in this case...
   vm_append_cplusplus

   ***REMOVED*** We ship libatk-bridge.so which links against libbonobo, so we need
   ***REMOVED*** to ship libbonobo as well.
   vm_append_lib 'libbonobo-2.so.0'
   vm_append_lib 'libbonobo-activation.so.4'

   echo "$libpath"
}

***REMOVED*** Libraries we should unconditionally append
vm_append_always() {
   vm_append_lib 'libcurl.so.4'
   echo "$libpath"
}

***REMOVED*** Append the C++ libraries to LD_LIBRARY_PATH
vm_fix_cplusplus() {
   vm_append_cplusplus
   echo "$libpath"
}

vm_fix_libxml2() {
   vm_append_lib 'libxml2.so.2'
   vm_append_lib 'libz.so.1'
   echo "$libpath"
}

vm_fix_libview() {
   vm_append_lib 'libview.so.2'
   echo "$libpath"
}


***REMOVED*** Append the remaining, usually safe, libraries
***REMOVED*** This is used in the 'force' case to ensure all our libs are used
vm_force_other_libs() {
   ***REMOVED*** Expat
   vm_append_lib 'libexpat.so.0'

   ***REMOVED*** libart
   vm_append_lib 'libart_lgpl_2.so.2'

   echo "$libpath"
}

***REMOVED*** Parse ldd's output and append all missing libraries to LD_LIBRARY_PATH
vm_append_missing() {
   local lib
   local dummy
   local status

   while read -r lib dummy status; do
      if [ -n "`echo "$status" | sed -ne '/not found/p'`" ]; then
         vm_append_lib "$lib"
      fi
   done

   echo "$libpath"
}

vm_append_to_library_path() {
   local ldBasePath
   if [ ! -z "$LD_LIBRARY_PATH" ]; then
      ldBasePath="$LD_LIBRARY_PATH:"
   fi
   export LD_LIBRARY_PATH="$ldBasePath""$1"
}

***REMOVED*** Extract the library list from an ldd output
vm_make_lib_list() {
   local lib

   while read -r lib dummy; do
      echo "$lib"
   done
}

***REMOVED*** Run "$binary" with the correct environment.
vm_run() {
   local prevLibList
   local curLibList
   local lddOutput
   local sanityCounter

   vm_append_to_library_path "`vm_append_always`"

   ***REMOVED***
   ***REMOVED*** Repeatedly run ldd and attempt to append missing libs. This will end when
   ***REMOVED*** the list of libraries reported by ldd stops changing. This iteration
   ***REMOVED*** ensures that we notice and attempt to satisfy any indirect dependencies.
   ***REMOVED***
   sanityCounter=20
   while true; do
      ***REMOVED*** If the sanity counter has run out, give up and break.
      sanityCounter=$(($sanityCounter - 1))
      if [ "$sanityCounter" = '0' ]; then
         echo 'Warning: Unable to fully resolve dependencies.'
         break
      fi

      ***REMOVED*** Refresh the ldd output for comparison.
      lddOutput="`LANGUAGE=C LANG=C ldd "$binary"`"

      prevLibList="$curLibList"
      curLibList="`echo "$lddOutput" | vm_make_lib_list`"

      ***REMOVED*** We're no longer changing the ldd output. Our work is done.
      if [ "$curLibList" = "$prevLibList" ]; then
         break
      fi

      ***REMOVED*** Append any libraries that are still missing.
      if [ "$VMWARE_USE_SHIPPED_GTK" = 'force' ]; then
         export preload="$preload":"`echo "$lddOutput" | vm_append_missing`"
      else
         vm_append_to_library_path "`echo "$lddOutput" | vm_append_missing`"
      fi
   done

   ***REMOVED*** Refresh ldd output with '-r' to check for missing symbols.
   lddOutput="`LANGUAGE=C LANG=C ldd -r "$binary" 2>&1 > /dev/null`"

   ***REMOVED***
   ***REMOVED*** For some libs, we require specific library versions, which we either detect
   ***REMOVED*** by missing symbols or missing version tags.
   ***REMOVED***
   if [ "$VMWARE_USE_SHIPPED_GTK" = '' ]; then
      if echo "$lddOutput" | grep -q 'xmlReadFile'; then
         ***REMOVED*** No sufficiently new libxml2 on the system
         vm_append_to_library_path "`vm_fix_libxml2`"
      fi
   fi

   if [ "$VMWARE_USE_SHIPPED_GTK" = '' ]; then
      ***REMOVED*** ldd output with '-r' to check for missing symbols against libvmwareui
      lddUiLibOutput="`LANGUAGE=C LANG=C ldd -r "$libvmwareui" 2>&1 > /dev/null`"
      if echo "$lddUiLibOutput" | grep -q 'ViewOvBox_SetVerticalOffset'; then
         ***REMOVED*** No sufficiently new libview on the system
         vm_append_to_library_path "`vm_fix_libview`"
      fi
   fi

   if [ "$VMWARE_USE_SHIPPED_GTK" = '' ]; then
      if echo "$lddOutput" | grep -q 'CXXABI_1.3.1'; then
         ***REMOVED*** No sufficiently new C++ runtime environment on the system.
         vm_append_to_library_path "`vm_fix_cplusplus`"
      fi
   fi

   ***REMOVED*** Use LD_LIBRARY_PATH instead of preload to avoid affecting the loader.
   if [ "$VMWARE_USE_SHIPPED_GTK" = "force" ]; then
      LD_LIBRARY_PATH="`echo $preload":" | sed -e 's/\/lib[^\/]*:/:/g'`"':'"$LD_LIBRARY_PATH"
      export LD_LIBRARY_PATH
   fi

   if [ $valgrind = 1 ] ; then
      valgrind --log-file=/tmp/valgrind-ui.log --leak-check=yes \
               --show-reachable=no --partial-loads-ok=yes \
               --num-callers=32 "$binary" "$@"
   elif [ $debugger = 1 ] ; then
      gdb $VMUI_DEBUG_FLAGS --args "$binary" "$@"
   else
      exec "$binary" "$@"
   fi

   return "$?"
}

***REMOVED***
***REMOVED*** This function tests if an environment variable is actually set or not.
***REMOVED*** As we had to dig quite a bit to work out what to do, we've put it in
***REMOVED*** a separate function.
***REMOVED***
vm_is_var_set() {
   local var="$1"

   eval '[ "${'"$var"'+yes}" = 'yes' ]'
}

***REMOVED***
***REMOVED*** We must save all environment variables that we manipulate because we will
***REMOVED*** be fork/exec'ing help/web browsers. We must also explicitly indicate which
***REMOVED*** vars were originally unset. There is a third state where we don't try and
***REMOVED*** save a var at all and this is indicated by not setting VMWARE_<foo> at all.
***REMOVED***
vm_save_var() {
   local var="$1"

   if vm_is_var_set 'VMWARE_'"$var" && [ "$VMWARE_DEBUG" = "yes" ] ; then
      echo 'VMWARE_'"$var"' is already set, but it will be overridden.'
   fi

   if vm_is_var_set "$var"; then
      eval 'export VMWARE_'"$var"'="1$'"$var"'"'
   else
      eval 'export VMWARE_'"$var"'="0"'
   fi
}

***REMOVED***
***REMOVED*** Function to strip qtengine out of the set of GTK2_RC_FILES. SuSE evilness
***REMOVED*** necessitates this. It has to be a function because we wipe the 'command line'
***REMOVED*** argument space when we do the stripping.
***REMOVED***
vm_strip_out_qt_engine() {
   local gtk2_rc_files="$1"
   local tmp_rc_files=""

   ***REMOVED***
   ***REMOVED*** gtk-qt-engine is evil and SuSE use an evil mechanism to force it.
   ***REMOVED*** So, we have to strip it out like this:
   ***REMOVED***
   set -- `IFS=':'; echo $gtk2_rc_files`
   while [ "$***REMOVED***" -gt 0 ]; do
      case "$1" in
         *'qtengine'*)
         ;;
         *'/Qt/'*)
         ;;
         *)
         tmp_rc_files="$tmp_rc_files""$1"':'
         ;;
      esac
      shift
   done
   echo "$tmp_rc_files"
}

***REMOVED***
***REMOVED*** This list must be kept in sync with the corresponding UI code that restores
***REMOVED*** these variables.
***REMOVED***
vm_save_var 'LD_LIBRARY_PATH'
vm_save_var 'LD_PRELOAD'
vm_save_var 'PANGO_RC_FILE'
vm_save_var 'GDK_PIXBUF_MODULE_FILE'
vm_save_var 'GTK_IM_MODULE_FILE'
vm_save_var 'FONTCONFIG_PATH'
vm_save_var 'GTK2_RC_FILES'
vm_save_var 'GTK_EXE_PREFIX'
vm_save_var 'GTK_PATH'
vm_save_var 'GTK_PATH64'

***REMOVED***
***REMOVED*** When environment variable VMWARE_USE_SHIPPED_GTK is set to "force", we
***REMOVED*** forcefully use the GTK+ runtime environment (libraries + their
***REMOVED*** configuration files) that we ship.
***REMOVED***
***REMOVED*** When environment variable VMWARE_USE_SHIPPED_GTK is set to "yes", we
***REMOVED*** thoughtfully use the GTK+ runtime environment (libraries + their
***REMOVED*** configuration files) that we ship.  This works for all but the most broken
***REMOVED*** environments, so if we're guessing we try this.
***REMOVED***
***REMOVED*** When environment variable VMWARE_USE_SHIPPED_GTK is set to "no", we use
***REMOVED*** the system's GTK+ runtime environment.
***REMOVED***
***REMOVED*** When environment variable VMWARE_USE_SHIPPED_GTK is not set (the default), we
***REMOVED*** try to make an educated guess.
***REMOVED***

if [ "$VMWARE_USE_SHIPPED_GTK" = '' ]; then
   ***REMOVED*** We're checking a symbol in gtkmm instead of gtk here so that we can
   ***REMOVED*** guarantee the version of gtkmm is new enough. And, if the gtkmm is new
   ***REMOVED*** enough, we know that the gtk will be new enough as well, as you cannot
   ***REMOVED*** use a version of gtkmm that's newer than gtk.
   GTKMM_SYMBOL='_ZN3Gtk7Spinner5startEv'

   if LANGUAGE=C LANG=C ldd -r "$binary" 2>&1 >/dev/null \
         | grep -q $GTKMM_SYMBOL; then
      ***REMOVED*** No sufficiently new GTK+ runtime environment on the system.
      export VMWARE_USE_SHIPPED_GTK=yes
   fi
fi

if [ "$VMWARE_USE_SHIPPED_GTK" = 'yes' -o "$VMWARE_USE_SHIPPED_GTK" = 'force' ]; then
   ***REMOVED***
   ***REMOVED*** Libraries
   ***REMOVED***

   if [ "$VMWARE_USE_SHIPPED_GTK" = 'yes' ]; then
      export LD_LIBRARY_PATH="`vm_fix_gtk`"
   else
      export preload="`vm_fix_gtk`":"`vm_force_other_libs`"
   fi

   ***REMOVED***
   ***REMOVED*** Library configuration files
   ***REMOVED***

   if [ -z "$PANGO_RC_FILE" -o "$VMWARE_USE_SHIPPED_GTK" = 'force' ]; then
      export PANGO_RC_FILE="$confs"'/etc/pango/pangorc'
   fi

   if [ -z "$GDK_PIXBUF_MODULE_FILE" -o "$VMWARE_USE_SHIPPED_GTK" = 'force' ]; then
      export GDK_PIXBUF_MODULE_FILE="$confs"'/etc/gtk-2.0/gdk-pixbuf.loaders'
   fi

   if [ -z "$GTK_IM_MODULE_FILE" -o "$VMWARE_USE_SHIPPED_GTK" = 'force' ]; then
      export GTK_IM_MODULE_FILE="$confs"'/etc/gtk-2.0/gtk.immodules'
   fi

   ***REMOVED*** We always want to append our gtkrc, unless we're forcing it
   if [ "$VMWARE_USE_SHIPPED_GTK" = 'force' ]; then
      export GTK2_RC_FILES="$confs"'/etc/gtk-2.0/gtkrc'
   else
      if [ -z "$GTK2_RC_FILES" ]; then
         GTK2_RC_FILES='/etc/gtk-2.0/gtkrc:'"$HOME"'/.gtkrc-2.0:'
      else
         GTK2_RC_FILES="`vm_strip_out_qt_engine $GTK2_RC_FILES`"
      fi
      export GTK2_RC_FILES="$GTK2_RC_FILES""$confs"'/etc/gtk-2.0/gtkrc'
   fi

   ***REMOVED*** We will try as hard as possible to use the system fonts.conf
   if [ \( ! -e "/etc/fonts/fonts.conf" -a -z "$FONTCONFIG_PATH" \) \
        -o "$VMWARE_USE_SHIPPED_GTK" = 'force' ]; then
      export FONTCONFIG_PATH="$confs"'/etc/fonts'
      vm_append_lib 'libfontconfig.so.1'
   fi

   if [ -d "$confs/gtk-2.0" ]; then
      GTK_PATH_PREFIX="$confs"
   else
      if [ -d "$confs/lib/gtk-2.0" ]; then
         GTK_PATH_PREFIX="$confs/lib"
      fi
   fi
   ***REMOVED*** There are systems that don't pay attention to GTK_PATH and appear to
   ***REMOVED*** depend on LD_LIBRARY_PATH for modules searching. So add that path to
   ***REMOVED*** LD_LIBRARY_PATH.
   vm_append_to_library_path "$GTK_PATH_PREFIX"
   vm_append_to_library_path "$GTK_PATH_PREFIX/gtk-2.0/modules"
   ***REMOVED*** Always append our libdir to GTK_PATH
   vm_gtk_path="$GTK_PATH_PREFIX/gtk-2.0/modules"

   ***REMOVED*** SuSE(except 10.1) & RedHat use lib64 for 64bit and lib == lib32 while
   ***REMOVED*** Ubuntu/Debian & we use lib == lib64 and lib32 is explicit.
   ***REMOVED*** So to determine if we should use GTK_PATH64, we need to detect
   ***REMOVED*** the lib==lib32 case and also to cover Sles 10.1 64-bit like
   ***REMOVED*** cases we need to detect if /usr/lib64 exists

   if [ -z "$GTK_PATH" -o "$VMWARE_USE_SHIPPED_GTK" = 'force' ]; then
      export GTK_PATH="$vm_gtk_path"
      export GTK_EXE_PREFIX="$confs"
      if [ -L "/usr/lib32" -o -e "/usr/lib64" ]; then
         ***REMOVED*** Take the contents of GTK_PATH and set it to GTK_PATH64
         ***REMOVED*** and then clear GTK_PATH.
         export GTK_PATH64="$GTK_PATH"
         unset GTK_PATH
      fi
   else
      ***REMOVED*** Incorporate the contents of the system-appropriate 64-bit GTK path into
      ***REMOVED*** the path we use.
      if [ -L "/usr/lib32" -o -e "/usr/lib64" ]; then
         export GTK_PATH="$GTK_PATH64"
      fi
      export GTK_PATH="$GTK_PATH"':'"$vm_gtk_path"
   fi

fi

vm_run "$@"
