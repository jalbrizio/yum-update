***REMOVED***!/bin/sh
***REMOVED*** Copyright 1998-2008 VMware, Inc.  All rights reserved.
***REMOVED***
***REMOVED*** Configures file paths in GTK+ library.
***REMOVED***

set -e

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

***REMOVED*** function that does what readlink -f does, but portable:
readlinkf() {
  file=$1

  cd $(dirname $file)
  file=$(basename $file)

  ***REMOVED*** Iterate down a (possible) chain of symlinks
  while [ -L "$file" ] ; do
    file=$(readlink $file)
    cd $(dirname $file)
    file=$(basename $file)
  done

  realdir=$(pwd -P)
  echo $realdir/$file
}

vmware_db='/etc/vmware-tools/locations'
db_load 'vm_db' "$vmware_db"

confs="$vm_db_answer_LIBDIR/libconf"
pangorc="$confs/etc/pango/pangorc"
pangoModules="$confs/etc/pango/pango.modules"
pangoxAliases="$confs/etc/pango/pangox.aliases"
gdkPixbufLoaders="$confs/etc/gtk-2.0/gdk-pixbuf.loaders"
gtkIMModules="$confs/etc/gtk-2.0/gtk.immodules"
template="@@LIBCONF_DIR@@"

TDIR=/tmp
if [ -n "$TMPDIR" -a -d "$TMPDIR" ]; then
   TDIR=$TMPDIR
fi
tmp_dir=$(mktemp -d $TDIR/tmp_sed.XXXXXX)

for i in pangorc pangoModules pangoxAliases gdkPixbufLoaders gtkIMModules; do
  eval "path=\$$i"
  tmp_file="$tmp_dir/$(basename $path)"
  sed -e "s,$template,$confs,g" < "$path" > "$tmp_file"
  cp "$tmp_file" "$path"; rm "$tmp_file"
  realpath=$(readlinkf $path)
  db_remove_file "$vmware_db" "$realpath"
  db_add_file "$vmware_db" "$realpath" "$realpath"
done

rm -rf $tmp_dir
exit 0
