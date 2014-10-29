***REMOVED***!/usr/bin/perl -w
***REMOVED*** If your copy of perl is not in /usr/bin, please adjust the line above.
***REMOVED***
***REMOVED*** Copyright 1998-2013 VMware, Inc.  All rights reserved.
***REMOVED***
***REMOVED*** Host configurator for VMware

use strict;

***REMOVED*** Use Config module to update VMware host-wide configuration file
***REMOVED*** BEGINNING_OF_CONFIG_DOT_PM
***REMOVED***!/usr/bin/perl

***REMOVED******REMOVED******REMOVED***
***REMOVED******REMOVED******REMOVED*** TODOs:
***REMOVED******REMOVED******REMOVED***  config file hierarchies
***REMOVED******REMOVED******REMOVED***  open/close/check file
***REMOVED******REMOVED******REMOVED***  error handling
***REMOVED******REMOVED******REMOVED***  config file checker
***REMOVED******REMOVED******REMOVED***  pretty print should print not present devices not in misc
***REMOVED******REMOVED******REMOVED***

use strict;
package VMware::Config;

my %PREF;

***REMOVED***$PREF{'commentChanges'} = 1;

sub new() {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = $proto->create();
  bless($self, $class);
  return($self);
}

sub create {
  my $self = {};
  $self->{db} = {};
  $self->{tr} = 1;
  return($self);  
}

sub preserve_case($) {
  my $self = shift;
  my $preserve = shift;
  $self->{tr} = !$preserve;
}

sub clear() {
  my $self = {};
  $self->{db} = {};
}

sub readin($) {
  my $self = shift;
  my ($file) = @_;

  my $text = "";
  
  my @stat = stat($file);
  $self->{timestamp} = $stat[9];

  open(CFG, "< $file") || return undef;
  
  while (<CFG>) {
    $text = $text . $_;
  }
  
  close(CFG);

  my $ret = $self->parse($text);
  if (!defined($ret)) {
    return undef;
  }

  $self->{file} = $file;
  $self->{text} = $text;

  return 1;
}

sub writeout($) {
  my $self = shift;
  my ($file) = @_;

  if (!defined($file)) {
    $file = $self->{file};
  }

  open(CFG, "> $file") || return undef;
  print CFG $self->update($self->{text});
  close(CFG);

  return 1;
}

sub overwrite($$) {
  my $self = shift;
  my($orig, $file) = @_;
  
  if (!defined($file)) {
    $file = $orig->{file};
  }
  
  open(CFG, "> $file") || return undef;
  print CFG $self->update($orig->{text});
  close(CFG);

  return 1;  
}

sub pretty_overwrite {
  my $self = shift;
  my($file) = @_;
  
  if (!defined($file)) {
    $file = $self->{file};
  }
  
  open(CFG, "> $file") || return undef;
  print CFG $self->pretty_print();
  close(CFG);

  return 1;  
}

sub parse($) {
  my $self = shift;
  my ($text) = @_;
  my(@lines, $line, $num);
  
  @lines = split(/\n/, $text);
  $num = 1;
  
  foreach $line (@lines) {
    my($status, $name, $value, $start, $end) = $self->parse_line($line);
    if (!defined($status)) {
      $self->clear();
      ***REMOVED*** syntax error on line $num
      return undef;
    } elsif ($status == 1) {
      if ($self->{tr}) {
        $name =~ tr/A-Z/a-z/;
      }
      $self->{db}{$name}{value} = $value;
      $self->{db}{$name}{modified} = 0;
      $self->{db}{$name}{mark} = 0;
    } elsif ($status == 0) {
      ***REMOVED*** noop
    } else {
      $self->clear();
      ***REMOVED*** internal error
      return undef;
    }
    $num++;
  }
  
  return 1;
}

sub timestamp() {
  my $self = shift;
  return $self->{timestamp};
}

sub get() {
  my $self = shift;
  my($name, $default) = @_;
  if ($self->{tr}) {
    $name =~ tr/A-Z/a-z/;
  }
  if (defined($self->{db}{$name})) {
    $self->{db}{$name}{mark} = 1;
    return $self->{db}{$name}{value};
  } else {
    return $default;
  }
}
        
sub get_bool() {
  my $self = shift;
  my($name, $default) = @_;
  my $val = $self->get($name);
  if (!defined($val)) {
    $val = $default;
  }
  if ($val =~ /TRUE|1|Y|YES/i) {
    $val = 1;
  } else {
    $val = 0;
  }
  return $val;
}
        
sub set($$) {
  my $self = shift;
  my($name, $value) = @_;
  if ($self->{tr}) {
    $name =~ tr/A-Z/a-z/;
  }
  $self->{db}{$name}{value} = $value;
  $self->{db}{$name}{modified} = 1;
  $self->{db}{$name}{mark} = 0;
}

sub remove($) {
  my $self = shift;
  my($name) = @_;
  if ($self->{tr}) {
    $name =~ tr/A-Z/a-z/;
  }
  delete $self->{db}{$name};
}

sub list($) {
  my $self = shift;
  my($pattern) = @_;
  return sort(grep(/$pattern/, keys(%{$self->{db}})));
}

sub device_list {
  my $self = shift;
  my($name, $pattern, $show_all) = @_;
  my($dev, $val, %present);

  $show_all = 0 if (!defined($show_all));

  foreach $_ (keys(%{$self->{db}})) {
    if (/$name($pattern)\.present/) {
      $dev = $name . $1;
      $val = $self->get_bool("$dev.present");
      if ($show_all || !defined($val) || ($val)) {
        $present{$dev} = 1;
      }
    }
  }

  return sort(keys(%present));
}

sub update($) {
  my $self = shift;
  my ($text) = @_;
  my $out = "";
  my($line, $name);
  
  my @lines;
  if (defined($text)) {
    @lines = split(/\n/, $text);
  }
  my $num = 1;

  $self->unmark_all();
  
  foreach $line (@lines) {
    my($status, $name, $value, $start, $end) = $self->parse_line($line);

    if (defined($name)) {
      if ($self->{tr}) {
        $name =~ tr/A-Z/a-z/;
      }
    }

    ***REMOVED******REMOVED******REMOVED***
    ***REMOVED******REMOVED******REMOVED*** five cases
    ***REMOVED******REMOVED******REMOVED***
    ***REMOVED******REMOVED******REMOVED***   1. deleted
    ***REMOVED******REMOVED******REMOVED***   2. modified
    ***REMOVED******REMOVED******REMOVED***   3. unmodified
    ***REMOVED******REMOVED******REMOVED***   4. comment or blank line
    ***REMOVED******REMOVED******REMOVED***   5. new (handled at the end)
    ***REMOVED******REMOVED******REMOVED***

    $line = $line . "\n";

    if (!defined($status)) {
      ***REMOVED*** XXX syntax error on line $num
      return undef;
      
    } elsif ($status == 1) {
      if (!defined($self->{db}{$name})) {
        ***REMOVED******REMOVED******REMOVED***
        ***REMOVED******REMOVED******REMOVED*** Case 1. removed
        ***REMOVED******REMOVED******REMOVED***
        
        if (defined($PREF{'commentChanges'})) {
          $line = "***REMOVED*** " . $line;
        } else {
          $line = "";
        }
        
      } else {
        $self->mark($name);

        if ($self->{db}{$name}{value} ne $value) {  
          ***REMOVED******REMOVED******REMOVED***
          ***REMOVED******REMOVED******REMOVED*** Case 2. modified
          ***REMOVED******REMOVED******REMOVED***
          
          my $newline = substr($line, 0, $start) 
            . "\"" . $self->{db}{$name}{value} . "\"" . substr($line, $end);
          
          if (defined($PREF{'commentChanges'})) {
            $line = "***REMOVED*** " . $line . $newline;
          } else {
            $line = $newline;
          }
          
        } else {
          ***REMOVED******REMOVED******REMOVED***
          ***REMOVED******REMOVED******REMOVED*** Case 3. unmodified
          ***REMOVED******REMOVED******REMOVED***
        }
      }

    } elsif ($status == 0) {
      ***REMOVED******REMOVED******REMOVED***
      ***REMOVED******REMOVED******REMOVED*** Case 4. comment or blank line
      ***REMOVED******REMOVED******REMOVED***
      
    } else {
      ***REMOVED*** XXX internal error: parse_line returned unknown status \"$status\"
      return undef;
    }
    
    $out = $out . "$line";
    $num++;
  }

  ***REMOVED******REMOVED******REMOVED***
  ***REMOVED******REMOVED******REMOVED*** Case 5. new entries
  ***REMOVED******REMOVED******REMOVED***

  $out = $out . $self->print_unmarked();

  return $out;
}

sub dump_all() {
  my $self = shift;
  my $out = "";
  my $name;
  
  foreach $name (keys(%{$self->{db}})) {
    $out = $out . "$name = \"$self->{db}{$name}{value}\"\n";
  }
  
  return $out;
}

sub pretty_print($) {
  my $self = shift;
  my($templ) = @_;
  my $out = "";
  my $sec;

  $self->unmark_all();
  
  foreach $sec (@{$templ}) {  
    $out = $out . $self->print_section($sec, "");
  }
  
  $out = $out . "***REMOVED******REMOVED******REMOVED***\n***REMOVED******REMOVED******REMOVED*** Misc.\n***REMOVED******REMOVED******REMOVED***\n\n";
  $out = $out . $self->print_unmarked();

  return $out;
}

sub print_section {
  my $self = shift;
  my($sec, $prefix) = @_;
  my $out = "";

  my @list;
  my $dev;
  
  if (defined($sec->{header})) {
    $out = $out . "***REMOVED******REMOVED******REMOVED***\n***REMOVED******REMOVED******REMOVED*** $sec->{header}\n***REMOVED******REMOVED******REMOVED***\n\n";
  }
  
  ***REMOVED******REMOVED*** name is here for compatibility, it should go away soon.
  my $name = defined($sec->{name}) ? $sec->{name} : "";

  if (defined($sec->{pattern})) {
    @list = $self->device_list($prefix . $name, $sec->{pattern}, 1);
    foreach $dev (@list) {
      if (defined($sec->{title})) {
        $out = $out . sprintf("***REMOVED*** $sec->{title}\n\n", $dev);
      }
      $out = $out . $self->print_values("$dev", $sec->{values});
      if (defined($sec->{sublist})) {
        $out = $out . $self->print_section($sec->{sublist}, "$dev");
      }
    }
  } else {
    if (defined($sec->{values})) {
      $out = $out . $self->print_values($prefix . $name, $sec->{values});
    } else {
      $out = $out . $self->print_value($prefix . $name, "is not set");
      $out = $out . "\n";
    }
  }

  return $out;
}

sub print_values {
  my $self = shift;
  my($name, $vars) = @_;
  my $var;

  my $out = "";
  
   foreach $var (@{$vars}) {
     my $v = ($name ne "") ? "$name.$var" : $var;
     $out = $out . $self->print_value($v);
  }

  $out = $out . "\n";

  return $out;
}

sub print_value {
  my $self = shift;
  my($name, $notset) = @_;
  my $val = $self->get($name);
  if (defined($val)) {
    $self->mark($name);
    return "$name = \"$val\"\n";
  } elsif (defined($notset)) {
    return "***REMOVED*** $name $notset\n";
  }
}

sub mark($) {
  my $self = shift;
  my($name) = @_;
  if ($self->{tr}) {
    $name =~ tr/A-Z/a-z/;
  }
  $self->{db}{$name}{mark} = 1;
}

sub unmark_all() {
  my $self = shift;
  my $name;
  foreach $name (keys %{$self->{db}}) {
    $self->{db}{$name}{mark} = 0;
  }
}

sub get_unmarked() {
  my $self = shift;
  my $name;
  my @list = ();
  foreach $name (keys %{$self->{db}}) {
    if (!$self->{db}{$name}{mark}) {
      push(@list, $name);
    }
  }
  return @list;
}

sub print_unmarked() {
  my $self = shift;
  my @unmarked = $self->get_unmarked();
  my $out = "";
  my $name;
  
  foreach $name (@unmarked) {
    $out = $out . "$name = \"$self->{db}{$name}{value}\"\n";
  }

  return $out;
}

sub parse_line($) {
  my $self = shift;
  ($_) = @_;

  if (/^\s*(\***REMOVED***.*)?$/) {
    return (0);
  } elsif (/^((\s*(\S+)\s*=\s*)(([\"]([^\"]*)[\"])|(\S+)))\s*(\***REMOVED***.*)?$/) {
    my $prefix1 = $2;
    my $prefix2 = $1;
    my $name = $3;
    my $value;
    if (defined($6)) {
      $value = $6;
    } else {
      $value = $7;
    }

    return (1, $name, $value, length($prefix1), length($prefix2));
  } 

  return (undef);  
}



1;

***REMOVED*** END_OF_CONFIG_DOT_PM

***REMOVED*** BEGINNING_OF_UTIL_DOT_PL
***REMOVED***!/usr/bin/perl

use strict;
no warnings 'once'; ***REMOVED*** Warns about use of Config::Config in config.pl

***REMOVED*** A list of known open-vmware tools packages
***REMOVED***
my @cOpenVMToolsRPMPackages = ("vmware-kmp-debug",
			       "vmware-kmp-default",
			       "vmware-kmp-pae",
			       "vmware-kmp-trace",
			       "vmware-guest-kmp-debug",
			       "vmware-guest-kmp-default",
			       "vmware-guest-kmp-desktop",
			       "vmware-guest-kmp-pae",
			       "open-vm-tools-gui",
			       "open-vm-tools",
			       "libvmtools-devel",
			       "libvmtools0");

***REMOVED*** Moved out of config.pl to support $gOption in spacechk_answer
my %gOption;
***REMOVED*** Moved from various scripts that include util.pl
my %gHelper;

***REMOVED***
***REMOVED*** All the known modules that the config.pl script needs to
***REMOVED*** know about.  Modules in this list are searched for when
***REMOVED*** we check for non-vmware modules on the system.
***REMOVED***
my @cKernelModules = ('vmblock', 'vmhgfs', 'vmmemctl',
                      'vmxnet', 'vmci', 'vsock',
                      'vmsync', 'pvscsi', 'vmxnet3',
		      'vmwgfx');

***REMOVED***
***REMOVED*** This list simply defined what modules need to be included
***REMOVED*** in the system ramdisk when we rebuild it.
***REMOVED***
my %cRamdiskKernelModules = (vmxnet3 => 'yes',
			     pvscsi  => 'yes',
			     vmxnet  => 'yes');
***REMOVED***
***REMOVED*** This defines module dependencies.  It is a temporary solution
***REMOVED*** until we eventually move over to using the modules.xml file
***REMOVED*** to get our dependency information.
***REMOVED***
my %cKernelModuleDeps = (vsock => ('vmci'),
			 vmhgfs => ('vmci'));

***REMOVED***
***REMOVED*** Module PCI ID and alias definitions.
***REMOVED***
my %cKernelModuleAliases = (
   ***REMOVED*** PCI IDs first
   'pci:v000015ADd000007C0' => 'pvscsi',
   'pci:v000015ADd00000740' => 'vmci',
   'pci:v000015ADd000007B0' => 'vmxnet3',
   'pci:v000015ADd00000720' => 'vmxnet',
   ***REMOVED*** Arbitrary aliases next
   'vmware_vsock'    => 'vsock',
   'vmware_vmsync'   => 'vmsync',
   'vmware_vmmemctl' => 'vmmemctl',
   'vmware_vmhgfs'   => 'vmhgfs',
   'vmware_vmblock'  => 'vmblock',
   'vmware_balloon'  => 'vmmemctl',
   'vmw_pvscsi'      => 'pvscsi',
    );

***REMOVED***
***REMOVED*** Upstream module names and their corresponding internal module names.
***REMOVED***
my %cUpstrKernelModNames = (
   'vmw_balloon'    => 'vmmemctl',
   'vmw_pvscsi'     => 'pvscsi',
   'vmw_vmxnet3'    => 'vmxnet3',
   'vmware_balloon' => 'vmmemctl',
   'vmxnet3'        => 'vmxnet3',
    );

***REMOVED***
***REMOVED*** Table mapping vmware_product() strings to applicable services script or
***REMOVED*** Upstart job name.
***REMOVED***

my %cProductServiceTable = (
   'acevm'              => 'acevm',
   'nvdk'               => 'nvdk',
   'player'             => 'vmware',
   'tools-for-freebsd'  => 'vmware-tools.sh',
   'tools-for-linux'    => 'vmware-tools',
   'tools-for-solaris'  => 'vmware-tools',
   'vix-disklib'        => 'vmware-vix-disklib',
   'wgs'                => 'vmware',
   'ws'                 => 'vmware',
   '@@VCLI_PRODUCT@@'   => '@@VCLI_PRODUCT_PATH_NAME@@',
);

***REMOVED***
***REMOVED*** Hashes to track vmware modules.
***REMOVED***
my %gNonVmwareModules = ();
my %gVmwareInstalledModules = ();
my %gVmwareRunningModules = ();

my $cTerminalLineSize = 79;

***REMOVED*** Flags
my $cFlagTimestamp     =   0x1;
my $cFlagConfig        =   0x2;
my $cFlagDirectoryMark =   0x4;
my $cFlagUserModified  =   0x8;
my $cFlagFailureOK     =  0x10;

***REMOVED*** See vmware_service_issue_command
my $cServiceCommandDirect = 0;
my $cServiceCommandSystem = 1;

***REMOVED*** Strings for Block Appends.
my $cMarkerBegin = "***REMOVED*** Beginning of the block added by the VMware software - DO NOT EDIT\n";
my $cMarkerEnd = "***REMOVED*** End of the block added by the VMware software\n";
my $cDBAppendString = 'APPENDED_FILES';

***REMOVED*** Constants
my $gWebAccessWorkDir = '/var/log/vmware/webAccess/work';

***REMOVED*** util.pl Globals
my %gSystem;

***REMOVED*** Needed to access $Config{...}, the Perl system configuration information.
require Config;

***REMOVED*** Use the Perl system configuration information to make a good guess about
***REMOVED*** the bit-itude of our platform.  If we're running on Solaris we don't have
***REMOVED*** to guess and can just ask isainfo(1) how many bits userland is directly.
sub is64BitUserLand {
  if (vmware_product() eq 'tools-for-solaris') {
    if (direct_command(shell_string($gHelper{'isainfo'}) . ' -b') =~ /64/) {
      return 1;
    } else {
      return 0;
    }
  }
  if ($Config::Config{archname} =~ /^(x86_64|amd64)-/) {
    return 1;
  } else {
    return 0;
  }
}

***REMOVED*** Return whether or not this is a hosted desktop product.
sub isDesktopProduct {
   return vmware_product() eq "ws" || vmware_product() eq "player";
}

***REMOVED*** Return whether or not this is a hosted server product.
sub isServerProduct {
   return vmware_product() eq "wgs";
}

sub isToolsProduct {
   return vmware_product() =~ /tools-for-/;
}

***REMOVED***  Call to specify lib suffix, mainly for FreeBSD tools where multiple versions
***REMOVED***  of the tools are packaged up in 32bit and 64bit instances.  So rather than
***REMOVED***  simply lib or bin, there is lib32-6 or bin64-53, where -6 refers to FreeBSD
***REMOVED***  version 6.0 and 53 to FreeBSD 5.3.
sub getFreeBSDLibSuffix {
   return getFreeBSDSuffix();
}

***REMOVED***  Call to specify lib suffix, mainly for FreeBSD tools where multiple versions
***REMOVED***  of the tools are packaged up in 32bit and 64bit instances.  So rather than
***REMOVED***  simply lib or bin, there is lib32-6 or bin64-53, where -6 refers to FreeBSD
***REMOVED***  version 6.0 and 53 to FreeBSD 5.3.
sub getFreeBSDBinSuffix {
   return getFreeBSDSuffix();
}

***REMOVED***  Call to specify lib suffix, mainly for FreeBSD tools where multiple versions
***REMOVED***  of the tools are packaged up in 32bit and 64bit instances.  In the case of
***REMOVED***  sbin, a lib compatiblity between 5.0 and older systems appeared.  Rather
***REMOVED***  than sbin32, which exists normally for 5.0 and older systems, there needs
***REMOVED***  to be a specific sbin:  sbin32-5.  There is no 64bit set.
sub getFreeBSDSbinSuffix {
   my $suffix = '';
   my $release = `uname -r | cut -f1 -d-`;
   chomp($release);
   if (vmware_product() eq 'tools-for-freebsd' && $release == 5.0) {
      $suffix = '-5';
   } else {
      $suffix = getFreeBSDSuffix();
   }
   return $suffix;
}

sub getFreeBSDSuffix {
  my $suffix = '';

  ***REMOVED*** On FreeBSD, we ship different builds of binaries for different releases.
  ***REMOVED***
  ***REMOVED*** For FreeBSD 6.0 and higher (which shipped new versions of libc) we use the
  ***REMOVED*** binaries located in the -6 directories.
  ***REMOVED***
  ***REMOVED*** For releases between 5.3 and 6.0 (which were the first to ship with 64-bit
  ***REMOVED*** userland support) we use binaries from the -53 directories.
  ***REMOVED***
  ***REMOVED*** For FreeBSD 5.0, we use binaries from the sbin32-5 directory.
  ***REMOVED***
  ***REMOVED*** Otherwise, we just use the normal bin and sbin directories, which will
  ***REMOVED*** contain binaries predominantly built against 3.2.
  if (vmware_product() eq 'tools-for-freebsd') {
    my $release = `uname -r | cut -f1 -d-`;
    ***REMOVED*** Tools lowest supported FreeBSD version is now 6.1.  Since the lowest
    ***REMOVED*** modules we ship are for 6.3, we will just use these instead.  They are
    ***REMOVED*** suppoed to be binary compatible (hopefully).
    if ($release >= 6.0) {
      $suffix = '-63';
    } elsif ($release >= 5.3) {
      $suffix = '-53';
    } elsif ($release >= 5.0) {
      ***REMOVED*** sbin dir is a special case here and is handled within getFreeBSDSbinSuffix().
      $suffix = '';
    }
  }

  return $suffix;
}

***REMOVED*** Determine what version of FreeBSD we're on and convert that to
***REMOVED*** install package values.
sub getFreeBSDVersion {
  my $system_version = direct_command("sysctl kern.osrelease");
  if ($system_version =~ /: *([0-9]+\.[0-9]+)-/) {
    return "$1";
  }

  ***REMOVED*** If we get here, we were unable to parse kern.osrelease
  return '';
}

***REMOVED*** Determine whether SELinux is enabled.
sub is_selinux_enabled {
   if (-x "/usr/sbin/selinuxenabled") {
      my $rv = system("/usr/sbin/selinuxenabled");
      return ($rv eq 0);
   } else {
      return 0;
   }
}

***REMOVED*** Wordwrap system: append some content to the output
sub append_output {
  my $output = shift;
  my $pos = shift;
  my $append = shift;

  $output .= $append;
  $pos += length($append);
  if ($pos >= $cTerminalLineSize) {
    $output .= "\n";
    $pos = 0;
  }

  return ($output, $pos);
}

***REMOVED*** Wordwrap system: deal with the next character
sub wrap_one_char {
  my $output = shift;
  my $pos = shift;
  my $word = shift;
  my $char = shift;
  my $reserved = shift;
  my $length;

  if (not (($char eq "\n") || ($char eq ' ') || ($char eq ''))) {
    $word .= $char;

    return ($output, $pos, $word);
  }

  ***REMOVED*** We found a separator.  Process the last word

  $length = length($word) + $reserved;
  if (($pos + $length) > $cTerminalLineSize) {
    ***REMOVED*** The last word doesn't fit in the end of the line. Break the line before
    ***REMOVED*** it
    $output .= "\n";
    $pos = 0;
  }
  ($output, $pos) = append_output($output, $pos, $word);
  $word = '';

  if ($char eq "\n") {
    $output .= "\n";
    $pos = 0;
  } elsif ($char eq ' ') {
    if ($pos) {
      ($output, $pos) = append_output($output, $pos, ' ');
    }
  }

  return ($output, $pos, $word);
}

***REMOVED*** Wordwrap system: word-wrap a string plus some reserved trailing space
sub wrap {
  my $input = shift;
  my $reserved = shift;
  my $output;
  my $pos;
  my $word;
  my $i;

  if (!defined($reserved)) {
      $reserved = 0;
  }

  $output = '';
  $pos = 0;
  $word = '';
  for ($i = 0; $i < length($input); $i++) {
    ($output, $pos, $word) = wrap_one_char($output, $pos, $word,
                                           substr($input, $i, 1), 0);
  }
  ***REMOVED*** Use an artifical last '' separator to process the last word
  ($output, $pos, $word) = wrap_one_char($output, $pos, $word, '', $reserved);

  return $output;
}


***REMOVED***
***REMOVED*** send_rpc_failed_msgs
***REMOVED***
***REMOVED*** A place that gets called when the configurator/installer bails out.
***REMOVED*** this ensures that the all necessary RPC end messages are sent.
***REMOVED***
sub send_rpc_failed_msgs {
  send_rpc("toolinstall.installerActive 0");
  send_rpc('toolinstall.end 0');
}


***REMOVED*** Print an error message and exit
sub error {
  my $msg = shift;

  ***REMOVED*** Ensure you send the terminating RPC message before you
  ***REMOVED*** unmount the CD.
  my $rpcresult = send_rpc('toolinstall.is_image_inserted');
  chomp($rpcresult);

  ***REMOVED*** Send terminating RPC messages
  send_rpc_failed_msgs();

  print STDERR wrap($msg . 'Execution aborted.' . "\n\n", 0);

  ***REMOVED*** Now unmount the CD.
  if ("$rpcresult" =~ /1/) {
    eject_tools_install_cd_if_mounted();
  }

  exit 1;
}

***REMOVED*** Convert a string to its equivalent shell representation
sub shell_string {
  my $single_quoted = shift;

  $single_quoted =~ s/'/'"'"'/g;
  ***REMOVED*** This comment is a fix for emacs's broken syntax-highlighting code
  return '\'' . $single_quoted . '\'';
}

***REMOVED*** Send an arbitrary RPC command to the VMX
sub send_rpc {
  my $command = shift;
  my $rpctoolSuffix;
  my $rpctoolBinary = '';
  my $libDir;
  my @rpcResultLines;


  if (vmware_product() eq 'tools-for-solaris') {
     $rpctoolSuffix = is64BitUserLand() ? '/sbin/amd64' : '/sbin/i86';
  } else {
     $rpctoolSuffix = is64BitUserLand() ? '/sbin64' : '/sbin32';
  }

  $rpctoolSuffix .= getFreeBSDSbinSuffix() . '/vmware-rpctool';

  ***REMOVED*** We don't yet know if vmware-rpctool was copied into place.
  ***REMOVED*** Let's first try getting the location from the DB.
  $libDir = db_get_answer_if_exists('LIBDIR');
  if (defined($libDir)) {
    $rpctoolBinary = $libDir . $rpctoolSuffix;
  }
  if (not (-x "$rpctoolBinary")) {
    ***REMOVED*** The DB didn't help.  But no matter, we can
    ***REMOVED*** extract a path to the untarred tarball installer from our
    ***REMOVED*** current location.  With that info, we can invoke the
    ***REMOVED*** rpc tool directly out of the staging area.  Woot!
    $rpctoolBinary = "./lib" .  $rpctoolSuffix;
  }

  ***REMOVED*** If we found the binary, send the RPC.
  if (-x "$rpctoolBinary") {
    open (RPCRESULT, shell_string($rpctoolBinary) . " " .
          shell_string($command) . ' 2> /dev/null |');

    @rpcResultLines = <RPCRESULT>;
    close RPCRESULT;
    return (join("\n", @rpcResultLines));
  } else {
    ***REMOVED*** Return something so we don't get any undef errors.
    return '';
  }
}

***REMOVED*** chmod() that reports errors
sub safe_chmod {
  my $mode = shift;
  my $file = shift;

  if (chmod($mode, $file) != 1) {
    error('Unable to change the access rights of the file ' . $file . '.'
          . "\n\n");
  }
}

***REMOVED*** Create a temporary directory
***REMOVED***
***REMOVED*** They are a lot of small utility programs to create temporary files in a
***REMOVED*** secure way, but none of them is standard. So I wrote this
sub make_tmp_dir {
  my $prefix = shift;
  my $tmp;
  my $serial;
  my $loop;

  $tmp = defined($ENV{'TMPDIR'}) ? $ENV{'TMPDIR'} : '/tmp';

  ***REMOVED*** Don't overwrite existing user data
  ***REMOVED*** -> Create a directory with a name that didn't exist before
  ***REMOVED***
  ***REMOVED*** This may never succeed (if we are racing with a malicious process), but at
  ***REMOVED*** least it is secure
  $serial = 0;
  for (;;) {
    ***REMOVED*** Check the validity of the temporary directory. We do this in the loop
    ***REMOVED*** because it can change over time
    if (not (-d $tmp)) {
      error('"' . $tmp . '" is not a directory.' . "\n\n");
    }
    if (not ((-w $tmp) && (-x $tmp))) {
      error('"' . $tmp . '" should be writable and executable.' . "\n\n");
    }

    ***REMOVED*** Be secure
    ***REMOVED*** -> Don't give write access to other users (so that they can not use this
    ***REMOVED*** directory to launch a symlink attack)
    if (mkdir($tmp . '/' . $prefix . $serial, 0755)) {
      last;
    }

    $serial++;
    if ($serial % 200 == 0) {
      print STDERR 'Warning: The "' . $tmp . '" directory may be under attack.' . "\n\n";
    }
  }

  return $tmp . '/' . $prefix . $serial;
}

***REMOVED*** Check available space when asking the user for destination directory.
sub spacechk_answer {
  my $msg = shift;
  my $type = shift;
  my $default = shift;
  my $srcDir = shift;
  my $id = shift;
  my $ifdefault = shift;
  my $answer;
  my $space = -1;

  while ($space < 0) {

    if (!defined($id)) {
      $answer = get_answer($msg, $type, $default);
    } else {
      if (!defined($ifdefault)) {
         $answer = get_persistent_answer($msg, $id, $type, $default);
      } else {
         $answer = get_persistent_answer($msg, $id, $type, $default, $ifdefault);
      }
    }

    ***REMOVED*** XXX check $answer for a null value which can happen with the get_answer
    ***REMOVED*** in config.pl but not with the get_answer in pkg_mgr.pl.  Moving these
    ***REMOVED*** (get_answer, get_persistent_answer) routines into util.pl eventually.
    if ($answer && ($space = check_disk_space($srcDir, $answer)) < 0) {
      my $lmsg;
      $lmsg = 'There is insufficient disk space available in ' . $answer
              . '.  Please make at least an additional ' . -$space
              . 'KB available';
      if ($gOption{'default'} == 1) {
        error($lmsg . ".\n");
      }
      print wrap($lmsg . " or choose another directory.\n", 0);
    }
  }
  return $answer;
}


***REMOVED***
***REMOVED*** Checks to see if the given module shares a name or PCI id with ours.
***REMOVED*** If there's a PCI or name match, send it to check_if_vmw_installed_module
***REMOVED*** to see if it's actually ours.
***REMOVED***
***REMOVED*** This does the checks in the following order
***REMOVED*** 1.  Check for PCI IDs
***REMOVED*** 2.  Check for VMware module Aliases
***REMOVED*** 3.  Check for module file names (legacy).
***REMOVED***
sub check_if_vmware_module {
  my $modPath = shift;
  my $modInfoCmd = shell_string($gHelper{'modinfo'})
                   . " -F alias $modPath 2>/dev/null";
  my @modInfoOutput = map { chomp; $_ } (`$modInfoCmd`);
  my $line;
  my $modName;
  undef $modName;

  ***REMOVED*** First check for PCI IDs/Aliases
  foreach $line (@modInfoOutput) {
    $line = reduce_pciid($line);
    $modName = $cKernelModuleAliases{"$line"};
    if (defined $modName) {
      check_if_vmw_installed_module($modName, $modPath);
      return;
    }
  }

  ***REMOVED*** Finally check the module name.
  if ($modPath =~ m,^.*/(\w+)\.k?o,) {
    foreach my $mod (@cKernelModules) {
      if ("$1" eq $mod) {
        check_if_vmw_installed_module($mod, $modPath);
        return;
      }
    }
    ***REMOVED*** If the module has been clobbered, the name is in the alias list.
    if (defined $cKernelModuleAliases{$1}) {
        return $cKernelModuleAliases{$1};
    }
  }
}

***REMOVED*** This function checks to see if the given module (modName)
***REMOVED*** is not in the db file; it adds the result
***REMOVED*** to gVmwareInstalledModules if it is in the db file
***REMOVED***
sub check_if_vmw_installed_module {
  my $modName = shift;
  my $modPath = shift;

  if (not -e $modPath) {
    return;
  }

  if (not db_file_in($modPath)) {
    ***REMOVED*** Add $modName module with path $modPath to bad list

    ***REMOVED*** Check to see if we have already found a module for this.  If
    ***REMOVED*** so, there is not much we can do.  Instead just warn the user.
    if (defined $gNonVmwareModules{$modName}) {
      print wrap("WARNING: A module identified as $modName has been found " .
        "at $gNonVmwareModules{$modName} and at $modPath.  " .
        "Leaving both modules in there could potentially " .
        "cause a race condition when a device is added.  " .
        "We recommend you remove one of them, run " .
        "'depmod -a', and then re-run this configurator.\n\n", 0);
    }

    $gNonVmwareModules{$modName} = "$modPath";
  } else {
    ***REMOVED*** Its one of our modules.  Lets keep track of where they are as
    ***REMOVED*** they might not be in the standard locations
    $gVmwareInstalledModules{$modName} = "$modPath";
  }
}

***REMOVED*** Returns the full path to the first argument. Returns first argument
***REMOVED*** if it is already a full path, returns the join() of the second and
***REMOVED*** first arguments otherwise.
***REMOVED***
sub get_full_module_path {
  my $module = shift;
  my $path = shift;
  chomp($module);

  ***REMOVED*** get rid of colon and anything following (if it exists)
  if($module =~ m/(.*):/) {
    $module = "$1";
  }

  my $fullPath;
  ***REMOVED*** if it starts with a slash, then it's already the full path
  if ($module =~ m/^\//) {
    $fullPath = $module;
  } else {
    ***REMOVED*** otherwise, get the path from the parameters and append
    $fullPath = join('/', $path, $module);
  }

  if(not -e $fullPath) {
    print wrap("WARNING: A module identified in modules.dep " .
      "could not be found. modules.dep may be out of date. " .
      "We recommend you run 'depmod -a' and then re-run this " .
      "configurator.\n\n", 0);
  }
  return $fullPath;
}

***REMOVED*** Extracts the alias and module name from a line, if it starts with "alias";
***REMOVED*** Returns empty strings otherwise. Designed for use only when parsing
***REMOVED*** modules.alias.
***REMOVED***
sub extract_alias_and_modname {
  my $line = shift;
  my $alias = "";
  my $modname = "";

  if($line =~ m/alias (.*)\s(.*)\s/) {
    $alias = "$1";
    $modname = "$2";
  }
  return ($alias, $modname);
}

***REMOVED*** Reduce PCI id by removing trailing data (subvendor, etc) from PCI IDs.
***REMOVED*** Returns the reduced PCI id if "pci" start's the string, otherwise returns
***REMOVED*** the original string.
***REMOVED***
sub reduce_pciid {
  my $string = shift;
  if ($string=~ m/^(pci:v[0-9A-F]{8}d[0-9A-F]{8})/) {
    $string= "$1";
  }
  return $string;
}

***REMOVED*** Looks for a module (*.ko) in modules.dep and returns
***REMOVED*** the full path to it if it exists; returns an empty string otherwise
***REMOVED***
sub search_for_module_in_moddep {
  my $modName = shift;
  my $libModPath = shift;

  if(open(MODDEP, "$libModPath/modules.dep")) {
    my $modPath='';
    while(<MODDEP>) {
      my $line = "$_";
      if($line =~ m/(.*$modName):.*/) {
        $modPath = get_full_module_path("$1", "$libModPath");
        last;
      }
    }
    close(MODDEP);
    return $modPath;
  } else {
    error("Unable to open kernel module dependency file\n.");
  }
}

***REMOVED*** Returns a list of VMware kernel modules that were
***REMOVED*** found on the system that were not placed there by the installer
***REMOVED*** by parsing modules.alias.
***REMOVED***
sub populate_vmw_modules_via_aliases_file {
  my $libModPath = shift;

  if(open(MODALIAS, "$libModPath/modules.alias")) {
    my @kernelModulesCopy = @cKernelModules;
    my ($alias, $actualMod, $modName, $modPath);
    while(<MODALIAS>) {
      ($alias, $actualMod) = extract_alias_and_modname("$_");
      $alias = reduce_pciid($alias);

      $modName = $cKernelModuleAliases{"$alias"};
      if (defined $modName) {
        ***REMOVED*** then a module alias matched one of our modules

        $modPath = search_for_module_in_moddep("$actualMod.ko", $libModPath);
        ***REMOVED*** remove $modName from @kernelModulesCopy
        @kernelModulesCopy = grep { $_ ne $modName } @kernelModulesCopy;

        check_if_vmw_installed_module($modName, $modPath);
      }
    }

    ***REMOVED*** search for any of the remaining modules for which
    ***REMOVED*** we did not find a module alias. Have to do this
    ***REMOVED*** second because it uses kernelModulesCopy, which is changed above
    foreach my $mod (@kernelModulesCopy) {
      $modPath = search_for_module_in_moddep("$mod.ko", $libModPath);
      if (not $modPath eq '') {
        check_if_vmw_installed_module($mod, $modPath);
      }
    }
    close(MODALIAS);
  } else {
    error("Unable to open modules.alias file\n.");
  }
}

***REMOVED*** Returns a list of VMWare kernel modules that were
***REMOVED*** found on the system that were not placed there by the installer
***REMOVED*** by parsing modules.dep, modinfo-ing the module, and parsing
***REMOVED*** the output of modinfo.
***REMOVED***
sub populate_vmw_modules_via_modinfo {
  my $libModPath = shift;

  if (open(MODULESDEP, "$libModPath/modules.dep")) {
    my $modPath = '';
    while (<MODULESDEP>) {
      if (/^(.*\.k?o):.*$/) {
        ***REMOVED***
        ***REMOVED*** Then the module may not be there.  In Ubuntu 9.04, modules.dep
        ***REMOVED*** no longer has a full path for the modules.  Therefore we must
        ***REMOVED*** try out both a full path and one relative to the modules
        ***REMOVED*** directory of the currently running kernel.
        ***REMOVED***

        $modPath = get_full_module_path("$1","$libModPath");

        if (defined $modPath) {
          check_if_vmware_module($modPath);
        }
      }
    }
    close(MODULESDEP);
  } else {
    error("Unable to open kernel module dependency file\n.");
  }
}

***REMOVED*** check_for_vmw_mods_in_kernel
***REMOVED***
***REMOVED*** Checks /sys/module for our kernel modules.  This only works on the
***REMOVED*** running kernel.
***REMOVED***
sub check_for_vmw_mods_in_kernel {
   my $k;
   my $v;

   return unless (getKernRel() eq $gSystem{'uts_release'});

   while (($k, $v) = each %cUpstrKernelModNames) {
      my $path = join('/', '/sys/module', $k);
      if (-e $path) {
         $gVmwareRunningModules{$v} = $k;
      }
   }
}


***REMOVED*** Returns a list of VMware kernel modules that were
***REMOVED*** found on the system that were not placed there by the installer.
***REMOVED*** Also checks the running kernel for modules that were built in when
***REMOVED*** the kernel was compiled.
sub populate_vmware_modules {
  my $libModPath = join('/','/lib/modules', getKernRel());

  ***REMOVED*** can't continue without the modules.dep file
  system(shell_string($gHelper{'depmod'}) . ' -a');
  if (not -e "$libModPath/modules.dep") {
    error("Unable to find kernel module dependency file\n.");
  }

  if (-e "$libModPath/modules.alias") {
    populate_vmw_modules_via_aliases_file($libModPath);
  } else {
    populate_vmw_modules_via_modinfo($libModPath);
  }

  check_for_vmw_mods_in_kernel();
}


***REMOVED*** Call restorecon on the supplied file if selinux is enabled
sub restorecon {
  my $file = shift;

   if (is_selinux_enabled()) {
     system("/sbin/restorecon " . $file);
     ***REMOVED*** Return a 1, restorecon was called.
     return 1;
   }

  ***REMOVED*** If it is not enabled, return a -1, restorecon was NOT called.
  return -1;
}

***REMOVED*** Append a clearly delimited block to an unstructured text file
***REMOVED*** Result:
***REMOVED***  1 on success
***REMOVED***  -1 on failure
sub block_append {
   my $file = shift;
   my $begin = shift;
   my $block = shift;
   my $end = shift;

   if (not open(BLOCK, '>>' . $file)) {
      return -1;
   }

   print BLOCK $begin . $block . $end;

   if (not close(BLOCK)) {
     ***REMOVED*** Even if close fails, make sure to call restorecon.
     restorecon($file);
     return -1;
   }

   ***REMOVED*** Call restorecon to set SELinux policy for this file.
   restorecon($file);
   return 1;
}

***REMOVED*** Append a clearly delimited block to an unstructured text file
***REMOVED*** and add this file to an "answer" entry in the locations db
***REMOVED***
***REMOVED*** Result:
***REMOVED***  1 on success
***REMOVED***  -1 on failure
sub block_append_with_db_answer_entry {
   my $file = shift;
   my $block = shift;

   return -1 if (block_append($file, $cMarkerBegin, $block, $cMarkerEnd) < 0);

   ***REMOVED*** get the list of already-appended files
   my $list = db_get_answer_if_exists($cDBAppendString);

   ***REMOVED*** No need to check if there's anything in the list because
   ***REMOVED*** db_add_answer removes the existing answer with the same name
   if ($list) {
      $list = join(':', $list, $file);
   } else {
      $list = $file;
   }
   db_add_answer($cDBAppendString, $list);

   return 1;
}


***REMOVED*** Insert a clearly delimited block to an unstructured text file
***REMOVED***
***REMOVED*** Uses a regexp to find a particular spot in the file and adds
***REMOVED*** the block at the first regexp match.
***REMOVED***
***REMOVED*** Result:
***REMOVED***  1 on success
***REMOVED***  0 on no regexp match (nothing added)
***REMOVED***  -1 on failure
sub block_insert {
   my $file = shift;
   my $regexp = shift;
   my $begin = shift;
   my $block = shift;
   my $end = shift;
   my $line_added = 0;
   my $tmp_dir = make_tmp_dir('vmware-block-insert');
   my $tmp_file = $tmp_dir . '/tmp_file';

   if (not open(BLOCK_IN, '<' . $file) or
       not open(BLOCK_OUT, '>' . $tmp_file)) {
      return -1;
   }

   foreach my $line (<BLOCK_IN>) {
     if ($line =~ /($regexp)/ and not $line_added) {
       print BLOCK_OUT $begin . $block . $end;
       $line_added = 1;
     }
     print BLOCK_OUT $line;
   }

   if (not close(BLOCK_IN) or not close(BLOCK_OUT)) {
     return -1;
   }

   if (not system(shell_string($gHelper{'mv'}) . " $tmp_file $file")) {
     return -1;
   }

   remove_tmp_dir($tmp_dir);

   ***REMOVED*** Call restorecon to set SELinux policy for this file.
   restorecon($file);

   ***REMOVED*** Our return status is 1 if successful, 0 if nothing was added.
   return $line_added
}


***REMOVED*** Test if specified file contains line matching regular expression
***REMOVED*** Result:
***REMOVED***  undef on failure
***REMOVED***  first matching line on success
sub block_match {
   my $file = shift;
   my $block = shift;
   my $line = undef;

   if (open(BLOCK, '<' . $file)) {
      while (defined($line = <BLOCK>)) {
         chomp $line;
         last if ($line =~ /$block/);
      }
      close(BLOCK);
   }
   return defined($line);
}


***REMOVED*** Remove all clearly delimited blocks from an unstructured text file
***REMOVED*** Result:
***REMOVED***  >= 0 number of blocks removed on success
***REMOVED***  -1 on failure
sub block_remove {
   my $src = shift;
   my $dst = shift;
   my $begin = shift;
   my $end = shift;
   my $count;
   my $state;

   if (not open(SRC, '<' . $src)) {
      return -1;
   }

   if (not open(DST, '>' . $dst)) {
      close(SRC);
      return -1;
   }

   $count = 0;
   $state = 'outside';
   while (<SRC>) {
      if      ($state eq 'outside') {
         if ($_ eq $begin) {
            $state = 'inside';
            $count++;
         } else {
            print DST $_;
         }
      } elsif ($state eq 'inside') {
         if ($_ eq $end) {
            $state = 'outside';
         }
      }
   }

   if (not close(DST)) {
      close(SRC);
      ***REMOVED*** Even if close fails, make sure to call restorecon on $dst.
      restorecon($dst);
      return -1;
   }

   ***REMOVED*** $dst file has been modified, call restorecon to set the
   ***REMOVED***  SELinux policy for it.
   restorecon($dst);

   if (not close(SRC)) {
      return -1;
   }

   return $count;
}

***REMOVED*** Similar to block_remove().  Find the delimited text, bracketed by $begin and $end,
***REMOVED*** and filter it out as the file is written out to a tmp file. Typicaly, block_remove()
***REMOVED*** is used in the pattern:  create tmp dir, create tmp file, block_remove(), mv file,
***REMOVED*** remove tmp dir. This encapsulates the pattern.
sub block_restore {
  my $src_file = shift;
  my $begin_marker = shift;
  my $end_marker = shift;
  my $tmp_dir = make_tmp_dir('vmware-block-restore');
  my $tmp_file = $tmp_dir . '/tmp_file';
  my $rv;
  my @sb;

  @sb = stat($src_file);

  $rv = block_remove($src_file, $tmp_file, $begin_marker, $end_marker);
  if ($rv >= 0) {
    system(shell_string($gHelper{'mv'}) . ' ' . $tmp_file . ' ' . $src_file);
    safe_chmod($sb[2], $src_file);
  }
  remove_tmp_dir($tmp_dir);

  ***REMOVED*** Call restorecon on the source file.
  restorecon($src_file);

  return $rv;
}

***REMOVED*** match the output of 'uname -s' to the product. These are compared without
***REMOVED*** case sensitivity.
sub DoesOSMatchProduct {

 my %osProductHash = (
    'tools-for-linux'   => 'linux',
    'tools-for-solaris' => 'sunos',
    'tools-for-freebsd' => 'freebsd'
 );

 my $OS = `uname -s`;
 chomp($OS);

 return ($osProductHash{vmware_product()} =~ m/$OS/i) ? 1 : 0;

}

***REMOVED*** Remove leading and trailing whitespaces
sub remove_whitespaces {
  my $string = shift;

  $string =~ s/^\s*//;
  $string =~ s/\s*$//;
  return $string;
}

***REMOVED*** Ask a question to the user and propose an optional default value
***REMOVED*** Use this when you don't care about the validity of the answer
sub query {
    my $message = shift;
    my $defaultreply = shift;
    my $reserved = shift;
    my $reply;
    my $default_value = $defaultreply eq '' ? '' : ' [' . $defaultreply . ']';
    my $terse = 'no';

    ***REMOVED*** Allow the script to limit output in terse mode.  Usually dictated by
    ***REMOVED*** vix in a nested install and the '--default' option.
    if (db_get_answer_if_exists('TERSE')) {
      $terse = db_get_answer('TERSE');
      if ($terse eq 'yes') {
        $reply = remove_whitespaces($defaultreply);
        return $reply;
      }
    }

    ***REMOVED*** Reserve some room for the reply
    print wrap($message . $default_value, 1 + $reserved);

    ***REMOVED*** This is what the 1 is for
    print ' ';

    if ($gOption{'default'} == 1) {
      ***REMOVED*** Simulate the enter key
      print "\n";
      $reply = '';
    } else {
      $reply = <STDIN>;
      $reply = '' unless defined($reply);
      chomp($reply);
    }

    print "\n";
    $reply = remove_whitespaces($reply);
    if ($reply eq '') {
      $reply = $defaultreply;
    }
    return $reply;
}

***REMOVED*** Execute the command passed as an argument
***REMOVED*** _without_ interpolating variables (Perl does it by default)
sub direct_command {
  return `$_[0]`;
}

***REMOVED*** If there is a pid for this process, consider it running.
sub check_is_running {
  my $proc_name = shift;
  my $rv = system(shell_string($gHelper{'pidof'}) . " " . $proc_name . " > /dev/null");
  return $rv eq 0;
}

***REMOVED*** OS-independent method of loading a kernel module by module name
***REMOVED*** Returns true (non-zero) if the operation succeeded, false otherwise.
sub kmod_load_by_name {
    my $modname = shift; ***REMOVED*** IN: Module name
    my $doSilent = shift; ***REMOVED*** IN: Flag to indicate whether loading should be done silently

    my $silencer = '';
    if (defined($doSilent) && $doSilent) {
	$silencer = ' >/dev/null 2>&1';
    }

    if (defined($gHelper{'modprobe'})) { ***REMOVED*** Linux
	return !system(shell_string($gHelper{'modprobe'}) . ' ' . shell_string($modname)
		       . $silencer);
    } elsif (defined($gHelper{'kldload'})) { ***REMOVED*** FreeBSD
	return !system(shell_string($gHelper{'kldload'}) . ' ' . shell_string($modname)
		       . $silencer);
    } elsif (defined($gHelper{'modload'})) { ***REMOVED*** Solaris
	return !system(shell_string($gHelper{'modload'}) . ' ' . shell_string($modname)
		       . $silencer);
    }

    return 0; ***REMOVED*** Failure
}

***REMOVED*** OS-independent method of loading a kernel module by object path
***REMOVED*** Returns true (non-zero) if the operation succeeded, false otherwise.
sub kmod_load_by_path {
    my $modpath = shift; ***REMOVED*** IN: Path to module object file
    my $doSilent = shift; ***REMOVED*** IN: Flag to indicate whether loading should be done silently
    my $doForce = shift; ***REMOVED*** IN: Flag to indicate whether loading should be forced
    my $probe = shift; ***REMOVED*** IN: 1 if to probe only, 0 if to actually load

    my $silencer = '';
    if (defined($doSilent) && $doSilent) {
	$silencer = ' >/dev/null 2>&1';
    }

    if (defined($gHelper{'insmod'})) { ***REMOVED*** Linux
	return !system(shell_string($gHelper{'insmod'}) . ($probe ? ' -p ' : ' ')
		       . ((defined($doForce) && $doForce) ? ' -f ' : ' ')
		       . shell_string($modpath)
		       . $silencer);
    } elsif (defined($gHelper{'kldload'})) { ***REMOVED*** FreeBSD
	return !system(shell_string($gHelper{'kldload'}) . ' ' . shell_string($modpath)
		       . $silencer);
    } elsif (defined($gHelper{'modload'})) { ***REMOVED*** Solaris
	return !system(shell_string($gHelper{'modload'}) . ' ' . shell_string($modpath)
		       . $silencer);
    }

    return 0; ***REMOVED*** Failure
}

***REMOVED*** OS-independent method of unloading a kernel module by name
***REMOVED*** Returns true (non-zero) if the operation succeeded, false otherwise.
sub kmod_unload {
    my $modname = shift;     ***REMOVED*** IN: Module name
    my $doRecursive = shift; ***REMOVED*** IN: Whether to also try loading modules that
                             ***REMOVED*** become unused as a result of unloading $modname

    if (defined($gHelper{'modprobe'})
	&& defined($doRecursive) && $doRecursive) { ***REMOVED*** Linux (with $doRecursive)
	return !system(shell_string($gHelper{'modprobe'}) . ' -r ' . shell_string($modname)
		       . ' >/dev/null 2>&1');
    } elsif (defined($gHelper{'rmmod'})) { ***REMOVED*** Linux (otherwise)
	return !system(shell_string($gHelper{'rmmod'}) . ' ' . shell_string($modname)
		       . ' >/dev/null 2>&1');
    } elsif (defined($gHelper{'kldunload'})) { ***REMOVED*** FreeBSD
	return !system(shell_string($gHelper{'kldunload'}) . ' ' . shell_string($modname)
		       . ' >/dev/null 2>&1');
    } elsif (defined($gHelper{'modunload'})) { ***REMOVED*** Solaris
	***REMOVED*** Solaris won't let us unload by module name, so we have to find the ID from modinfo
	my $aline;
	my @lines = split('\n', direct_command(shell_string($gHelper{'modinfo'})));

	foreach $aline (@lines) {
	    chomp($aline);
	    my($amodid, $dummy2, $dummy3, $dummy4, $dummy5, $amodname) = split(/\s+/, $aline);

	    if ($modname eq $amodname) {
		return !system(shell_string($gHelper{'modunload'}) . ' -i ' . $amodid
			       . ' >/dev/null 2>&1');
	    }
	}

	return 0; ***REMOVED*** Failure - module not found
    }

    return 0; ***REMOVED*** Failure
}

***REMOVED***
***REMOVED*** check to see if the certificate files exist (and
***REMOVED*** that they appear to be a valid certificate).
***REMOVED***
sub certificateExists {
  my $certLoc = shift;
  my $openssl_exe = shift;
  my $certPrefix = shift;
  my $ld_lib_path = $ENV{'LD_LIBRARY_PATH'};
  my $libdir = db_get_answer('LIBDIR') . '/lib';
  $ld_lib_path .= ';' . $libdir . '/libssl.so.0.9.8;' . $libdir . '/libcrypto.so.0.9.8';

  my $ld_lib_string = "LD_LIBRARY_PATH='" . $ld_lib_path . "'";
  return ((-e "$certLoc/$certPrefix.crt") &&
          (-e "$certLoc/$certPrefix.key") &&
          !(system($ld_lib_string . " " . shell_string("$openssl_exe") . ' x509 -in '
                   . shell_string("$certLoc") . "/$certPrefix.crt " .
                   ' -noout -subject > /dev/null 2>&1')));
}

***REMOVED*** Helper function to create SSL certificates
sub createSSLCertificates {
  my ($openssl_exe, $vmware_version, $certLoc, $certPrefix, $unitName) = @_;
  my $certUniqIdent = "(564d7761726520496e632e)";
  my $certCnf;
  my $curTime = time();
  my $hostname = direct_command(shell_string($gHelper{"hostname"}));

  my $cTmpDirPrefix = "vmware-ssl-config";
  my $tmpdir;

  if (certificateExists($certLoc, $openssl_exe, $certPrefix)) {
    print wrap("Using Existing SSL Certificate.\n", 0);
    return;
  }

  ***REMOVED*** Create the directory
  if (! -e $certLoc) {
    create_dir($certLoc, $cFlagDirectoryMark);
  }

  $tmpdir = make_tmp_dir($cTmpDirPrefix);
  $certCnf = "$tmpdir/certificate.cnf";
  if (not open(CONF, '>' . $certCnf)) {
    error("Unable to open $certCnf to create SSL certificate.\n")
  }
  print CONF <<EOF;
  ***REMOVED*** Conf file that we will use to generate SSL certificates.
RANDFILE                = $tmpdir/seed.rnd
[ req ]
default_bits		= 1024
default_keyfile 	= $certPrefix.key
distinguished_name	= req_distinguished_name

***REMOVED***Don't encrypt the key
encrypt_key             = no
prompt                  = no

string_mask = nombstr

[ req_distinguished_name ]
countryName= US
stateOrProvinceName     = California
localityName            = Palo Alto
0.organizationName      = VMware, Inc.
organizationalUnitName  = $unitName
commonName              = $hostname
unstructuredName        = ($curTime),$certUniqIdent
emailAddress            = ssl-certificates\@vmware.com
EOF
  close(CONF);

  my $ld_lib_path = $ENV{'LD_LIBRARY_PATH'};
  my $libdir = db_get_answer('LIBDIR') . '/lib';
  $ld_lib_path .= ';' . $libdir . '/libssl.so.0.9.8;' . $libdir . '/libcrypto.so.0.9.8';
  my $ld_lib_string = "LD_LIBRARY_PATH='" . $ld_lib_path . "'";

  system($ld_lib_string . " " . shell_string("$openssl_exe") . ' req -new -x509 -keyout '
         . shell_string("$certLoc") . '/' . shell_string("$certPrefix")
         . '.key -out ' . shell_string("$certLoc") . '/'
         . shell_string("$certPrefix") . '.crt -config '
         . shell_string("$certCnf") . ' -days 5000 > /dev/null 2>&1');
  db_add_file("$certLoc/$certPrefix.key", $cFlagTimestamp);
  db_add_file("$certLoc/$certPrefix.crt", $cFlagTimestamp);

  remove_tmp_dir($tmpdir);
  ***REMOVED*** Make key readable only by root (important)
  safe_chmod(0400, "$certLoc" . '/' . "$certPrefix" . '.key');

  ***REMOVED*** Let anyone read the certificate
  safe_chmod(0444, "$certLoc" . '/' . "$certPrefix" . '.crt');
}

***REMOVED*** Install a pair of S/K startup scripts for a given runlevel
sub link_runlevel {
   my $level = shift;
   my $service = shift;
   my $S_level = shift;
   my $K_level = shift;

   ***REMOVED***
   ***REMOVED*** Create the S symlink
   ***REMOVED***
   install_symlink(db_get_answer('INITSCRIPTSDIR') . '/' . $service,
                   db_get_answer('INITDIR') . '/rc' . $level . '.d/S'
                   . $S_level . $service);

   ***REMOVED***
   ***REMOVED*** Create the K symlink
   ***REMOVED***
   install_symlink(db_get_answer('INITSCRIPTSDIR') . '/' . $service,
                   db_get_answer('INITDIR') . '/rc' . $level . '.d/K'
                   . $K_level . $service);
}

***REMOVED*** Create the links for VMware's services taking the service name and the
***REMOVED*** requested levels
sub link_services {
   my @fields;
   my $service = shift;
   my $S_level = shift;
   my $K_level = shift;

   ***REMOVED*** Try using insserv if it is available.
   my $init_style = db_get_answer_if_exists('INIT_STYLE');

   if ($gHelper{'insserv'} ne '') {
     if (0 == system(shell_string($gHelper{'insserv'}) . ' '
                     . shell_string(db_get_answer('INITSCRIPTSDIR')
                                    . '/' . $service) . ' >/dev/null 2>&1')) {
       return;
     }
   }
   if ("$init_style" eq 'lsb') {
     ***REMOVED*** Then we have gotten here, but gone past the insserv section, indicating
     ***REMOVED*** that insserv cannot be found.  Warn the user...
     print wrap("WARNING: The installer initially used the " .
                "insserv application to setup the vmware-tools service.  " .
                "That application did not run successfully.  " .
                "Please re-install the insserv application or check your settings.  " .
                "This script will now attempt to manually setup the " .
                "vmware-tools service.\n\n", 0);
   }

   ***REMOVED*** Now try using chkconfig if available.
   ***REMOVED*** Note: RedHat's chkconfig reads LSB INIT INFO if present.
   if ($gHelper{'chkconfig'} ne '') {
     if (0 == system(shell_string($gHelper{'chkconfig'}) . ' '
                     . $service . ' reset')) {
       return;
     }
   }
   if ("$init_style" eq 'chkconfig') {
     ***REMOVED*** Then we have gotten here, but gone past the chkconfig section, indicating
     ***REMOVED*** that chkconfig cannot be found.  Warn the user..
     print wrap("WARNING: The installer initially used the " .
                "chkconfig application to setup the vmware-tools service.  " .
                "That application did not run successfully.  " .
                "Please re-install the chkconfig application or check your settings.  " .
                "This script will now attempt to manually setup the " .
                "vmware-tools service.\n\n", 0);
   }

   ***REMOVED*** Now try using update-rc.d if available.
   if ($gHelper{'update-rc.d'} ne '') {
     if (0 == system(shell_string($gHelper{'update-rc.d'}) . " " . $service
	             . " start " . $S_level . " S ."
                     . " start " . $K_level . " 0 6 .")) {
       return;
     }
   }
   if ("$init_style" eq 'update-rc.d') {
     ***REMOVED*** Then we have gotten here, but gone past the update-rc.d section, indicating
     ***REMOVED*** that update-rc.d cannot be found.  Warn the user..
     print wrap("WARNING: The installer initially used the " .
                "'udpate-rc.d' to setup the vmware-tools service.  " .
                "That command cannot be found.  " .
                "Please re-install the 'sysv-rc' package.  " .
                "This script will now attempt to manually setup the " .
                "vmware-tools service.", 0);
   }

   if (distribution_info() eq "debian") {
     ***REMOVED*** Set up vmware to start at run level S
     install_symlink(db_get_answer('INITSCRIPTSDIR') . '/' . $service,
                     db_get_answer('INITDIR') . '/rcS.d/S' . $S_level . $service);
   }
   else {
     ***REMOVED*** Set up vmware to start/stop at run levels 2, 3 and 5
     link_runlevel(2, $service, $S_level, $K_level);
     link_runlevel(3, $service, $S_level, $K_level);
     link_runlevel(5, $service, $S_level, $K_level);
   }

   ***REMOVED*** Set up vmware to stop at run levels 0 and 6
   my $K_prefix = "K";
   if (distribution_info() eq "debian") {
     $K_prefix = "S";
   }
   install_symlink(db_get_answer('INITSCRIPTSDIR') . '/' . $service,
                   db_get_answer('INITDIR') . '/rc0' . '.d/' . $K_prefix
                   . $K_level . $service);
   install_symlink(db_get_answer('INITSCRIPTSDIR') . '/' . $service,
                   db_get_answer('INITDIR') . '/rc6' . '.d/' . $K_prefix
                   . $K_level . $service);
}


***REMOVED*** Emulate a simplified ls program for directories
sub internal_ls {
  my $dir = shift;
  my @fn;

  opendir(LS, $dir) or return ();
  @fn = grep(!/^\.\.?$/, readdir(LS));
  closedir(LS);

  return @fn;
}


***REMOVED*** Emulate a simplified dirname program
sub internal_dirname {
  my $path = shift;
  my $pos;

  $path = dir_remove_trailing_slashes($path);

  $pos = rindex($path, '/');
  if ($pos == -1) {
    ***REMOVED*** No slash
    return '.';
  }

  if ($pos == 0) {
    ***REMOVED*** The only slash is at the beginning
    return '/';
  }

  return substr($path, 0, $pos);
}

sub internal_dirname_vcli {
  my $path = shift;
  my $pos;

  $path = dir_remove_trailing_slashes($path);

  $pos = rindex($path, '/');
  if ($pos == -1) {
    ***REMOVED*** No slash
    return '.';
  }

  my @arr1 = split(/\//, $path);

  ***REMOVED*** if "/bin" is top directory return parent directory as base directory
  if ( $arr1[scalar(@arr1) -1] eq "bin" ) {
    return substr($path, 0, $pos);
  }

  return $path;
}

***REMOVED***
***REMOVED*** unconfigure_autostart_legacy --
***REMOVED***
***REMOVED***      Remove VMware-added blocks relating to vmware-user autostart from
***REMOVED***      pre-XDG resource files, scripts, etc.
***REMOVED***
***REMOVED*** Results:
***REMOVED***      OpenSuSE:        Revert xinitrc.common.
***REMOVED***      Debian/Ubuntu:   Remove script from Xsession.d.
***REMOVED***      xdm:             Revert xdm-config(s).
***REMOVED***      gdm:             None.  (gdm mechanism used install_symlink, so that will be
***REMOVED***                       cleaned up separately.)
***REMOVED***
***REMOVED*** Side effects:
***REMOVED***      None.
***REMOVED***

sub unconfigure_autostart_legacy {
   my $markerBegin = shift;     ***REMOVED*** IN: block begin marker
   my $markerEnd = shift;       ***REMOVED*** IN: block end marker

   if (!defined($markerBegin) || !defined($markerEnd)) {
      return;
   }

   my $chompedMarkerBegin = $markerBegin; ***REMOVED*** block_match requires chomped markers
   chomp($chompedMarkerBegin);

   ***REMOVED***
   ***REMOVED*** OpenSuSE (xinitrc.common)
   ***REMOVED***
   my $xinitrcCommon = '/etc/X11/xinit/xinitrc.common';
   if (-f $xinitrcCommon && block_match($xinitrcCommon, $chompedMarkerBegin)) {
      block_restore($xinitrcCommon, $markerBegin, $markerEnd);
   }

   ***REMOVED***
   ***REMOVED*** Debian (Xsession.d) - We forgot to simply call db_add_file() after
   ***REMOVED*** creating this one.
   ***REMOVED***
   my $dotdScript = '/etc/X11/Xsession.d/99-vmware_vmware-user';
   if (-f $dotdScript && !db_file_in($dotdScript)) {
      unlink($dotdScript);
   }

   ***REMOVED***
   ***REMOVED*** xdm
   ***REMOVED***
   my @xdmcfgs = ("/etc/X11/xdm/xdm-config");
   my $x11Base = db_get_answer_if_exists('X11DIR');
   if (defined($x11Base)) {
      push(@xdmcfgs, "$x11Base/lib/X11/xdm/xdm-config");
   }
   foreach (@xdmcfgs) {
      if (-f $_ && block_match($_, "!$chompedMarkerBegin")) {
         block_restore($_, "!$markerBegin", "!$markerEnd");
      }
   }
}

***REMOVED*** Check a mountpoint to see if it hosts the guest tools install iso.
sub check_mountpoint_for_tools {
   my $mountpoint = shift;
   my $foundit = 0;

   if (vmware_product() eq 'tools-for-solaris') {
      if ($mountpoint =~ /vmwaretools$/ ||
          $mountpoint =~ /\/media\/VMware Tools$/) {
         $foundit = 1;
      }
   } elsif (opendir CDROMDIR, $mountpoint) {
      my @dircontents = readdir CDROMDIR;
      foreach my $entry ( @dircontents ) {
         if (vmware_product() eq 'tools-for-linux') {
            if ($entry =~ /VMwareTools-.*\.tar\.gz$/) {
               $foundit = 1;
            }
         } elsif (vmware_product() eq 'tools-for-freebsd') {
            if ($entry =~ /vmware-freebsd-tools\.tar\.gz$/) {
               $foundit = 1;
            }
         }
      }
      closedir(CDROMDIR);
   }
   return $foundit;
}

***REMOVED*** Try to eject the guest tools install cd so the user doesn't have to manually.
sub eject_tools_install_cd_if_mounted {
   ***REMOVED*** TODO: Add comments to the other code which generates the filenames
   ***REMOVED***       and volumeids which this code is now dependent upon.
   my @candidate_mounts;
   my $device;
   my $mountpoint;
   my $fstype;
   my $rest;
   my $eject_cmd = '';
   my $eject_failed = 0;
   my $eject_really_failed = 0;

   ***REMOVED*** For each architecture, first collect a list of mounted cdroms.
   if (vmware_product() eq 'tools-for-linux') {
      $eject_cmd = internal_which('eject');
      if (open(MOUNTS, '</proc/mounts')) {
         while (<MOUNTS>) {
            ($device, $mountpoint, $fstype, $rest) = split;
            ***REMOVED*** note: /proc/mounts replaces spaces with \040
            $device =~ s/\\040/\ /g;
            $mountpoint =~ s/\\040/\ /g;
            if ($fstype eq "iso9660" && $device !~ /loop/ ) {
               push(@candidate_mounts, "${device}::::${mountpoint}");
            }
         }
         close(MOUNTS);
      }
   } elsif (vmware_product() eq 'tools-for-freebsd' and
	    -x internal_which('mount')) {
      $eject_cmd = internal_which('cdcontrol') . " eject";
      my @mountlines = split('\n', direct_command(internal_which('mount')));
      foreach my $mountline (@mountlines) {
         chomp($mountline);
         if ($mountline =~ /^(.+)\ on\ (.+)\ \(([0-9a-zA-Z]+),/) {
	   $device = $1;
	   $mountpoint = $2;
	   $fstype = $3;

	   ***REMOVED*** If the device begins with /dev/md it will most likely
	   ***REMOVED*** be the equivalent of a loopback mount in linux.
	   if ($fstype eq "cd9660" && $device !~ /^\/dev\/md/) {
	     push(@candidate_mounts, "${device}::::${mountpoint}");
	   }
	 }
       }
   } elsif (vmware_product() eq 'tools-for-solaris') {
      $eject_cmd = internal_which('eject');
      ***REMOVED*** If this fails, don't bother trying to unmount, or error.
      if (open(MNTTAB, '</etc/mnttab')) {
         while (<MNTTAB>) {
            ($device, $rest) = split("\t", $_);
            ***REMOVED*** I don't think there are actually ever comments in /etc/mnttab.
            next if $device =~ /^***REMOVED***/;
            if ($device =~ /vmwaretools$/ ||
                $rest =~ /\/media\/VMware Tools$/) {
               $mountpoint = $rest;
               $mountpoint =~ s/(.*)\s+hsfs.*/$1/;
               push(@candidate_mounts, "${device}::::${mountpoint}");
            }
         }
         close(MNTTAB);
      }
   }

   ***REMOVED*** For each mounted cdrom, check if it's vmware guest tools installer,
   ***REMOVED*** and if so, try to eject it, then verify.
   foreach my $candidate_mount (@candidate_mounts) {
      ($device, $mountpoint) = split('::::',$candidate_mount);
      if (check_mountpoint_for_tools($mountpoint)) {
         print wrap("Found VMware Tools CDROM mounted at " .
                    "${mountpoint}. Ejecting device $device ...\n");

         ***REMOVED*** Freebsd doesn't auto unmount along with eject.
         if (vmware_product() eq 'tools-for-freebsd' and
	     -x internal_which('umount')) {
            ***REMOVED*** If this fails, the eject will fail, and the user will see
            ***REMOVED*** the appropriate output.
            direct_command(internal_which('umount') .
                           ' "' . $device . '"');
         }
	 my @output = ();
	 if ($eject_cmd ne '') {
	   open(CMDOUTPUT, "$eject_cmd $device 2>&1 |");
	   @output = <CMDOUTPUT>;
	   close(CMDOUTPUT);
	   $eject_failed = $?;
	 } else {
	   $eject_failed = 1;
	 }

         ***REMOVED*** For unknown reasons, eject can succeed, but return error, so
         ***REMOVED*** double check that it really failed before showing the output to
         ***REMOVED*** the user.  For more details see bug170327.
         if ($eject_failed && check_mountpoint_for_tools($mountpoint)) {
            foreach my $outputline (@output) {
               print wrap ($outputline, 0);
            }

            ***REMOVED*** $eject_really_failed ensures this message is not printed
            ***REMOVED*** multiple times.
            if (not $eject_really_failed) {
	      if ($eject_cmd eq '') {
		 print wrap ("No eject (or equivilant) command could be " .
			     "located.\n");
	       }
	      print wrap ("Eject Failed:  If possible manually eject the " .
			  "Tools installer from the guest cdrom mounted " .
			  "at $mountpoint before canceling tools install " .
			  "on the host.\n", 0);

	      $eject_really_failed = 1;
            }
         }
      }
   }
}


***REMOVED*** Compares variable length version strings against one another.
***REMOVED*** Returns 1 if the first version is greater, -1 if the second
***REMOVED*** version is greater, or 0 if they are equal.
sub dot_version_compare {
  my $str1 = shift;
  my $str2 = shift;

  if ("$str1" eq '' or "$str2" eq '') {
    if ("$str1" eq '' and "$str2" eq '') {
      return 0;
    } else {
      return (("$str1" eq '') ? -1 : 1);
    }
  }

  if ("$str1" =~ /[^0-9\.]+/ or "$str2" =~ /[^0-9\.]+/) {
    error("Bad character detected in dot_version_compare.\n");
  }

  my @arr1 = split(/\./, "$str1");
  my @arr2 = split(/\./, "$str2");
  my $indx = 0;
  while(1) {
     if (!defined $arr1[$indx] and !defined $arr2[$indx]) {
        return 0;
     }

     $arr1[$indx] = 0 if not defined $arr1[$indx];
     $arr2[$indx] = 0 if not defined $arr2[$indx];

     if ($arr1[$indx] != $arr2[$indx]) {
        return (($arr1[$indx] > $arr2[$indx]) ? 1 : -1);
     }
     $indx++;
  }
  error("NOT REACHED IN DOT_VERSION_COMPARE\n");
}


***REMOVED*** Checks for versioning information in both the system module
***REMOVED*** and the shipped module.  If it finds information in the sytem
***REMOVED*** module, it compares it against the version information of the
***REMOVED*** shipped module and will use whatever module is newer.
***REMOVED*** Returns 1 if it uses the shipped module (and 0 otherwise).
sub install_x_module {
  my $shippedMod = shift;
  my $systemMod = shift;
  my $modinfo = internal_which('modinfo');
  my $shippedModVer = '';
  my $systemModVer = '';
  my $installShippedModule = 0;
  my $line;

  if (not -r $shippedMod) {
    error("Could not read $shippedMod\n");
  }

  if ("$modinfo" ne '' and -r "$systemMod") {
    open (SHIPPED_MOD_VER, "$modinfo $shippedMod |");
    open (SYSTEM_MOD_VER, "$modinfo $systemMod |");

    foreach $line (<SHIPPED_MOD_VER>) {
      if ($line =~ /version: +([0-9\.]+)/) {
        $shippedModVer = "$1";
        last;
      }
    }
    foreach $line (<SYSTEM_MOD_VER>) {
      if ($line =~ /version: +([0-9\.]+)/) {
        $systemModVer = "$1";
        last;
      }
    }

    close (SHIPPED_MOD_VER);
    close (SYSTEM_MOD_VER);

    chomp ($shippedModVer);
    chomp ($systemModVer);

    if ("$systemModVer" eq '' or
	dot_version_compare ("$shippedModVer", "$systemModVer") > 0) {
      ***REMOVED*** Then the shipped module is newer than sytem module.
      $installShippedModule = 1;
    }
  } else {
    ***REMOVED*** If it has no version, assume the one we ship is newer.
    $installShippedModule = 1;
  }

  if ($gOption{'clobber-xorg-modules'} or $installShippedModule) {
    install_x_module_no_checks($shippedMod, $systemMod);
    return 1;
  }
  return 0;
}

sub install_x_module_no_checks {
   my $shippedMod = shift;
   my $systemMod = shift;
   my %patch;
   undef %patch;

   ***REMOVED*** Ensure we have a unique backup suffix for this file.
   ***REMOVED*** Also strip off anything sh wouldn't like.  Bug 502544
   my $bkupExt = internal_basename($systemMod);
   $bkupExt =~ s/^(\w+).*$/$1/;
   backup_file_to_restore($systemMod, $bkupExt);
   install_file ("$shippedMod", "$systemMod", \%patch, 1);
}

***REMOVED*** Returns the tuple ($halScript, $halName) if the system
***REMOVED*** has scripts to control HAL.
***REMOVED***
sub get_hal_script_name {
   my $initDir = shell_string(db_get_answer('INITSCRIPTSDIR'));
   $initDir =~ s/\'//g; ***REMOVED*** Remove quotes

   my @halguesses = ("haldaemon", "hal");
   my $halScript = undef;
   my $halName = undef;

   ***REMOVED*** Attempt to find the init script for the HAL service.
   ***REMOVED*** It should be one of the names in our list of guesses.
   foreach my $hname (@halguesses) {
      if (-f "$initDir/$hname") {
         $halScript = "$initDir/$hname";
         $halName = "$hname";
      }
   }

   if (vmware_product() eq 'tools-for-solaris') {
      ***REMOVED*** In Solaris 11, use svcadm to handle HAL.
      ***REMOVED*** XXX: clean this up on main.
      my $svcadmBin = internal_which('svcadm');
      if (system("$svcadmBin refresh hal >/dev/null 2>&1") eq 0) {
         $halScript = 'svcadm';
         $halName = 'hal';
      }
   }

   return ($halScript, $halName);
}

sub restart_hal {
   my $servicePath = internal_which("service");
   my $halScript = undef;
   my $halName = undef;

   ($halScript, $halName) = get_hal_script_name();

   if ($halScript eq 'svcadm') {
      ***REMOVED*** Solaris svcadm.
      my $svcadmBin = internal_which('svcadm');
      system("$svcadmBin restart hal");
   } elsif (-d '/etc/init' and $servicePath ne '' and defined($halName)) {
      ***REMOVED*** Upstart case.
      system("$servicePath $halName restart");
   } elsif (defined($halScript)) {
      ***REMOVED*** Traditional init script restart case.
      system($halScript . ' restart');
   } else {
      print "Could not locate hal daemon init script.\n";
   }
}


sub prelink_fix {
  my $source = "/etc/vmware-tools/vmware-tools-prelink.conf";
  my $dest = '/etc/prelink.conf.d/vmware-tools-prelink.conf';
  my $prelink_file = '/etc/prelink.conf';
  my $libdir = db_get_answer_if_exists('LIBDIR');
  my %patch;

  if (defined($libdir)) {
    %patch = ('@@LIBDIR@@' => $libdir);
  } else {
    error ("LIBDIR must be defined before prelink_fix is called.\n");
  }

  if (-d internal_dirname($dest)) {
    install_file($source, $dest, \%patch, 1);
  } elsif (-f $prelink_file) {
    ***REMOVED*** Readin our prelink file, do the appropreiate substitutions, and
    ***REMOVED*** block insert it into the prelink.conf file.

    my $key;
    my $value;
    my $line;
    my $to_append = '';

    if (not open(FH, $source)) {
      error("Could not open $source\n");
    }

    foreach $line (<FH>) {
      chomp ($line);
      while (($key, $value) = each %patch) {
	$line =~ s/$key/$value/g;
      }
      $to_append .= $line . "\n";
    }

    close FH;

    if (block_insert($prelink_file, '^ *-b', $cMarkerBegin,
		     $to_append, $cMarkerEnd) == 1) {
      db_add_answer('PRELINK_CONFED', $prelink_file);
    }
  }
}


sub prelink_restore {
  my $prelink_file = db_get_answer_if_exists('PRELINK_CONFED');

  if (defined $prelink_file) {
    block_restore($prelink_file, $cMarkerBegin, $cMarkerEnd);
  }
}

***REMOVED*** Determines if the system at hand needs to have timer
***REMOVED*** based audio support disabled in pulse.  Make this call
***REMOVED*** based on the version of pulseaudio installed on the system.
***REMOVED***
sub pulseNeedsTimerBasedAudioDisabled {
   my $pulseaudioBin = internal_which("pulseaudio");
   my $cmd = "$pulseaudioBin --version";
   my $verStr = '0';

   if (-x $pulseaudioBin) {
      open(OUTPUT, "$cmd |");
      foreach my $line (<OUTPUT>) {
	 chomp $line;
	 if ($line =~ /pulseaudio *([0-9\.]+)/) {
	     $verStr = $1;
	     last
	 }
      }
      if (dot_version_compare($verStr, "0.9.19") ge 0) {
	 ***REMOVED*** Then pulseaudio's version is >= 0.9.19
	 return 1;
      }
   }

   return 0
}

***REMOVED*** Disables timer based audio scheduling in the default config
***REMOVED*** file for PulseAudio
***REMOVED***
sub pulseDisableTimerBasedAudio {
   my $cfgFile = '/etc/pulse/default.pa';
   my $regex = qr/^ *load-module +module-(udev|hal)-detect$/;
   my $tmpDir = make_tmp_dir('vmware-pulse');
   my $tmpFile = $tmpDir . '/tmp_file';
   my $fileModified = 0;

   if (not open(ORGPCF, "<$cfgFile") or
       not open(NEWPCF, ">$tmpFile")) {
      return 0;
   }

   foreach my $line (<ORGPCF>) {
      chomp $line;
      if ($line =~ $regex and $line !~ /tsched/) {
	 ***REMOVED*** add the flag if its not already there.
	 print NEWPCF "$line tsched=0\n";
	 $fileModified = 1;
      } else {
	 ***REMOVED*** just print the line.
	 print NEWPCF "$line\n";
      }
   }

   close ORGPCF;
   close NEWPCF;

   if ($fileModified) {
      backup_file_to_restore($cfgFile, "orig");
      system(join(' ', $gHelper{'cp'}, $tmpFile, $cfgFile));
      restorecon($cfgFile);
      db_add_answer('PULSE_AUDIO_CONFED', $cfgFile);
   }

  remove_tmp_dir($tmpDir);
}


***REMOVED*** Checks to see if any of the package names in a given list
***REMOVED*** are currently installed by RPM on the system.
***REMOVED*** @param - A list of RPM packages to check for.
***REMOVED*** @returns - A list of the installed RPM packages that this
***REMOVED***            function checked for and found (if any).
***REMOVED***
sub checkRPMForPackages {
   my @pkgList = @_;
   my @instPkgs;
   my $rpmBin = internal_which('rpm');
   my $cmd = join(' ', $rpmBin, '-qa --queryformat \'%{NAME}\n\'');

   if (-x $rpmBin) {
      open(OUTPUT, "$cmd |");
      foreach my $instPkgName (<OUTPUT>) {
	 chomp $instPkgName;
	 foreach my $pkgName (@pkgList) {
	    if ($pkgName eq $instPkgName) {
	       push @instPkgs, $instPkgName;
	    }
	 }
      }
   }
   return @instPkgs
}

***REMOVED*** Attempts to remove the given list of RPM packages
***REMOVED*** @param - List of rpm packages to remove
***REMOVED*** @returns - -1 if there was an internal error, otherwise
***REMOVED***            the return value of RPM
***REMOVED***
sub removeRPMPackages {
   my @pkgList = @_;
   my $rpmBin = internal_which('rpm');
   my @cmd = (("$rpmBin", '-e'), @pkgList);

   if (-x $rpmBin) {
      return system(@cmd);
   } else {
      return -1;
   }
}


***REMOVED******REMOVED***
***REMOVED*** locate_upstart_jobinfo
***REMOVED***
***REMOVED*** Determine whether Upstart is supported, and if so, return the path in which
***REMOVED*** Upstart jobs should be installed and any job file suffix.
***REMOVED***
***REMOVED*** @retval ($path, $suffix) Path containing Upstart jobs, job suffix (ex: .conf).
***REMOVED*** @retval ()               Upstart unsupported or unable to determine job path.
***REMOVED***

sub locate_upstart_jobinfo() {
   my $initctl = internal_which('initctl');
   my $retval;
   ***REMOVED*** Don't bother checking directories unless initctl is available and
   ***REMOVED*** indicates that Upstart is active.
   if ($initctl ne '' and ( -x $initctl )) {
      my $initctl_version_string = direct_command(shell_string($initctl) . " version");
      if (($initctl_version_string =~ /upstart ([\d\.]+)/) and
          ***REMOVED*** XXX Fix dot_version_compare to support a comparison like 0.6.5 to 0.6.
          (dot_version_compare($1, "0.6.0") >= 0)) {
         my $jobPath = "/etc/init";
         if ( -d $jobPath ) {
            my $suffix = "";

            foreach my $testSuffix (".conf") {
               if (glob ("$jobPath/*$testSuffix")) {
                  $suffix = $testSuffix;
                  last;
               }
            }

            return ($jobPath, $suffix);
         }
      }
   }

   return ();
}


***REMOVED******REMOVED***
***REMOVED*** vmware_service_basename
***REMOVED***
***REMOVED*** Simple product name -> service script map accessor.  (See
***REMOVED*** $cProductServiceTable.)
***REMOVED***
***REMOVED*** @return Service script basename on valid product, undef otherwise.
***REMOVED***
sub vmware_service_basename {
   return $cProductServiceTable{vmware_product()};
}


***REMOVED******REMOVED***
***REMOVED*** vmware_service_path
***REMOVED***
***REMOVED*** @return Valid service script's path relative to INITSCRIPTSDIR unless
***REMOVED*** vmware_product() has no such script.
***REMOVED***

sub vmware_service_path {
   my $basename = vmware_service_basename();

   return $basename
      ? join('/', db_get_answer('INITSCRIPTSDIR'), $basename)
      : undef;
}


***REMOVED******REMOVED***
***REMOVED*** vmware_service_issue_command
***REMOVED***
***REMOVED*** Executes a VMware services script, determined by locations database contents
***REMOVED*** and product type, with a single command parameter.
***REMOVED***
***REMOVED*** @param[in] $useSystem If true, uses system().  Else uses direct_command().
***REMOVED*** @param[in] @commands  List of commands passed to services script or initctl
***REMOVED***                       (ex: start, stop, status vm).
***REMOVED***
***REMOVED*** @returns Return value from system() or direct_command().
***REMOVED***

sub vmware_service_issue_command {
   my $useSystem = shift;
   my @argv;
   my @escapedArgv;
   my $cmd;

   ***REMOVED*** Upstart/initctl case.
   if (db_get_answer_if_exists('UPSTARTJOB')) {
      my $service = vmware_service_basename();
      my $initctl = internal_which('initctl');

      error("ASSERT: Failed to determine my service name.\n") unless defined $service;

      @argv = ($initctl, @_, $service);

   ***REMOVED*** Legacy SYSV style.
   } else {
      @argv = (vmware_service_path(), @_);
   }

   ***REMOVED*** Escape parameters, then join by a single space.
   foreach (@argv) {
      push(@escapedArgv, shell_string($_));
   }
   $cmd = join(' ', @escapedArgv);

   return $useSystem ? system($cmd) : direct_command($cmd);
}


***REMOVED******REMOVED***
***REMOVED*** does_solaris_package_exist
***REMOVED***
***REMOVED*** Executes a system call to check if the given package (passed in as
***REMOVED*** a parameter) exists.
***REMOVED***
***REMOVED*** @param[in] $packageName
***REMOVED***
***REMOVED*** @returns 1 (true) if package exists, 0 (false) otherwise
***REMOVED***

sub does_solaris_package_exist {
   my $packageName = shift;

   system("pkginfo $packageName > /dev/null 2>&1");
   return $? == 0 ? 1 : 0;
}

***REMOVED******REMOVED***
***REMOVED*** is_esx_virt_env
***REMOVED***
***REMOVED*** Returns true if the VM is runing in an ESX virtual environment,
***REMOVED*** false otherwise.
***REMOVED*** @returns - 1 (true) if in ESX, 0 (false) otherwise
***REMOVED***
sub is_esx_virt_env {
   my $ans = 0;
   my $sbinDir = db_get_answer('SBINDIR');
   my $checkvm = join('/', $sbinDir, 'vmware-checkvm');

   if (-x $checkvm) {
      my $output = `$checkvm -p 2>&1`;
      $ans = 1 if ($output =~ m/ESX Server/);
   }

   return $ans;
}

***REMOVED******REMOVED***
***REMOVED*** disable_module
***REMOVED***
***REMOVED*** Sets the appropriate flags to disable the module.
***REMOVED*** @returns - Nothing useful.
***REMOVED***
sub disable_module {
   my $mod = shift;

   set_manifest_component("$mod", 'FALSE');
   db_add_answer(uc("$mod") . '_CONFED', 'no');

   return;
}


***REMOVED******REMOVED***
***REMOVED*** getKernRel
***REMOVED***
***REMOVED*** Returns the release of the kernel in question.  Defaults to the
***REMOVED*** running kernel unless the user has set the --kernel-version option.
***REMOVED***
sub getKernRel {
   if ($gOption{'kernel_version'} ne '') {
      return $gOption{'kernel_version'};
   } else {
      return $gSystem{'uts_release'};
   }
}


***REMOVED******REMOVED***
***REMOVED*** getModDBKey
***REMOVED***
***REMOVED*** Creates and returns the DB key for a module based on a little
***REMOVED*** system information
***REMOVED***
sub getModDBKey {
   my $modName = shift;
   my $tag = shift;
   my $kernel = getKernRel();

   ***REMOVED*** Remove non alpha-numeric characters
   $kernel =~ s/[\.\-\+]//g;
   my $key = join('_', uc($modName), $kernel, $tag);

   return $key;
}


***REMOVED******REMOVED***
***REMOVED*** removeDuplicateEntries
***REMOVED***
***REMOVED*** Removes duplicate entries from a given string and delimeter
***REMOVED*** @param - string to cleanse
***REMOVED*** @param - the delimeter
***REMOVED*** @returns - String without duplicate entries.
***REMOVED***
sub removeDuplicateEntries {
   my $string = shift;
   my $delim = shift;
   my $newStr = '';

   if (not defined $string or not defined $delim) {
      error("Missing parameters in removeDuplicateEntries\n.");
   }

   foreach my $subStr (split($delim, $string)) {
      if ($newStr !~ /(^|$delim)$subStr($delim|$)/ and $subStr ne '') {
	 if ($newStr ne '') {
	    $newStr = join($delim, $newStr, $subStr);
	 } else {
	    $newStr = $subStr;
	 }
      }
   }

   return $newStr;
}


***REMOVED******REMOVED***
***REMOVED*** addEntDBList
***REMOVED***
***REMOVED*** Adds an entry to a list within the DB.  This function also removes
***REMOVED*** duplicate entries from the list.
***REMOVED***
sub addEntDBList {
   my $dbKey = shift;
   my $ent = shift;

   if (not defined $dbKey or $dbKey eq '') {
      error("Bad dbKey value in addEntDBList.\n");
   }

   if ($ent =~ m/,/) {
      error("New list entry can not contain commas.\n");
   }

   my $list = db_get_answer_if_exists($dbKey);
   my $newList = $list ? join(',', $list, $ent) : $ent;
   $newList = removeDuplicateEntries($newList, ',');
   db_add_answer($dbKey, $newList);
}


***REMOVED******REMOVED***
***REMOVED*** internalMv
***REMOVED***
***REMOVED*** mv command for Perl that works across file system boundaries.  The rename
***REMOVED*** function may not work across FS boundaries and I don't want to introduce
***REMOVED*** a dependency on File::Copy (at least not with this installer/configurator).
***REMOVED***
sub internalMv {
   my $src = shift;
   my $dst = shift;
   return system("mv $src $dst");
}


***REMOVED******REMOVED***
***REMOVED*** addTextToKVEntryInFile
***REMOVED***
***REMOVED*** Despite the long and confusing function name, this function is very
***REMOVED*** useful.  If you have a key value entry in a file, this function will
***REMOVED*** allow you to add an entry to it based on a special regular expression.
***REMOVED*** This regular expression must capture the pre-text, the values, and any
***REMOVED*** post text by using regex back references.
***REMOVED*** @param - Path to file
***REMOVED*** @param - The regular expression.  See example below...
***REMOVED*** @param - The delimeter between values
***REMOVED*** @param - The new entry
***REMOVED*** @returns - 1 if the file was modified, 0 otherwise.
***REMOVED***
***REMOVED*** For example, if I have
***REMOVED***   foo = 'bar,baz';
***REMOVED*** I can add 'biz' to the values by calling this function with the proper
***REMOVED*** regex.  A regex for this would look like '^(foo = ')(\.*)(;)$'.  The
***REMOVED*** delimeter is ',' and the entry would be 'biz'.  The result should look
***REMOVED*** like
***REMOVED***   foo = 'bar,baz,biz';
***REMOVED***
***REMOVED*** NOTE1:  This function will only add to the first KV pair found.
***REMOVED***
sub addTextToKVEntryInFile {
   my $file = shift;
   my $regex = shift;
   my $delim = shift;
   my $entry = shift;
   my $modified = 0;
   my $firstPart;
   my $origValues;
   my $newValues;
   my $lastPart;

   $regex = qr/$regex/;

   if (not open(INFILE, "<$file")) {
      error("addTextToKVEntryInFile: File $file not found\n");
   }

   my $tmpDir = make_tmp_dir('vmware-file-mod');
   my $tmpFile = join('/', $tmpDir, 'new-file');
   if (not open(OUTFILE, ">$tmpFile")) {
      error("addTextToKVEntryInFile: Failed to open output file\n");
   }

   foreach my $line (<INFILE>) {
      if ($line =~ $regex and not $modified) {
         ***REMOVED*** We have a match.  $1 and $2 have to be deifined; $3 is optional
         if (not defined $1 or not defined $2) {
            error("addTextToKVEntryInFile: Bad regex.\n");
         }
         $firstPart = $1;
         $origValues = $2;
         $lastPart = ((defined $3) ? $3 : '');
         chomp $firstPart;
         chomp $origValues;
         chomp $lastPart;

         ***REMOVED*** Modify the origValues and remove duplicates
         ***REMOVED*** Handle white space as well.
         if ($origValues =~ /^\s*$/) {
            $newValues = $entry;
         } else {
            $newValues = join($delim, $origValues, $entry);
            $newValues = removeDuplicateEntries($newValues, $delim);
         }
         print OUTFILE join('', $firstPart, $newValues, $lastPart, "\n");

         $modified = 1;
      } else {
         print OUTFILE $line;
      }
   }

   close(INFILE);
   close(OUTFILE);

   return 0 unless (internalMv($tmpFile, $file) eq 0);
   remove_tmp_dir($tmpDir);

   ***REMOVED*** Our return status is 1 if successful, 0 if nothing was added.
   return $modified;
}


***REMOVED******REMOVED***
***REMOVED*** removeTextInKVEntryInFile
***REMOVED***
***REMOVED*** Does exactly the opposite of addTextToKVEntryFile.  It will remove
***REMOVED*** all instances of the text entry in the first KV pair that it finds.
***REMOVED*** @param - Path to file
***REMOVED*** @param - The regular expression.  See example above...
***REMOVED*** @param - The delimeter between values
***REMOVED*** @param - The entry to remove
***REMOVED*** @returns - 1 if the file was modified, 0 otherwise.
***REMOVED***
***REMOVED*** NOTE1:  This function will only remove from the first KV pair found.
***REMOVED***
sub removeTextInKVEntryInFile {
   my $file = shift;
   my $regex = shift;
   my $delim = shift;
   my $entry = shift;
   my $modified = 0;
   my $firstPart;
   my $origValues;
   my $newValues = '';
   my $lastPart;

   $regex = qr/$regex/;

   if (not open(INFILE, "<$file")) {
      error("removeTextInKVEntryInFile:  File $file not found\n");
   }

   my $tmpDir = make_tmp_dir('vmware-file-mod');
   my $tmpFile = join('/', $tmpDir, 'new-file');
   if (not open(OUTFILE, ">$tmpFile")) {
      error("removeTextInKVEntryInFile:  Failed to open output file $tmpFile\n");
   }

   foreach my $line (<INFILE>) {
      if ($line =~ $regex and not $modified) {
         ***REMOVED*** We have a match.  $1 and $2 have to be deifined; $3 is optional
         if (not defined $1 or not defined $2) {
            error("removeTextInKVEntryInFile:  Bad regex.\n");
         }
         $firstPart = $1;
         $origValues = $2;
         $lastPart = ((defined $3) ? $3 : '');
         chomp $firstPart;
         chomp $origValues;
         chomp $lastPart;

         ***REMOVED*** Modify the origValues and remove duplicates
         ***REMOVED*** If $origValues is just whitespace, no need to modify $newValues.
         if ($origValues !~ /^\s*$/) {
            foreach my $existingEntry (split($delim, $origValues)) {
               if ($existingEntry ne $entry) {
                  if ($newValues eq '') {
                     $newValues = $existingEntry; ***REMOVED*** avoid adding unnecessary whitespace
                  } else {
                     $newValues = join($delim, $newValues, $existingEntry);
                  }
               }
            }
         }
         print OUTFILE join('', $firstPart, $newValues, $lastPart, "\n");

         $modified = 1;
      } else {
         print OUTFILE $line;
      }
   }

   close(INFILE);
   close(OUTFILE);

   return 0 unless (internalMv($tmpFile, $file));
   remove_tmp_dir($tmpDir);

   ***REMOVED*** Our return status is 1 if successful, 0 if nothing was added.
   return $modified;
}
***REMOVED*** END_OF_UTIL_DOT_PL


***REMOVED*** Constants
my $cKernelModuleDir = '/lib/modules';
my $cTmpDirPrefix = 'vmware-config';
my $cConnectSocketDir = '/var/run/vmware';
my $cVixProductName = ' VMware VIX API';
my $machine = 'host';
my $os = 'host';
if (vmware_product() eq 'server') {
  $machine = 'machine';
  $os = "Console OS";
}
my $cServices = '/etc/services';

my $cNetmapConf = '/etc/vmware/netmap.conf';

my $cConfiguratorFileName = 'vmware-config.pl';
my $cNICAlias = 'vmnics';

if (vmware_product() eq 'tools-for-linux' ||
    vmware_product() eq 'tools-for-freebsd' ||
    vmware_product() eq 'tools-for-solaris') {
  $cConfiguratorFileName = 'vmware-config-tools.pl';
}

my $cModulesBuildEnv;
if (vmware_product() eq 'tools-for-solaris') {
  $cModulesBuildEnv = ' please upgrade to a newer Solaris release.';
} else {
  $cModulesBuildEnv = ' you can install the driver by running '
                      . $cConfiguratorFileName
                      . ' again after making sure that gcc, binutils, make '
                      . 'and the kernel sources for your running kernel are '
                      . 'installed on your machine. These packages are '
                      . 'available on your distribution\'s installation CD.';
}

***REMOVED*** kernels to avoid when rmmod'ing pcnet32
my %cPCnet32KernelBlacklist = (
                          '2.4.2'  => 'yes',
                          '2.4.9'  => 'yes',
                          '2.6.0'  => '-test',
                          '2.6.0'  => '-test5_2',
                          '2.6.16' => '.13-4-default',
                          '2.6.8'  => '-1',
                          );

my $cDirExists = '1';
my $cCreateDirSuccess = '0';
my $cCreateDirFailure = '-1';

***REMOVED***
***REMOVED*** Global variables
***REMOVED***
my $gRegistryDir;
my $gStateDir;
my $gInstallerMainDB;
my $gConfFlag;
my $gLogDir;
my $gGccPath;
my $gKernelHeaders;
my @gManifestNames;
my @gManifestVersions;
my @gManifestInstFlags;
my @gRamdiskModules;
***REMOVED*** List of all ethernet adapters on the system
my @gAllEthIf;
***REMOVED*** List of ethernet adapters that have not been bridged
my @gAvailEthIf;
***REMOVED*** By convention, vmnet1 is the virtual ethernet interface connected to the
***REMOVED*** private virtual network that Samba uses.  We are also reserving vmnet0
***REMOVED*** for bridged networks.  These are reserved vmnets.
my $gDefBridged = '0';
my $gDefHostOnly = '1';
my $gDefNat = '8';
***REMOVED*** Reserved vmnets
my @gReservedVmnet = ($gDefBridged, $gDefHostOnly, $gDefNat);
***REMOVED*** Constant defined as the smallest vmnet that is allowed
my $gMinVmnet = '0';
***REMOVED*** Constant defined as the largest vmnet that is allowed
***REMOVED*** Although 256 are supported, ***REMOVED***255 is reserved
***REMOVED*** Note: Max length of interface name is 8
my $gMaxVmnet = '254';
***REMOVED*** Constant defines as the number of vmnets to be pre-created
my $gNumVmnet = 10;
my $gFirstModuleBuild = 1;
my $gCanCompileModules = 0;
my $gDefaultAuthdPort = 902;
my @gDefaultHttpProxy = (8222, 80);
my @gDefaultHttpSProxy = (8333, 443);
***REMOVED*** BEGINNING OF THE SECOND LIBRARY FUNCTIONS
***REMOVED*** Global variables
my %gDBAnswer;
my %gDBFile;
my %gDBDir;
my %gDBUserFile;
my $cBackupExtension = '.BeforeVMwareToolsInstall';
my $cRestorePrefix = 'RESTORE_';
my $cRestoreBackupSuffix = '_BAK';
my $cRestoreBackList = 'RESTORE_BACK_LIST';
my $cSwitchedToHost = 'SWITCHED_TO_HOST';
my $cXModulesDir = '/usr/X11R6/lib/modules';
my $cX64ModulesDir = '/usr/X11R6/lib64/modules';
my $gXMouseDriverFile = '';
my $gXVideoDriverFile = '';
my $gIs64BitX = 0;
my $gSavedPath = $ENV{'PATH'};
my $gNoXDrivers = 0;
my @gSuspectedFontLocations = ('/usr/share/fonts',
   '/usr/lib/X11/fonts', '/usr/lib64/X11/fonts');
my $useApploader = (vmware_product() eq 'tools-for-linux');

***REMOVED*** Solaris forced libs for toolbox-gtk
***REMOVED*** 5.10 -> Solaris 10
***REMOVED*** 5.11 -> Solaris 11
my %gSolarisToolboxGtkForcedLibs = (
   '5.10' => 'libpng12.so.0 libglib-2.0.so.0 libgmodule-2.0.so.0',
   '5.11' => '',
    );


***REMOVED*** Load the installer database
sub db_load {
  undef %gDBAnswer;
  undef %gDBFile;
  undef %gDBDir;

  if (not open(INSTALLDB, '<' . $gInstallerMainDB)) {
    error('Unable to open the installer database ' . $gInstallerMainDB
          . ' in read-mode.' . "\n\n");
  }
  while (<INSTALLDB>) {
    chomp;
    if (/^answer (\S+) (.+)$/) {
      $gDBAnswer{$1} = $2;
    } elsif (/^answer (\S+)/) {
      $gDBAnswer{$1} = '';
    } elsif (/^remove_answer (\S+)/) {
      delete $gDBAnswer{$1};
    } elsif (/^file (.+) (\d+)$/) {
      $gDBFile{$1} = $2;
    } elsif (/^file (.+)$/) {
      $gDBFile{$1} = 0;
    } elsif (/^modified (.+)$/) {
      if (defined $gDBFile{$1}) {
         $gDBUserFile{$1} = 0;
      }
    } elsif (/^remove_file (.+)$/) {
      delete $gDBFile{$1};
      delete $gDBUserFile{$1}; ***REMOVED*** harmless if not in there
    } elsif (/^directory (.+)$/) {
      $gDBDir{$1} = '';
    } elsif (/^remove_directory (.+)$/) {
      delete $gDBDir{$1};
    }
  }
  close(INSTALLDB);
}

***REMOVED*** Open the database on disk in append mode
sub db_append {
  if (not open(INSTALLDB, '>>' . $gInstallerMainDB)) {
    error('Unable to open the installer database ' . $gInstallerMainDB
          . ' in append-mode.' . "\n\n");
  }
  ***REMOVED*** Force a flush after every write operation.
  ***REMOVED*** See 'Programming Perl' 3rd edition, p. 781 (p. 110 in an older edition)
  select((select(INSTALLDB), $| = 1)[0]);
}

***REMOVED*** Add a file to the tar installer database
***REMOVED*** flags:
***REMOVED***  0x1 - write time stamp ($cFlagTimestamp)
***REMOVED***  0x2 - is config file ($cFlagConfig)
***REMOVED***  0x8 - is user-modified file ($cFlagUserModified)
sub db_add_file {
  my $file = shift;
  my $flags = shift;

  if ($flags & $cFlagTimestamp) {
    my @statbuf;

    @statbuf = stat($file);
    if (not (defined($statbuf[9]))) {
      error('Unable to get the last modification timestamp of the destination '
            . 'file ' . $file . '.' . "\n\n");
    }

    $gDBFile{$file} = $statbuf[9];
    print INSTALLDB 'file ' . $file . ' ' . $statbuf[9] . "\n";
  } else {
    $gDBFile{$file} = 0;
    print INSTALLDB 'file ' . $file . "\n";
  }

  if ($flags & $cFlagUserModified) {
    print INSTALLDB 'modified ' . $file . "\n";
    $gDBUserFile{$file} = 0;
  }

  if ($flags & $cFlagConfig) {
    print INSTALLDB 'config ' . $file . "\n";
  }
}

***REMOVED*** Mark a file as modified without changing it.
sub db_set_userfile {
   my $file = shift;

   if (!db_userfile_in($file)) {
      print INSTALLDB 'modified ' . $file . "\n";
      $gDBUserFile{$file} = 0;
   }
}

***REMOVED*** Remove a file from the tar installer database
sub db_remove_file {
  my $file = shift;

  print INSTALLDB 'remove_file ' . $file . "\n";
  delete $gDBFile{$file};
  delete $gDBUserFile{$file};
}

***REMOVED*** Remove a directory from the tar installer database
sub db_remove_dir {
  my $dir = shift;

  print INSTALLDB 'remove_directory ' . $dir . "\n";
  delete $gDBDir{$dir};
}

***REMOVED*** Determine if a file belongs to the tar installer database
sub db_file_in {
  my $file = shift;

  return defined($gDBFile{$file});
}

***REMOVED*** Determine if a directory belongs to the tar installer database
sub db_dir_in {
  my $dir = shift;

  return defined($gDBDir{$dir});
}

***REMOVED*** Determine if a directory belongs to the tar installer database
sub db_userfile_in {
  my $file = shift;

  return defined($gDBUserFile{$file});
}

***REMOVED*** Return the timestamp of an installed file
sub db_file_ts {
  my $file = shift;

  return $gDBFile{$file};
}

***REMOVED*** Remove the timestamp data for a file.
sub db_remove_ts {
  my $file = shift;
  db_remove_file($file);
  db_add_file($file, 0);
}

***REMOVED*** Reset the timestamp data for a file.
sub db_update_ts {
  my $file = shift;
  db_remove_file($file);
  db_add_file($file, 1);
}

***REMOVED*** Add a directory to the tar installer database
sub db_add_dir {
  my $dir = shift;

  $gDBDir{$dir} = '';
  print INSTALLDB 'directory ' . $dir . "\n";
}

***REMOVED*** Remove an answer from the tar installer database
sub db_remove_answer {
  my $id = shift;

  if (defined($gDBAnswer{$id})) {
    print INSTALLDB 'remove_answer ' . $id . "\n";
    delete $gDBAnswer{$id};
  }
}

***REMOVED*** Add an answer to the tar installer database
sub db_add_answer {
  my $id = shift;
  my $value = shift;

  db_remove_answer($id);
  $gDBAnswer{$id} = $value;
  print INSTALLDB 'answer ' . $id . ' ' . $value . "\n";
}

***REMOVED*** Retrieve an answer that must be present in the database
sub db_get_answer {
  my $id = shift;

  if (not defined($gDBAnswer{$id})) {
    error('Unable to find the answer ' . $id . ' in the installer database ('
          . $gInstallerMainDB . ').  You may want to re-install '
          . vmware_product_name() . ".\n\n");
  }

  return $gDBAnswer{$id};
}


***REMOVED*** Retrieves an answer if it exists in the database, else returns undef;
sub db_get_answer_if_exists {
  my $id = shift;
  if (not defined($gDBAnswer{$id})) {
    return undef;
  }
  if ($gDBAnswer{$id} eq '') {
    return undef;
  }
  return $gDBAnswer{$id};
}

***REMOVED*** Save the tar installer database
sub db_save {
  close(INSTALLDB);
}
***REMOVED*** END OF THE SECOND LIBRARY FUNCTIONS

***REMOVED*** BEGINNING OF THE LIBRARY FUNCTIONS
***REMOVED*** Global variables
my %gAnswerSize;
my %gCheckAnswerFct;

***REMOVED*** Tell if the user is the super user
sub is_root {
  return $> == 0;
}

***REMOVED*** Contrary to a popular belief, 'which' is not always a shell builtin command.
***REMOVED*** So we cannot trust it to determine the location of other binaries.
***REMOVED*** Moreover, SuSE 6.1's 'which' is unable to handle program names beginning with
***REMOVED*** a '/'...
***REMOVED***
***REMOVED*** Return value is the complete path if found, or '' if not found
sub internal_which {
  my $bin = shift;
  my $useSavedPath = shift;     ***REMOVED*** (optional, bool) Define this if you'd like to
                                ***REMOVED*** look around using the user's original PATH.
  my $appendPaths = shift;      ***REMOVED*** (optional, array ref) Define this if you'd like
                                ***REMOVED*** to append custom directories to $gSavedPath or
                                ***REMOVED*** $ENV{'PATH'}.

  if (substr($bin, 0, 1) eq '/') {
    ***REMOVED*** Absolute name
    if ((-f $bin) && (-x $bin)) {
      return $bin;
    }
  } else {
    ***REMOVED*** Relative name
    my @paths;
    my $path;

    if (index($bin, '/') == -1) {
      ***REMOVED*** There is no other '/' in the name
      @paths = split(':', $useSavedPath ? $gSavedPath : $ENV{'PATH'});
      @paths = (@paths, @{$appendPaths}) if defined $appendPaths;
      foreach $path (@paths) {
         my $fullbin;

         $fullbin = $path . '/' . $bin;
         if ((-f $fullbin) && (-x $fullbin)) {
               return $fullbin;
         }
      }
    }
  }

  return '';
}

***REMOVED*** Check the validity of an answer whose type is yesno
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_binpath {
  my $answer = shift;
  my $source = shift;

  my $fullpath = internal_which($answer);
  if (not ("$fullpath" eq '')) {
    return $fullpath;
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid.  It must be the '
               . 'complete name of a binary file.' . "\n\n", 0);
  }
  return '';
}
$gAnswerSize{'binpath'} = 20;
$gCheckAnswerFct{'binpath'} = \&check_answer_binpath;

***REMOVED*** Prompts the user if a binary is not found
***REMOVED*** Return value is:
***REMOVED***  '': the binary has not been found
***REMOVED***  the binary name if it has been found
sub DoesBinaryExist_Prompt {
  my $bin = shift;
  my $answer;
  my $prefix = 'BIN_';

  $answer = check_answer_binpath($bin, 'default');
  if ($answer ne '') {
    return $answer;
  } else {
    if (defined db_get_answer_if_exists($prefix . $bin)) {
      return db_get_answer($prefix . $bin);
    }
  }

  if (get_answer('Setup is unable to find the "' . $bin . '" program on your '
                 . 'machine.  Please make sure it is installed.  Do you want '
                 . 'to specify the location of this program by hand?', 'yesno',
                 'yes') eq 'no') {
    return '';
  }

  $answer = get_answer('What is the location of the "' . $bin . '" program on '
		       . 'your machine?', 'binpath', '');
  if ($answer ne '' &&
      not defined db_get_answer_if_exists($prefix . $bin)) {
    db_add_answer($prefix . $bin, $answer);
  }
  return $answer;
}

***REMOVED*** chown() that reports errors.
sub safe_chown {
  my $uid = shift;
  my $gid = shift;
  my $file = shift;

  if (chown($uid, $gid, $file) != 1) {
    error('Unable to change the owner of the file ' . $file . '.'
          . "\n\n");
  }
}

***REMOVED*** Install a file permission
sub install_permission {
  my $src = shift;
  my $dst = shift;
  my @statbuf;

  @statbuf = stat($src);
  if (not (defined($statbuf[2]))) {
    error('Unable to get the access rights of source file "' . $src . '".'
          . "\n\n");
  }
  safe_chmod($statbuf[2] & 07777, $dst);
}

***REMOVED*** Emulate a simplified sed program
***REMOVED*** Return 1 if success, 0 if failure
***REMOVED*** XXX as a side effect, if the string being replaced is '', remove
***REMOVED*** the entire line.  Remove this, once we have better "block handling" of
***REMOVED*** our config data in config files.
sub internal_sed {
  my $src = shift;
  my $dst = shift;
  my $append = shift;
  my $patchRef = shift;
  my @patchKeys;

  if (not open(SRC, '<' . $src)) {
    return 0;
  }
  if (not open(DST, (($append == 1) ? '>>' : '>') . $dst)) {
    return 0;
  }

  @patchKeys = keys(%$patchRef);
  if ($***REMOVED***patchKeys == -1) {
    while (defined($_ = <SRC>)) {
      print DST $_;
    }
  } else {
    while (defined($_ = <SRC>)) {
      my $patchKey;
      my $del = 0;

      foreach $patchKey (@patchKeys) {
        if (s/$patchKey/$$patchRef{$patchKey}/g) {
          if ($_ eq "\n") {
            $del = 1;
          }
        }
      }
      if ($del) {
        next;
      }
      print DST $_;
    }
  }

  close(SRC);
  close(DST);
  return 1;
}

***REMOVED*** Check if a file name exists
sub file_name_exist {
  my $file = shift;

  ***REMOVED*** Note: We must test for -l before, because if an existing symlink points to
  ***REMOVED***       a non-existing file, -e will be false
  return ((-l $file) || (-e $file))
}

***REMOVED*** Check if a file name already exists and prompt the user
***REMOVED*** Return 0 if the file can be written safely, 1 otherwise
sub file_check_exist {
  my $file = shift;

  if (not file_name_exist($file)) {
    return 0;
  }

  ***REMOVED*** The default must make sure that the product will be correctly installed
  ***REMOVED*** We give the user the choice so that a sysadmin can perform a normal
  ***REMOVED*** install on a NFS server and then answer 'no' NFS clients
  return (get_answer('The file ' . $file . ' that this program was about to '
                     . 'install already exists.  Overwrite?', 'yesno', 'yes')
            eq 'yes') ? 0 : 1;
}

***REMOVED***
***REMOVED*** Set file contents
***REMOVED***
sub set_file_contents {
  my $file = shift;
  my $contents = shift;

  ***REMOVED*** Open the file w/ overwrite
  open (OUTFILE, ">" . $file);
  print OUTFILE $contents;
  close (OUTFILE);
}

***REMOVED*** Returns 1 if a file has changed with respect to its timestamp in the database,
***REMOVED*** 0 otherwise
sub file_changed_db_ts {
   my $file = shift;
   my @statbuf;

   ***REMOVED*** This doesn't matter if (a) file doesn't exist, (b) doesn't have a
   ***REMOVED*** timestamp anyway or (c) the timestamp is zero. Usually (b) and (c)
   ***REMOVED*** are equivalent but the use is undefined.
   if (!file_name_exist($file)) {
      return 0;
   }

   if (!defined(db_file_ts($file)) || db_file_ts($file) == 0) {
      return 0;
   }

   @statbuf = stat($file);
   if (defined($statbuf[9])) {
      return (db_file_ts($file) != $statbuf[9]);
   } else {
      error('Unable to get the last modification timestamp of the destination '
            . 'file ' . $file . '.' . "\n\n");
      return 0;
   }
}

***REMOVED*** Install one file
***REMOVED*** flags are forwarded to db_add_file()
sub install_file {
  my $src = shift;
  my $dst = shift;
  my $patchRef = shift;
  my $flags = shift;

  ***REMOVED*** If we are installing a config file and such a config file already exists
  ***REMOVED*** AND it has changed timestamp with regards to the DB,
  ***REMOVED*** OR
  ***REMOVED*** it's marked as a user-modified config file...
  if (($flags & $cFlagConfig) && file_name_exist($dst)) {
      if (db_userfile_in($dst)) {
         ***REMOVED*** Note the default choice. We should not require users to pass
         ***REMOVED*** a command line option to preserve userfiles. That should be the
         ***REMOVED*** default.
         my $default = ($gOption{'overwrite'} ? 'no' : 'yes');
         my $rv = get_answer('You have previously modified the configuration '
                           . 'file ' . $dst . ' and chosen to keep your '
                           . 'version.  Would you still like to keep it '
                           . 'instead of having this program create a new '
                           . 'version?', 'yesno', $default);

         if ($rv eq 'yes') {
            return;
         }
      } elsif (file_changed_db_ts($dst)) {
         ***REMOVED*** When this branch is reached, we default to clobbering unless
         ***REMOVED*** --preserve is used.
         my $default = ($gOption{'preserve'} ? 'yes' : 'no');
         my $rv = get_answer('The configuration file ' . $dst . ' already '
          . 'exists and has been modified (possibly by you) since the '
          . 'last install. Would you like to keep your version of the '
          . 'file instead of installing a new one?', 'yesno', $default);

         if ($rv eq 'yes') {
            db_remove_file($dst);
            db_set_userfile($dst);
            print wrap("Note that you may need to change this configuration "
                  . "file yourself. For example, if you reconfigure your "
                  . "networking settings using this script, and choose to keep "
                  . "your version of a configuration file, you may need to "
                  . "update it to reflect the new layout of the network."
                  . "\n\n", 0);

            return;
         }
      }
  }


  ***REMOVED*** Well, if that's not true, just clobber it, whatever it is or was.
  ***REMOVED*** Doing this will also undo its userfile status.
  uninstall_file($dst);
  if (file_check_exist($dst)) {
    return;
  }
  ***REMOVED*** The file could be a symlink to another location.  Remove it
  unlink($dst);
  if (not internal_sed($src, $dst, 0, $patchRef)) {
    error('Unable to copy the source file ' . $src . ' to the destination '
          . 'file ' . $dst . '.' . "\n\n");
  }
  db_add_file($dst, $flags);
  install_permission($src, $dst);
}

***REMOVED*** mkdir() that reports errors
sub safe_mkdir {
  my $file = shift;

  if (-d $file) {
    return 1;
  }

  if (mkdir($file, 0777) == 0) {
    error('Unable to create the directory ' . $file . '.' . "\n\n");
  }
  return 1;
}

***REMOVED*** Remove trailing slashes in a dir path
sub dir_remove_trailing_slashes {
  my $path = shift;

  for (;;) {
    my $len;
    my $pos;

    $len = length($path);
    if ($len < 2) {
      ***REMOVED*** Could be '/' or any other character.  Ok.
      return $path;
    }

    $pos = rindex($path, '/');
    if ($pos != $len - 1) {
      ***REMOVED*** No trailing slash
      return $path;
    }

    ***REMOVED*** Remove the trailing slash
    $path = substr($path, 0, $len - 1)
  }
}


***REMOVED*** Emulate a simplified basename program
sub internal_basename {
  return substr($_[0], rindex($_[0], '/') + 1);
}


***REMOVED*** Create a hierarchy of directories with permission 0755
***REMOVED*** flags:
***REMOVED***  0x4 - write this directory creation in the installer database
***REMOVED***        ($cFlagDirectoryMark)
***REMOVED*** Return 1 if the directory existed before
sub create_dir {
  my $dir = shift;
  my $parentDir = internal_dirname($dir);
  my $flags = shift;

  if (-d $dir) {
    return $cDirExists;
  }

  if (index($dir, '/') != -1) {
    create_dir($parentDir, $flags);
  }

  if ($flags & $cFlagFailureOK) {
    if (mkdir($dir, 0777) == 0) {
      return $cCreateDirFailure;
    }
  } else {
    safe_mkdir($dir, $flags);
  }

  if ($flags & $cFlagDirectoryMark) {
    db_add_dir($dir);
  }
  return $cCreateDirSuccess;
}

***REMOVED*** Get a valid non-persistent answer to a question
***REMOVED*** Use this when the answer shouldn't be stored in the database
sub get_answer {
  my $msg = shift;
  my $type = shift;
  my $default = shift;
  my $answer;

  if (not defined($gAnswerSize{$type})) {
    die 'get_answer(): type ' . $type . ' not implemented :(' . "\n\n";
  }
  for (;;) {
    $answer = check_answer(query($msg, $default, $gAnswerSize{$type}), $type,
                           'user');
    if ($answer ne '') {
      return $answer;
    }

    ***REMOVED*** Let the error propagate to callers
    if ($gOption{'default'} == 1) {
      return '';
    }
  }
}

***REMOVED*** Get a valid persistent answer to a question
***REMOVED*** Use this when you want an answer to be stored in the database
sub get_persistent_answer {
  my $msg = shift;
  my $id = shift;
  my $type = shift;
  my $default = shift;
  my $answer;

  if (defined($gDBAnswer{$id})) {
    ***REMOVED*** There is a previous answer in the database
    $answer = check_answer($gDBAnswer{$id}, $type, 'db');
    if ($answer ne '') {
      ***REMOVED*** The previous answer is valid.  Make it the default value
      $default = $answer;
    }
  }

  $answer = get_answer($msg, $type, $default);
  db_add_answer($id, $answer);
  return $answer;
}

***REMOVED*** Find a suitable backup name and backup a file
sub backup_file {
  my $file = shift;
  my $i;

  for ($i = 0; $i < 100; $i++) {
    if (not file_name_exist($file . '.old.' . $i)) {
      my %patch;

      undef %patch;
      if (internal_sed($file, $file . '.old.' . $i, 0, \%patch)) {
         print wrap('File ' . $file . ' is backed up to ' . $file . '.old.'
                    . $i . '.' . "\n\n", 0);
      } else {
         print STDERR wrap('Unable to backup the file ' . $file . ' to '
                           . $file . '.old.' . $i .'.' . "\n\n", 0);
      }
      return;
    }
  }

  print STDERR wrap('Unable to backup the file ' . $file . '.  You have too '
                    . 'many backups files.  They are files of the form '
                    . $file . '.old.N, where N is a number.  Please delete '
                    . 'some of them.' . "\n\n", 0);
}

***REMOVED*** Backup a file in the idea to restore it in the future.
sub backup_file_to_restore {
  my $file = shift;
  my $restoreStr = shift;
  my $backupDir = shift;         ***REMOVED*** (optional) Pass this in to backup $file to a different directory.
  my $dstFile;

  if (!defined($backupDir)) {
      $dstFile = $file . $cBackupExtension;
      $backupDir = '';
  } else {
      $dstFile = $backupDir . '/' . internal_basename($file) . $cBackupExtension;
  }

  if (file_name_exist($file) &&
      (not file_name_exist($dstFile))) {
    my %p;
    undef %p;
    rename $file, $dstFile;
    db_add_answer($cRestorePrefix . $restoreStr, $file);
    db_add_answer($cRestorePrefix . $restoreStr . $cRestoreBackupSuffix,
                  $dstFile);

    if (defined db_get_answer_if_exists($cRestoreBackList)) {
      my $allRestoreStr;
      $allRestoreStr = db_get_answer($cRestoreBackList);
      db_add_answer($cRestoreBackList,$allRestoreStr . ':' . $restoreStr);
    } else {
      db_add_answer($cRestoreBackList, $restoreStr);
    }
  }
}

***REMOVED*** XXX Duplicated in pkg_mgr.pl
***REMOVED*** format of the returned hash:
***REMOVED***          - key is the system file
***REMOVED***          - value is the backed up file.
***REMOVED*** This function should never know about filenames. Only database
***REMOVED*** operations.
sub db_get_files_to_restore {
  my %fileToRestore;
  undef %fileToRestore;

  if (defined db_get_answer_if_exists($cRestoreBackList)) {
    my $restoreStr;
    foreach $restoreStr (split(/:/, db_get_answer($cRestoreBackList))) {
      if (defined db_get_answer_if_exists($cRestorePrefix . $restoreStr)) {
        $fileToRestore{db_get_answer($cRestorePrefix . $restoreStr)} =
          db_get_answer($cRestorePrefix . $restoreStr
                        . $cRestoreBackupSuffix);
      }
    }
  }
  return %fileToRestore;
}

***REMOVED*** Uninstall a file previously installed by us
sub uninstall_file {
  my $file = shift;

  if (not db_file_in($file)) {
    ***REMOVED*** Not installed by this program
    return;
  }

  if (file_name_exist($file)) {
    if (file_changed_db_ts($file) || db_userfile_in($file)) {
      backup_file($file);
      db_remove_file($file);
      return;
    }

    if (not unlink($file)) {
      error('Unable to remove the file "' . $file . '".' . "\n");
    } else {
      db_remove_file($file);
    }

  } else {
    print wrap('This program previously created the file ' . $file . ', and '
               . 'was about to remove it.  Somebody else apparently did it '
               . 'already.' . "\n\n", 0);
    db_remove_file($file);
  }
}

***REMOVED*** Uninstall a directory previously installed by us
sub uninstall_dir {
  my $dir = shift;

  if (not db_dir_in($dir)) {
    ***REMOVED*** Not installed by this program
    return;
  }

  if (-d $dir) {
    if (not rmdir($dir)) {
      print wrap('This program previously created the directory ' . $dir . ', '
                 . 'and was about to remove it. Since there are files in that '
                 . 'directory that this program did not create, it will not be '
                 . 'removed.' . "\n\n", 0);
      if (   defined($ENV{'VMWARE_DEBUG'})
          && ($ENV{'VMWARE_DEBUG'} eq 'yes')) {
        system('ls -AlR ' . shell_string($dir));
      }
    }
  } else {
    print wrap('This program previously created the directory ' . $dir
               . ', and was about to remove it. Somebody else apparently did '
               . 'it already.' . "\n\n", 0);
  }

  db_remove_dir($dir);
}

***REMOVED*** Install one directory (recursively)
sub install_dir {
  my $src_dir = shift;
  my $dst_dir = shift;
  my $patchRef = shift;
  my $file;

  if (create_dir($dst_dir, $cFlagDirectoryMark) == $cDirExists) {
    my @statbuf;

    @statbuf = stat($dst_dir);
    if (not (defined($statbuf[2]))) {
      error('Unable to get the access rights of destination directory "' . $dst_dir . '".' . "\n\n");
    }

    ***REMOVED*** Was bug 15880
    if (   ($statbuf[2] & 0555) != 0555
        && get_answer('Current access permissions on directory "' . $dst_dir
                      . '" will prevent some users from using '
                      . vmware_product_name()
                      . '. Do you want to set those permissions properly?',
                      'yesno', 'yes') eq 'yes') {
      safe_chmod(($statbuf[2] & 07777) | 0555, $dst_dir);
    }
  } else {
    install_permission($src_dir, $dst_dir);
  }
  foreach $file (internal_ls($src_dir)) {
    if (-d $src_dir . '/' . $file) {
      install_dir($src_dir . '/' . $file, $dst_dir . '/' . $file, $patchRef);
    } else {
      install_file($src_dir . '/' . $file, $dst_dir . '/' . $file, $patchRef, $cFlagTimestamp);
    }
  }
}

***REMOVED*** Uninstall files and directories beginning with a given prefix
sub uninstall_prefix {
  my $prefix = shift;
  my $prefix_len;
  my $file;
  my $dir;

  $prefix_len = length($prefix);

  ***REMOVED*** Remove all files beginning with $prefix
  foreach $file (keys %gDBFile) {
    if (substr($file, 0, $prefix_len) eq $prefix) {
      uninstall_file($file);
    }
  }

  ***REMOVED*** Remove all directories beginning with $prefix
  ***REMOVED*** We sort them by decreasing order of their length, to ensure that we will
  ***REMOVED*** remove the inner ones before the outer ones
  foreach $dir (sort {length($b) <=> length($a)} keys %gDBDir) {
    if (substr($dir, 0, $prefix_len) eq $prefix) {
      uninstall_dir($dir);
    }
  }
}

***REMOVED*** Return the version of VMware
sub vmware_version {
  my $buildNr;

  $buildNr = '8.6.14 build-1976090';
  return remove_whitespaces($buildNr);
}

***REMOVED*** Return product name and version
sub vmware_longname {
   my $name = vmware_product_name() . ' ' . vmware_version();

   if (defined $gSystem{'system'} and
       not (vmware_product() eq 'server')) {
      $name .= ' for ' . $gSystem{'system'};
   }

   return $name;
}

***REMOVED*** Check the validity of an answer whose type is yesno
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_yesno {
  my $answer = shift;
  my $source = shift;

  if (lc($answer) =~ /^y(es)?$/) {
    return 'yes';
  }

  if (lc($answer) =~ /^n(o)?$/) {
    return 'no';
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid.  It must be one of '
               . '"y" or "n".' . "\n\n", 0);
  }
  return '';
}
$gAnswerSize{'yesno'} = 3;
$gCheckAnswerFct{'yesno'} = \&check_answer_yesno;

***REMOVED*** Check the validity of an answer based on its type
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer {
  my $answer = shift;
  my $type = shift;
  my $source = shift;

  if (not defined($gCheckAnswerFct{$type})) {
    die 'check_answer(): type ' . $type . ' not implemented :(' . "\n\n";
  }
  return &{$gCheckAnswerFct{$type}}($answer, $source);
}
***REMOVED*** END OF THE LIBRARY FUNCTIONS

***REMOVED*** Set the name of the main /etc/vmware* directory.
sub initialize_globals {

  if (vmware_product() eq 'tools-for-linux' ||
      vmware_product() eq 'tools-for-freebsd' ||
      vmware_product() eq 'tools-for-solaris') {
    $gRegistryDir = '/etc/vmware-tools';
  } else {
    $gRegistryDir = '/etc/vmware';
  }
  $gLogDir = '/var/log/vmware';
  $gStateDir = $gRegistryDir . '/state';
  $gInstallerMainDB = $gRegistryDir . '/locations';
  $gConfFlag = $gRegistryDir . '/not_configured';

  $gOption{'default'} = 0;
  $gOption{'compile'} = 0;
  $gOption{'prebuilt'} = 0;
  $gOption{'tools-switch'} = 0;
  $gOption{'clobber-xorg-modules'} = 0;
  $gOption{'preserve'} = 0;
  $gOption{'overwrite'} = 0;
  $gOption{'clobberKernelModules'} = {};
  $gOption{'skip-stop-start'} = vmware_product() eq 'server';
  $gOption{'rpc-on-end'} = 1;
  $gOption{'create_shortcuts'} = 1;
  $gOption{'modules_only'} = 0;
  $gOption{'kernel_version'} = '';
  $gOption{'install-vmwgfx'} = 0;
}

***REMOVED*** Set up the location of external helpers
sub initialize_external_helpers {
  my $program;
  my @programList;

  if (not defined($gHelper{'more'})) {
    $gHelper{'more'} = '';
    if (defined($ENV{'PAGER'})) {
      my @tokens;

      ***REMOVED*** The environment variable sometimes contains the pager name _followed by
      ***REMOVED*** a few command line options_.
      ***REMOVED***
      ***REMOVED*** Isolate the program name (we are certain it does not contain a
      ***REMOVED*** whitespace) before dealing with it.
      @tokens = split(' ', $ENV{'PAGER'});
      $tokens[0] = DoesBinaryExist_Prompt($tokens[0]);
      if (not ($tokens[0] eq '')) {
        ***REMOVED*** This is _already_ a shell string
        $gHelper{'more'} = join(' ', @tokens);
      }
    }
    if ($gHelper{'more'} eq '') {
      $gHelper{'more'} = DoesBinaryExist_Prompt('more');
      if ($gHelper{'more'} eq '') {
        error('Unable to continue.' . "\n\n");
      }
      ***REMOVED*** Save it as a shell string
      $gHelper{'more'} = shell_string($gHelper{'more'});
    }
  }

  if (vmware_product() eq 'tools-for-freebsd') {
    @programList = ('cp', 'uname', 'grep', 'ldd', 'mknod', 'kldload',
                    'kldunload', 'mv', 'rm', 'ldconfig');
  } elsif (vmware_product() eq 'tools-for-solaris') {
    ***REMOVED*** Note that svcprop(1) is added for Solaris 10 and later after it is
    ***REMOVED*** guaranteed that uname(1) has been found
    @programList = ('cp', 'uname', 'grep', 'ldd', 'mknod', 'modload', 'modinfo',
                    'modunload', 'add_drv', 'rem_drv', 'update_drv',
                    'rm', 'isainfo', 'ifconfig', 'cat', 'mv', 'sed',
                    'cut','pkginfo');
  } elsif ((vmware_product() eq 'wgs') || (vmware_product() eq 'server')) {
    @programList = ('cp', 'uname', 'grep', 'ldd', 'mknod', 'depmod', 'insmod',
                    'lsmod', 'modprobe', 'rmmod', 'ifconfig', 'rm', 'tar',
                    'killall', 'perl', 'mv', 'touch', 'hostname', 'pidof');
  } else {
    @programList = ('cp', 'uname', 'grep', 'ldd', 'mknod', 'depmod', 'insmod',
                    'lsmod', 'modprobe', 'mv', 'rmmod', 'ifconfig', 'rm',
		    'tar', 'modinfo');
  }

  foreach $program (@programList) {
    if (not defined($gHelper{$program})) {
      $gHelper{$program} = DoesBinaryExist_Prompt($program);
      if ($gHelper{$program} eq '') {
        error('Unable to continue.' . "\n\n");
      }
    }
  }

  if (vmware_product() eq 'tools-for-solaris' &&
      solaris_10_or_greater() eq 'yes') {
    $gHelper{'svcprop'} = DoesBinaryExist_Prompt('svcprop');
    if ($gHelper{'svcprop'} eq '') {
      error('Unable to continue.' . "\n\n");
    }
  }
  $gHelper{'insserv'} = internal_which('insserv');
  $gHelper{'chkconfig'} = internal_which('/sbin/chkconfig');
  $gHelper{'update-rc.d'} = internal_which('update-rc.d');
  if (vmware_product() eq 'server' &&
      $gHelper{'chkconfig'} eq '') {
         error('No initscript installer found.' . "\n\n");
  }
}

***REMOVED*** Check the validity of an answer whose type is dirpath
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_dirpath {
    my $answer = shift;
    my $source = shift;

    $answer = dir_remove_trailing_slashes($answer);

    if (substr($answer, 0, 1) ne '/') {
	print wrap('The path "' . $answer . '" is a relative path. Please enter '
		   . 'an absolute path.' . "\n\n", 0);
	return '';
    }

    if (-d $answer) {
	***REMOVED*** The path is an existing directory
	return $answer;
    }

    ***REMOVED*** The path is not a directory
    if (file_name_exist($answer)) {
	if ($source eq 'user') {
	    print wrap('The path "' . $answer . '" exists, but is not a directory.'
		       . "\n\n", 0);
	}
	return '';
    }

    ***REMOVED*** The path does not exist
    if ($source eq 'user') {
	return (get_answer('The path "' . $answer . '" does not exist currently. '
			   . 'This program is going to create it, including needed '
			   . 'parent directories. Is this what you want?',
			   'yesno', 'yes') eq 'yes') ? $answer : '';
    } else {
	return $answer;
    }
}
$gAnswerSize{'dirpath'} = 20;
$gCheckAnswerFct{'dirpath'} = \&check_answer_dirpath;


***REMOVED*** Check the validity of an answer whose type is dirpath_existing
***REMOVED*** Return an existing directory if valid, or ''
sub check_answer_dirpath_existing {
    my $answer = shift;
    my $source = shift;

    $answer = dir_remove_trailing_slashes($answer);

    if (substr($answer, 0, 1) ne '/') {
	print wrap('The path "' . $answer . '" is a relative path. Please enter '
		   . 'an absolute path.' . "\n\n", 0);
	return '';
    }

    if (-d $answer) {
	***REMOVED*** The path is an existing directory
	return $answer;
    }

    ***REMOVED*** The path is not a directory
    if (file_name_exist($answer) && ($source eq 'user')) {
      print wrap('The path "' . $answer . '" exists, but is not a directory.'
		 . "\n\n", 0);
    } else {
      ***REMOVED*** The path does not exist
      print wrap('The path "' . $answer . '" does not exist.' . "\n\n", 0);
    }
    return '';
}
$gAnswerSize{'dirpath_existing'} = 20;
$gCheckAnswerFct{'dirpath_existing'} = \&check_answer_dirpath_existing;


***REMOVED*** Check the validity of an answer whose type is headerdir
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_headerdir {
  my $answer = shift;
  my $source = shift;
  my $pattern = '@@VMWARE@@';
  my $header_version_uts;
  my $header_smp;
  my $uts_headers;

  $answer = dir_remove_trailing_slashes($answer);

  if (not (-d $answer)) {
    if ($source eq 'user') {
      print wrap('The path "' . $answer . '" is not an existing directory.'
                 . "\n\n", 0);
    }
    return '';
  }

  if ($answer =~ m|^/usr/include(/.*)?$|) { ***REMOVED***/***REMOVED*** Broken colorizer.
    if ($source eq 'user') {
      if (get_answer('The header files in /usr/include are generally for C '
                     . 'libraries, not for the running kernel. If you do not '
                     . 'have kernel header files in your /usr/src directory, '
                     . 'you probably do not have the kernel-source package '
                     . 'installed. Are you sure that /usr/include contains '
                     . 'the header files associated with your running kernel?',
                     'yesno', 'no') eq 'no') {
        return '';
      }
    }
  }

  if (not (-d $answer . '/linux')) {
    if ($source eq 'user') {
      print wrap('The path "' . $answer . '" is an existing directory, but it '
                 . 'does not contain a "linux" subdirectory as expected.'
                 . "\n\n", 0);
    }
    return '';
  }

  ***REMOVED***
  ***REMOVED*** Check that the running kernel matches the set of header files
  ***REMOVED***

  if (not (-r $answer . '/linux/version.h')) {
    if ($source eq 'user') {
      print wrap('The path "' . $answer . '" is a kernel header file '
                 . 'directory, but it does not contain the file '
                 . '"linux/version.h" as expected.  This can happen if the '
                 . 'kernel has never been built, or if you have invoked the '
                 . '"make mrproper" command in your kernel directory.  In any '
                 . 'case, you may want to rebuild your kernel.' . "\n\n", 0);
    }
    return '';
  }

  ***REMOVED***
  ***REMOVED*** Kernels before 2.6.18 declare UTS_RELEASE in version.h.  Newer kernels
  ***REMOVED*** use utsrelease.h.  We include both just in case somebody moves UTS_RELEASE
  ***REMOVED*** back while leaving utsrelease.h file in place.
  ***REMOVED***
  if ($gOption{'kernel_version'} eq '') {
    $uts_headers = "***REMOVED***include <linux/version.h>\n";
    if (-e $answer . '/linux/utsrelease.h') {
      $uts_headers .= "***REMOVED***include <linux/utsrelease.h>\n";
    }
    $header_version_uts = direct_command(
      shell_string($gHelper{'echo'}) . ' '
      . shell_string($uts_headers . $pattern
                     . ' UTS_RELEASE') . ' | ' . shell_string($gHelper{'gcc'})
      . ' ' . shell_string('-I' . $answer) . ' -E - | '
      . shell_string($gHelper{'grep'}) . ' ' . shell_string($pattern));
    chomp($header_version_uts);
    $header_version_uts =~ s/^$pattern \"([^\"]*)\".*$/$1/;
    if (not ($header_version_uts eq $gSystem{'uts_release'})) {
      if ($source eq 'user') {
        print wrap('The directory of kernel headers (version '
                   . $header_version_uts . ') does not match your running '
                   . 'kernel (version ' . $gSystem{'uts_release'} . ').  Even '
                   . 'if the module were to compile successfully, it would not '
                   . 'load into the running kernel.' . "\n\n", 0);
      }
      return '';
    }
  }

  if (not (-r $answer . '/linux/autoconf.h')) {
    if ($source eq 'user') {
      print wrap('The path "' . $answer . '" is a kernel header file '
                 . 'directory, but it does not contain the file '
                 . '"linux/autoconf.h" as expected.  This can happen if the '
                 . 'kernel has never been built, or if you have invoked the '
                 . '"make mrproper" command in your kernel directory.  In any '
                 . 'case, you may want to rebuild your kernel.' . "\n\n", 0);
    }
    return '';
  }
  $header_smp = direct_command(shell_string($gHelper{'grep'}) . ' CONFIG_SMP '
                               . shell_string($answer . '/linux/autoconf.h'));
  if (not ($header_smp eq '')) {
    ***REMOVED*** linux/autoconf.h contains the up/smp information
    $header_smp = direct_command(
      shell_string($gHelper{'echo'}) . ' '
      . shell_string('***REMOVED***include <linux/autoconf.h>' . "\n" . $pattern
                     . ' CONFIG_SMP') . ' | ' . shell_string($gHelper{'gcc'})
      . ' ' . shell_string('-I' . $answer) . ' -E - | '
      . shell_string($gHelper{'grep'}) . ' ' . shell_string($pattern));
    chomp($header_smp);
    $header_smp =~ s/^$pattern (\S+).*$/$1/;
    $header_smp = ($header_smp eq '1') ? 'yes' : 'no';
    if (not (lc($header_smp) eq lc($gSystem{'smp'}))) {
      if ($source eq 'user') {
        print wrap('The kernel defined by this directory of header files is '
                   . (($header_smp eq 'yes') ? 'multiprocessor'
                                             : 'uniprocessor') . ', while '
                   . 'your running kernel is '
                   . (($gSystem{'smp'} eq 'yes') ? 'multiprocessor'
                                                 : 'uniprocessor') . '.'
                   . "\n\n", 0);
      }
      return '';
    }
  }

  ***REMOVED***
  ***REMOVED*** For kernels before 2.6.0 require asm and net subdirectories.  And verify
  ***REMOVED*** that PAGE_OFFSET for running kernel matches one specified in kernel
  ***REMOVED*** headers.  We use our Makefiles to build kernel modules on these kernels,
  ***REMOVED*** so we know that asm and net directories must be here for successful build,
  ***REMOVED*** and PAGE_OFFSET must match.
  ***REMOVED***
  ***REMOVED*** For kernel 2.6.0 and above require ../Makefile and ../.config presence.
  ***REMOVED*** Although they could be theoretically missing, they are present on all
  ***REMOVED*** currently existing systems.  And check for ../.config presence
  ***REMOVED*** rules out /usr/src/linux/include eliminates false positive we
  ***REMOVED*** currently hit on SuSE 9.x systems.  And do not verify PAGE_OFFSET value
  ***REMOVED*** at all, asm/page.h needs special processing on 2.6.15+ kernels.
  ***REMOVED***
  if ($header_version_uts =~ /^2\.[0-5]\./) {
    if (   (not (-d $answer . '/asm'))
        || (not (-d $answer . '/net'))) {
      if ($source eq 'user') {
        print wrap('The path "' . $answer . '" is an existing directory, but it '
                   . 'does not contain subdirectories "asm" and "net" as expected.'
                   . "\n\n", 0);
      }
      return '';
    }
    if (not (-r $answer . '/asm/page.h')) {
      if ($source eq 'user') {
        print wrap('The path "' . $answer . '" is a kernel header file '
                   . 'directory, but it does not contain the file "asm/page.h" '
                   . 'as expected.' . "\n\n", 0);
      }
      return '';
    }
    my $header_page_offset = direct_command(
      shell_string($gHelper{'echo'}) . ' '
      . shell_string('***REMOVED***define __KERNEL__' . "\n" . '***REMOVED***include <asm/page.h>'
                     . "\n" . $pattern . ' __PAGE_OFFSET') . ' | '
      . shell_string($gHelper{'gcc'}) . ' ' . shell_string('-I' . $answer)
      . ' -E - | ' . shell_string($gHelper{'grep'}) . ' '
      . shell_string($pattern));
    chomp($header_page_offset);
    ***REMOVED*** Ignore PAGE_OFFSET if we cannot parse it.
    if ($header_page_offset =~ /^$pattern \(?0x([0-9a-fA-F]{8,})/) {
      ***REMOVED*** We found a valid page offset
      $header_page_offset = $1;
      if (defined($gSystem{'page_offset'}) and
          not (lc($header_page_offset) eq lc($gSystem{'page_offset'}))) {
        if ($source eq 'user') {
          print wrap('The kernel defined by this directory of header files does '
                     . 'not have the same address space size as your running '
                     . 'kernel.' . "\n\n", 0);
        }
        return '';
      }
    }
  } else {
    if (not (-r $answer . '/../Makefile')) {
      if ($source eq 'user') {
        print wrap('The path "' . $answer . '" is a kernel header file '
                   . 'directory, but it is not part of kernel source tree.'
                   . "\n\n", 0);
      }
      return '';
    }
    if (not (-r $answer . '/../.config')) {
      if ($source eq 'user') {
        print wrap('The path "' . $answer . '" is a kernel header file '
                   . 'directory, but it is not configured yet.'
                   . "\n\n", 0);
      }
      return '';
    }
  }
  return $answer;
}
$gAnswerSize{'headerdir'} = 20;
$gCheckAnswerFct{'headerdir'} = \&check_answer_headerdir;

***REMOVED*** Check the validity of an answer whose type is ip
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_ip {
  my $answer = shift;
  my $source = shift;
  my $re;

  $re = '^([0-9]|[1-9][0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))'
        . '(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))){3}$';
  ***REMOVED*** This comment fixes emacs's broken syntax highlighting
  if ($answer =~ /$re/) {
    return $answer;
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid.  It must be of the '
               . 'form a.b.c.d where a, b, c and d are decimal numbers '
               . 'between 0 and 255.' . "\n\n", 0);
  }
  return '';
}
$gAnswerSize{'ip'} = 15;
$gCheckAnswerFct{'ip'} = \&check_answer_ip;

***REMOVED*** Check the validity of an answer whose type is serial number
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_serialnum {
  my $answer = shift;
  my $source = shift;
  my $re;

  if ($answer eq '') {
      return ' ';
  }

  $re = '^(([0-9]|[A-Z]){5}-){3}(([0-9]|[A-Z]){5})$';
  ***REMOVED*** This comment fixes emacs's broken syntax highlighting
  if ($answer =~ /$re/) {
    return $answer;
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid.  It must be of the '
               . 'form XXXXX-XXXXX-XXXXX-XXXXX where X is a digit 0-9 or a '
	       . 'capital letter A-Z' . "\n\n", 0);
  }
  return '';
}
$gAnswerSize{'serialnum'} = 23;
$gCheckAnswerFct{'serialnum'} = \&check_answer_serialnum;

***REMOVED*** Check the validity of an answer whose type is editorwizardhelp
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_editorwizardhelp {
  my $answer = shift;
  my $source = shift;

  if (lc($answer) =~ /^e(ditor)?$/) {
    return 'editor';
  }

  if (lc($answer) =~ /^w(izard)?$/) {
    return 'wizard';
  }

  if (lc($answer) =~ /^h(elp)?$/) {
    return 'help';
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid. It must be one of '
               . '"w", "e" or "h".' . "\n\n", 0);
  }
  return '';
}
$gAnswerSize{'editorwizardhelp'} = 6;
$gCheckAnswerFct{'editorwizardhelp'} = \&check_answer_editorwizardhelp;

***REMOVED*** Check the validity of an answer whose type is yesnohelp
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_yesnohelp {
  my $answer = shift;
  my $source = shift;

  if (lc($answer) =~ /^y(es)?$/) {
    return 'yes';
  }

  if (lc($answer) =~ /^n(o)?$/) {
    return 'no';
  }

  if (lc($answer) =~ /^h(elp)?$/) {
    return 'help';
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid.  It must be one of '
               . '"y", "n" or "h".' . "\n\n", 0);
  }
  return '';
}
$gAnswerSize{'yesnohelp'} = 4;
$gCheckAnswerFct{'yesnohelp'} = \&check_answer_yesnohelp;

***REMOVED*** Check the validity of an answer whose type is vmnet
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_vmnet {
  my $answer = shift;
  my $source = shift;

  if ($answer =~ /^\d+$/) {
    if ($answer >= $gMinVmnet && $answer <= $gMaxVmnet) {
      return $answer;
    }
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid. It must be an '
               . 'integer between ' . $gMinVmnet . ' and ' . $gMaxVmnet . '.'
               . "\n\n", 0);
  }

  return '';
}
$gAnswerSize{'vmnet'} = length("$gMaxVmnet");
$gCheckAnswerFct{'vmnet'} = \&check_answer_vmnet;

***REMOVED*** Check the validity of an answer whose type is nettype
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_nettype {
  my $answer = shift;
  my $source = shift;

  if (lc($answer) =~ /^h(ostonly)?$/) {
    return 'hostonly';
  }

  if (lc($answer =~ /^b(ridged)?$/)) {
    return 'bridged';
  }

  if (lc($answer =~ /^n(at)?$/)) {
    return 'nat';
  }

  if (lc($answer =~ /^none$/)) {
    return 'none';
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid. It must be either '
               . '"b", "h", "n", or "none".' . "\n\n", 0);
  }
  return '';
}
$gAnswerSize{'nettype'} = 8;
$gCheckAnswerFct{'nettype'} = \&check_answer_nettype;

***REMOVED*** Check the validity of an answer whose type is availethif
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_availethif {
  my $answer = shift;
  my $source = shift;

  if (grep($answer eq $_, @gAvailEthIf)) {
    return $answer;
  }

  if ($source eq 'user') {
    if (grep($answer eq $_, @gAllEthIf)) {
      print wrap('The ethernet device "' . $answer . '" is already configured '
                 . 'as a bridged device.' . "\n\n", 0);
      return '';
    }
    if (get_answer('The ethernet device "' . $answer . '" was not detected on '
                   . 'your system.  Available ethernet devices detected on '
                   . 'your system include ' . join(', ', @gAvailEthIf) . '.  '
                   . 'Are you sure you want to use this device? (yes/no)',
                   'yesno', 'no') eq 'no') {
      return '';
    } else {
      return $answer;
    }
  }
  return '';
}
$gAnswerSize{'availethif'} = 4;
$gCheckAnswerFct{'availethif'} = \&check_answer_availethif;

***REMOVED*** check the validity of a user or group name against the set of authenticatable users,
***REMOVED*** return the answer if valid or ''
sub check_answer_usergrp {
  my $answer = shift;
  my $source = shift;

  if ($answer=~/^[^-][a-zA-Z0-9.\@\$_-]+$/) {
    my @id_params = getpwnam $answer;
    if ((scalar(@id_params) != 0) && length($answer) < 32) {
      return $answer;
    }
  }

  if ($source eq 'user') {
    my $answer_string = '""';
    if (defined($answer)) {
       $answer_string = '"' . $answer . '"';
    }
    print wrap('The answer ' . $answer_string .' is invalid. Please enter a valid '
               . "name of length < 32 and containing any of letters of the alphabet, "
               . "numbers, '.\@_-', and and not beginning with a '-'.  The name must "
               . "be a valid user on this system."
               . "\n\n", 0);
  }

  return '';
}

$gAnswerSize{'usergrp'} = 32;
$gCheckAnswerFct{'usergrp'} = \&check_answer_usergrp;

***REMOVED*** check the validity of a timeout value
***REMOVED*** return the answer if valid or ''
sub check_answer_timeout {
  my $answer = shift;
  my $source = shift;

  if ($answer=~/^-?\d+$/ && $answer >= -1) {
    return $answer;
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid. Please enter a valid'
               . ' number of minutes in the range -1 to 99999' . "\n\n", 0);
  }

  return '';
}

$gAnswerSize{'timeout'} = 5;
$gCheckAnswerFct{'timeout'} = \&check_answer_timeout;


***REMOVED*** Check the validity of an answer whose type is nocheck
***REMOVED*** Always returns answer.
sub check_answer_anyethif {
  my $answer = shift;
  my $source = shift;

  return $answer;
}
$gAnswerSize{'anyethif'} = 4;
$gCheckAnswerFct{'anyethif'} = \&check_answer_anyethif;

***REMOVED*** Check the validity of an answer whose type is inetport
***REMOVED*** Return a clean answer if valid, or ''
sub check_answer_inetport {
  my $answer = shift;
  my $source = shift;

  if ($source eq 'default' || $source eq 'db') {
    if (check_if_port_free($answer) != 1) {
      return '';
    }
  }

  if (($answer !~ /^\d+$/) || ($answer < 0) || ($answer > 65536)) {
    my $filler = '';
    if ($answer ne '') {
      $filler = ", $answer,";
    }
    my $msg = "The port you selected" . $filler . " is invalid.  A port value "
            . "must be between 0 - 65536 and contain only decimal digits." . "\n\n";
    if ($source eq 'user') {
      print wrap($msg, 0);
    }
    return '';
  }

  if (check_if_port_free($answer) != 1) {
    if ($source eq 'user') {
      print wrap("The port you chose is not available for use.  Please select another "
               . "port value." . "\n", 0);
    }
    return '';
  }

  return $answer;
}
$gAnswerSize{'inetport'} = 5;
$gCheckAnswerFct{'inetport'} = \&check_answer_inetport;

***REMOVED*** Check the validity of an answer whose type is number
***REMOVED*** Return a clean number if valid, or '0'
***REMOVED*** Default value for the 'number' type of answer.
***REMOVED*** This $gMaxNumber as well as the $gAnswerSize{'number'} has to be updated
***REMOVED*** before calling get_*_answer functions so that wrap() leaves enough room
***REMOVED*** for the reply.
my $gMaxNumber = 0;
sub check_answer_number {
  my $answer = shift;
  my $source = shift;

  if (($answer =~ /^\d+$/) && ($answer > 0) && ($answer <= $gMaxNumber)) {
    return $answer;
  }

  if ($source eq 'user') {
    print wrap('The answer "' . $answer . '" is invalid. Please enter a valid '
               . 'number in the range 1 to ' . $gMaxNumber . "\n\n", 0);
  }

  return '';
}
$gAnswerSize{'number'} = length($gMaxNumber);
$gCheckAnswerFct{'number'} = \&check_answer_number;

***REMOVED*** Check the validity of an answer whose type is netname
***REMOVED*** Always returns answer.
sub check_answer_netname {
  my $answer = shift;
  my $source = shift;

  if (length($answer) > 255) {
    print wrap("That name is too long, please enter a name"
               . " shorter than 256 characters.\n");
    $answer = '';
  }
  return $answer;
}
$gAnswerSize{'netname'} = 32;
$gCheckAnswerFct{'netname'} = \&check_answer_netname;

my %gPortCache;
***REMOVED*** Check $cServices file for specified port
***REMOVED*** If port not in $cServices return 1
***REMOVED*** If port is in $cServices return 0
sub check_port_not_registered {
  my $port = shift;
  if (defined($gPortCache{$port}) && $gPortCache{$port} == 2) {
    return 0;
  }
  return 1;
}

***REMOVED*** Fill the cache with port assignments from /etc/services
***REMOVED*** that aren't already filled by earlier calls to get_tcp_listeners()
***REMOVED*** and get_proc_tcp_entries().  Ignore vmware* entries.
sub get_services_ports {
  if (not open(CONF, $cServices)) {
    return -1;
  }

  while (<CONF>) {
    if (/(.*)\b(\d+)\/(tcp)\b/i) {
      if ((!defined($gPortCache{$2})) && ($1 !~ /^vmware/i)) {
        $gPortCache{$2} = 2;
      }
    }
  }
  close(CONF);

}

***REMOVED*** Use /proc/net/tcp as a list of ports in use and fillout the
***REMOVED*** port cache with those entries.
sub get_proc_tcp_entries {
  undef %gPortCache;

  foreach my $i (qw(tcp tcp6)) {
    if (not open(TCP, "</proc/net/" . $i)) {
      next;
    }
    while (<TCP>) {
      if (/^\s*\d+:\s*[0-9a-fA-F]+:([0-9a-fA-F]{4})\s*[0-9a-fA-F]+:[0-9a-fA-F]{4}\s*([0-9a-fA-F]{2}).*$/) {
        ***REMOVED*** We'll consider a socket free if it is in TIME_WAIT state
        if ($2 eq "06") {
          next;
        }
        ***REMOVED*** Ignore if port is already defined, unless its value is 2.  That is,
        ***REMOVED*** the port is really a 'maybe' in use.
        if (!defined($gPortCache{$1}) || $gPortCache{$1} eq 2) {
          $gPortCache{hex($1)} = 1;
        }
      }
    }
    close TCP;
  }
}

sub check_if_port_active {
  my $port = shift;

  ***REMOVED*** In this case, only want ports that are active on the system, not just
  ***REMOVED*** place holders in /etc/services.
  if (defined($gPortCache{$port}) && $gPortCache{$port} == 1) {
    return 1;
  }

  return 0;
}

***REMOVED*** if the port is already in use i.e. in the port cache.
***REMOVED*** If port is free, return 1;
***REMOVED*** If port is in use, return 0;
sub check_if_port_free {
  my $port = shift;

  if (check_if_port_active($port)) {
    return 0;
  }

  return check_port_not_registered($port);
}


***REMOVED*** Display the end-user license agreement
sub show_EULA {
  if (   (not defined($gDBAnswer{'EULA_AGREED'}))
      || (db_get_answer('EULA_AGREED') eq 'no')) {
    if ($gOption{'default'} == 1) {
       print wrap('You must read and accept the End User License Agreement to '
                  . 'continue.' . "\n\n" . 'To display End User License '
                  . 'Agreement please restart ' . $0 . ' in the '
                  . 'interactive mode, without using `-d\' option.' . "\n\n", 0);
       exit 0;
    }
    query('You must read and accept the End User License Agreement to '
          . 'continue.' . "\n" . 'Press enter to display it.', '', 0);

    open(EULA, db_get_answer('DOCDIR') . '/EULA') ||
      error("$0: can't open EULA file: $!\n");

    my $origRecordSeparator = $/;
    undef $/;

    my $eula = <EULA>;
    close(EULA);

    $/ = $origRecordSeparator;

    $eula =~ s/(.{50,76})\s/$1\n/g;

    ***REMOVED*** Trap the PIPE signal to avoid broken pipe errors on RHEL4 U4.
    local $SIG{PIPE} = sub {};

    open(PAGER, '| ' . $gHelper{'more'}) ||
      error("$0: can't open $gHelper{'more'}: $!\n");
    print PAGER $eula . "\n";
    close(PAGER);

    print "\n";

    ***REMOVED*** Make sure there is no default answer here
    if (get_persistent_answer('Do you accept? (yes/no)', 'EULA_AGREED',
                              'yesno', '') eq 'no') {
      print wrap('Please try again when you are ready to accept.' . "\n\n", 0);
      exit 1;
    }

    print wrap('Thank you.' . "\n\n", 0);
  }
}

***REMOVED*** Build a Linux kernel integer version
sub kernel_version_integer {
  my $version = shift;
  my $patchLevel = shift;
  my $subLevel = shift;

  return $version * 65536 + $patchLevel * 256 + $subLevel;
}

***REMOVED*** Retrieve distribution information
sub distribution_info {
  my $issue = '/etc/issue';
  my $system;

  ***REMOVED*** First use the accurate method that are intended to work reliably on recent
  ***REMOVED*** distributions (if an FHS guy is listening, we really need a generic way to
  ***REMOVED*** do this)
  if (-e '/etc/debian_version') {
    return 'debian';
  }
  if (-e '/etc/redhat-release') {
    return 'redhat';
  }
  if (-e '/etc/SuSE-release') {
    return 'suse';
  }
  if (-e '/etc/turbolinux-release') {
    return 'turbolinux';
  }
  if (-e '/etc/mandrake-release') {
    return 'mandrake';
  }

  ***REMOVED*** Then use less accurate methods that should work even on old distributions,
  ***REMOVED*** if people haven't customized their system too much
  if (-e $issue) {
    if (not (direct_command(shell_string($gHelper{'grep'}) . ' -i '
                            . shell_string('debian') . ' '
                            . shell_string($issue)) eq '')) {
      return 'debian';
    }
    if (not (direct_command(shell_string($gHelper{'grep'}) . ' -i '
                            . shell_string('red *hat') . ' '
                            . shell_string($issue)) eq '')) {
      return 'redhat';
    }
    if (not (direct_command(shell_string($gHelper{'grep'}) . ' -i '
                            . shell_string('suse\|s\.u\.s\.e') . ' '
                            . shell_string($issue)) eq '')) {
      return 'suse';
    }
    if (not (direct_command(shell_string($gHelper{'grep'}) . ' -i '
                            . shell_string('caldera') . ' '
                            . shell_string($issue)) eq '')) {
      return 'caldera';
    }
  }

  return 'unknown';
}

sub vmware_check_vm_app_name {
  return db_get_answer('SBINDIR') . '/vmware-checkvm';
}

sub vmware_vmx_app_name {
  return db_get_answer('LIBDIR') . '/bin/vmware-vmx';
}

sub is64BitKernel {
  if (vmware_product() eq 'tools-for-solaris') {
    if (direct_command(shell_string($gHelper{'isainfo'}) . ' -k') =~ /amd64/) {
      return 1;
    } else {
      return 0;
    }
  }

  if (direct_command(shell_string($gHelper{'uname'}) . ' -m') =~ /(x86_64|amd64)/) {
    return 1;
  } else {
    return 0;
  }
}

***REMOVED*** SIGINT handler (only gets used in tools configurations)
sub sigint_handler {
  error("\n");
}

***REMOVED*** The installer packages up both 32 and 64 bit userlevel binaries, leaving
***REMOVED*** them all in LIBDIR. This function links the correct thing in BINDIR and
***REMOVED*** SBINDIR. This "installs" vmware-checkvm, vmware-guestd,
***REMOVED*** vmware-tools-upgrader, vmware-hgfsclient, vmware-hgfsmounter,
***REMOVED*** vmware-vmblock-fuse and the wrapper script for vmware-toolbox.
sub setup32or64Symlinks {
  my $is64BitUserland = is64BitUserLand();
  my $libdir = db_get_answer('LIBDIR');
  my $libbindir = $libdir . ($is64BitUserland ? '/bin64' : '/bin32');
  my $libsbindir = $libdir . ($is64BitUserland ? '/sbin64' : '/sbin32');
  my $liblibdir = $libdir . ($is64BitUserland ? '/lib64' : '/lib32');
  my $pluginsdir = $libdir . ($is64BitUserland ? '/plugins64' : '/plugins32');
  my $pamdfile = $libdir . '/configurator/pam.d/vmtoolsd';
  my $bindir = db_get_answer('BINDIR');
  my $sbindir = db_get_answer('SBINDIR');

  $libbindir .= getFreeBSDBinSuffix();
  $liblibdir .= getFreeBSDLibSuffix();
  $libsbindir .= getFreeBSDSbinSuffix();

  install_symlink($libsbindir . '/vmware-checkvm',
                  $sbindir . '/vmware-checkvm');

  install_symlink($libsbindir . '/vmware-rpctool',
                  $sbindir . '/vmware-rpctool');

  if ($useApploader) {
      install_hardlink($libbindir . '/appLoader',
                       $libsbindir . '/vmtoolsd');
      install_symlink($libsbindir . '/vmtoolsd',
                      $sbindir . "/vmtoolsd");
  } elsif (vmware_product() eq 'tools-for-freebsd') {
      install_symlink($libsbindir . '/vmtoolsd-wrapper',
                      $sbindir . '/vmtoolsd');
  } else {
      install_symlink($libsbindir . '/vmware-guestd-wrapper',
                      $sbindir . '/vmware-guestd');
  }

  ***REMOVED***
  ***REMOVED*** Linux distros now use apploader for toolbox-cmd and
  ***REMOVED*** modconfig-console.
  ***REMOVED***
  if ($useApploader) {
    install_symlink($libbindir . '/appLoader',
		    $bindir . '/vmware-toolbox-cmd');
    install_symlink($libbindir . '/appLoader',
		    $libsbindir . '/vmware-modconfig-console');
  } else {
    install_symlink($libbindir . '/vmware-toolbox-cmd-wrapper',
		    $bindir . '/vmware-toolbox-cmd');
  }

  ***REMOVED*** Both the toolbox and vmware-user get special attention as their dependency
  ***REMOVED*** on shipped gtk libraries require us to use special wrapper scripts if not
  ***REMOVED*** cut them out entirely for a particular product. Here's the scoop:
  ***REMOVED***
  ***REMOVED*** On Linux and Solaris, we use the gtk toolbox everywhere, and use wrapper
  ***REMOVED*** scripts for both the toolbox and vmware-user. Note that the vmware-user
  ***REMOVED*** wrapper script is marked setuid.
  ***REMOVED***
  ***REMOVED*** On FreeBSD, we use the gtk toolbox for release 5.0 and higher, and the tcl
  ***REMOVED*** toolbox otherwise. vmware-user is only available from release 5.3 or
  ***REMOVED*** higher, and both it and the toolbox are run via wrapper scripts (like
  ***REMOVED*** Linux and Solaris, the vmware-user wrapper script is marked setuid).
  if (vmware_product() eq 'tools-for-linux') {
     install_symlink($libbindir . '/vmware-user-wrapper',
                     $bindir . '/vmware-user-wrapper');
     install_symlink($libbindir . '/vmware-user-suid-wrapper',
                     $bindir . '/vmware-user');
     install_symlink($libbindir . '/appLoader',
		     $bindir . '/vmware-toolbox');
     install_symlink($libbindir . '/vmware-gksu',
                     $bindir . '/vmware-gksu');

     set_manifest_component('vmwareuser', 'TRUE');
     set_manifest_component('toolboxgtk', 'TRUE');

  } elsif (vmware_product() eq 'tools-for-freebsd') {
    my $release = `uname -r | cut -f1 -d-`;
    if ($release < 5.0) {
      install_symlink($libbindir . '/vmware-toolbox-tcl',
		      $bindir . '/vmware-toolbox');
    } else {
      install_symlink($libbindir . '/vmware-toolbox-gtk-wrapper',
		      $bindir . '/vmware-toolbox');
      if ($release >= 5.3) {
        install_symlink($libbindir . '/vmware-user-wrapper',
                        $bindir . '/vmware-user-wrapper');
        install_symlink($libbindir . '/vmware-user-suid-wrapper',
                        $bindir . '/vmware-user');
      }
    }
  }
  ***REMOVED*** Generic spots for the wrapper to access so it won't need to know lib32-6, etc.
  install_symlink($liblibdir, $libdir . "/lib");
  install_symlink($libbindir, $libdir . "/bin");
  install_symlink($libsbindir, $libdir . "/sbin");
  install_symlink($liblibdir . "/libconf", $libdir . "/libconf");
  install_symlink($pluginsdir, $libdir . "/plugins");
  install_symlink($libdir . "/plugins", $gRegistryDir . "/plugins");

  if (vmware_product() eq 'tools-for-linux') {
     install_symlink($libsbindir . '/vmware-tools-upgrader',
                     $sbindir .  '/vmware-tools-upgrader');
     install_symlink($pamdfile, '/etc/pam.d/vmtoolsd');

     install_symlink($libbindir . '/appLoader',
                     $bindir . '/vmware-hgfsclient');
     install_symlink($libbindir . '/vmware-xferlogs',
                     $bindir . '/vmware-xferlogs');
     install_symlink($libsbindir . '/vmware-vmblock-fuse-wrapper',
                     $sbindir . '/vmware-vmblock-fuse');
     ***REMOVED*** Hardcoded because mount(8) expects mounting apps to be /sbin/mount.fs
     ***REMOVED*** Install the hgfsmounter app to /sbin/mount.vmhgfs to solve SELinux issues.
     ***REMOVED*** This is all handled in the tar installer auto-magically now so don't do
     ***REMOVED*** the symlink here any more.  But we still set the manifest_component here.
     ***REMOVED*** See bug 527827.

     set_manifest_component('vmtoolsd', 'TRUE');
     set_manifest_component('upgrader', 'TRUE');
     set_manifest_component('hgfsclient', 'TRUE');
     set_manifest_component('hgfsmounter', 'TRUE');
     set_manifest_component('checkvm', 'TRUE');
     set_manifest_component('toolbox-cmd', 'TRUE');
  }

  if (vmware_product() eq 'tools-for-freebsd') {
      my $hgfsmounterBinary = $libsbindir . '/vmware-hgfsmounter';
      if (-f $hgfsmounterBinary) {
	  safe_chmod(0555, $hgfsmounterBinary);

	  ***REMOVED*** Hardcoded because FreeBSD's mount(8) expects mounting apps to be /sbin/mount_fs
	  install_symlink($hgfsmounterBinary,
			  '/sbin/mount_vmhgfs');
      }

      safe_chmod(0555, $libsbindir . '/vmware-vmblockmounter');
      install_symlink($libsbindir . '/vmware-vmblockmounter',
                      '/sbin/mount_vmblock');

      set_manifest_component('vmblockmounter', 'TRUE');
  }
}

***REMOVED*** Solaris can boot into either its 32-bit or 64-bit kernel and invokes the
***REMOVED*** appropriate binary through use of its isaexec(3C) program.  This means that
***REMOVED*** we need to add symlinks for both the 32-bit and 64-bit versions and a hard
***REMOVED*** link to /usr/lib/isaexec.
sub install_solaris_symlink {
   my $targetdir = shift;
   my $targetname = shift;
   my $linkdir = shift;
   my $linkname = shift;

   ***REMOVED*** Create i86 and amd64 directories if necessary
   create_dir($linkdir . '/i86', $cFlagDirectoryMark);
   create_dir($linkdir . '/amd64', $cFlagDirectoryMark);

   install_symlink($targetdir . '/i86/' . $targetname,
                   $linkdir . '/i86/' . $linkname);
   install_symlink($targetdir . '/amd64/' . $targetname,
                   $linkdir . '/amd64/' . $linkname);

   ***REMOVED*** Try to install a hard link to /usr/lib/isaexec.  If that doesn't work, we
   ***REMOVED*** copy isaexec to $linkdir and create a hard link to that one.
   if (install_hardlink('/usr/lib/isaexec', $linkdir . '/' . $linkname) eq 'no') {
      my $isaexec = $linkdir . '/isaexec';
      system(shell_string($gHelper{'cp'}) . ' /usr/lib/isaexec ' . $isaexec);
      db_add_file($isaexec, 0);
      install_hardlink($isaexec, $linkdir . '/' . $linkname);
   }
}

***REMOVED*** Solaris can boot into either its 32-bit or 64-bit kernel and invokes the
***REMOVED*** appropriate binary through use of its isaexec(3C) program.  Ideally we use
***REMOVED*** symlinks for our wrapper scripts but some wrapper scripts need to be altered
***REMOVED*** based on the system (ie Solaris 10 vs 11), hence we need to modify the wrapper
***REMOVED*** and install it.
sub install_solaris_custom_wrapper {
   my $srcdir = shift;
   my $srcname = shift;
   my $destdir = shift;
   my $destname = shift;
   my $patchRef = shift;

   ***REMOVED*** Create i86 and amd64 directories if necessary
   create_dir($destdir . '/i86', $cFlagDirectoryMark);
   create_dir($destdir . '/amd64', $cFlagDirectoryMark);

   install_file($srcdir . '/i86/' . $srcname,
                $destdir . '/i86/' . $destname,
                $patchRef, 0);
   install_file($srcdir . '/amd64/' . $srcname,
                $destdir . '/amd64/' . $destname,
                $patchRef, 0);

   ***REMOVED*** Try to install a hard link to /usr/lib/isaexec.  If that doesn't work, we
   ***REMOVED*** copy isaexec to $linkdir and create a hard link to that one.
   if (install_hardlink('/usr/lib/isaexec', $destdir . '/' . $destname) eq 'no') {
      my $isaexec = $destdir . '/isaexec';
      system(shell_string($gHelper{'cp'}) . ' /usr/lib/isaexec ' . $isaexec);
      db_add_file($isaexec, 0);
      install_hardlink($isaexec, $destdir . '/' . $destname);
   }
}


***REMOVED*** See the comment above install_solaris_symlink().
sub setupSolarisSymlinks {
   my $libdir = db_get_answer('LIBDIR');
   my $plugins32 = $libdir . '/plugins32';
   my $plugins64 = $libdir . '/plugins64';
   my $libbindir = $libdir . '/bin';
   my $libsbindir = $libdir . '/sbin';
   my $bindir = db_get_answer('BINDIR');
   my $sbindir = db_get_answer('SBINDIR');
   my %patch;

   ***REMOVED*** Forcefully load libs based on the Solaris release for toolbox-gtk.
   my $rel = `uname -r`;
   chomp $rel;
   my $forcedLibs = $gSolarisToolboxGtkForcedLibs{$rel};
   if ($forcedLibs) {
      $patch{'@@VMWARE_APPENDED_LIBS@@'} = $forcedLibs;
   }
   install_solaris_custom_wrapper($libbindir, 'vmware-toolbox',
                                  $bindir, 'vmware-toolbox',
                                  \%patch);

   install_solaris_symlink($libsbindir, 'vmware-checkvm',
                           $sbindir, 'vmware-checkvm');

   install_solaris_symlink($libsbindir, 'vmware-rpctool',
                           $sbindir, 'vmware-rpctool');

***REMOVED*** If the app requires a wrapper, let the wrapper handle selecting the arch.
   install_symlink("$libdir/wrapper-all.sh",
                   "$sbindir/vmtoolsd");

   install_symlink("$libdir/wrapper-all.sh",
                   "$bindir/vmware-toolbox-cmd");

***REMOVED*** VMware-user-suid-wrapper requires no wrapper and is only available in
***REMOVED*** a 32 bit flavor.  Since the installer sets the suid bit, leave the binary
***REMOVED*** where it is and simply add a symlink to it from $bindir
   install_symlink("$libbindir/i86/vmware-user-suid-wrapper",
                   "$bindir/vmware-user");

   ***REMOVED*** Install vmware-hgfsmounter into /etc/fs/vmhgfs because that's
   ***REMOVED*** where Solaris's mount expects to find it. We only install 32
   ***REMOVED*** bit version since it is going to work on 64 bit as well.
   create_dir('/etc/fs/vmhgfs', $cFlagDirectoryMark);
   install_symlink($libsbindir . '/i86/vmware-hgfsmounter',
                   '/etc/fs/vmhgfs/mount');

   ***REMOVED*** Do the same for vmware-vmblockmounter
   create_dir('/etc/fs/vmblock', $cFlagDirectoryMark);
   install_symlink($libsbindir . '/i86/vmware-vmblockmounter',
                   '/etc/fs/vmblock/mount');

   install_symlink($plugins32, "$gRegistryDir/plugins");
   install_symlink($plugins64, "$plugins32/amd64");
}

***REMOVED*** We must set up various symlinks for each of our Tools products.
sub setupSymlinks {
   if (vmware_product() eq 'tools-for-linux') {
      setup32or64Symlinks();
   } elsif (vmware_product() eq 'tools-for-freebsd') {
      setup32or64Symlinks();
   } elsif (vmware_product() eq 'tools-for-solaris') {
      setupSolarisSymlinks();
   }
}

***REMOVED*** Open a file binary and read the ELF header. We really only care about the fifth
***REMOVED*** byte, EI_CLASS. I pulled the values from /usr/include/elf.h
sub is64BitElf {
  my $file = shift;
  my ($buf, $buf2);
  my $cEI_CLASS = 4;
  my $cELFCLASS64 = 2;
  my $cEI_MAG0 = 0;
  my $cSELFMAG = 4;
  my $cELFMAG = "\x7FELF";

  open(X_BIN, '<' . $file) || return 0;
  seek(X_BIN, $cEI_MAG0, 0) || return 0;
  read(X_BIN, $buf, $cSELFMAG)  || return 0;
  ($buf2) = unpack("a4", $buf);
  if ($buf2 ne $cELFMAG) {
      return 0;
  }

  seek(X_BIN, $cEI_CLASS, 0) || return 0;
  read(X_BIN, $buf, 1)  || return 0;
  ($buf2) = unpack("C", $buf);
  return ($buf2 eq $cELFCLASS64);
}

sub isAthlonKernel {
  my $version = shift;
  my $patchLevel = shift;
  my $answer = 'no';

  ***REMOVED*** Right now this only applies to 2.4.x kernels as /proc/ksyms was
  ***REMOVED*** eliminated in the 2.6 kernel.
  ***REMOVED***
  ***REMOVED*** Look for the mmx flag so we can tell if we are running on a kernel
  ***REMOVED*** built for the athlon family of processors.
  if ("$version.$patchLevel" eq '2.4') {
     if (not open (KSYMS, '</proc/ksyms')) {
       error ('Could not open /proc/ksyms to determine if kernel is compiled '
            . "for Athlon processors.\n");
     }
     while (<KSYMS>) {
       if (/mmx_clear_page/) {
         $answer = 'yes';
         last;
       }
     }
     close (KSYMS);
  }
  return $answer;
}

***REMOVED*** Retrieve and check system information
sub system_info {
  my $fullVersion;
  my $version;
  my $patchLevel;
  my $subLevel;
  my $runSystem;

  ***REMOVED*** populate_non_vmware_modules can take a while to run.  Add this here to
  ***REMOVED*** let users know our code is actually doing something.
  print wrap("Initializing...\n\n", 0);

  $gSystem{'system'} = direct_command(shell_string($gHelper{'uname'}) . ' -s');
  chomp($gSystem{'system'});

  if (vmware_product() eq 'tools-for-freebsd') {
     $runSystem = 'FreeBSD';
  } elsif (vmware_product() eq 'tools-for-solaris') {
     $runSystem = 'SunOS';
  } else {
     $runSystem = 'Linux';
  }

  if (not ($gSystem{'system'} eq $runSystem)) {
    error('You are not running ' . $runSystem . '. This version of the product '
          . 'only runs on ' . $runSystem . '.' . "\n\n");
  }

  ***REMOVED*** Users will expect the output to be "Solaris", despite what uname -s says
  if (vmware_product() eq 'tools-for-solaris') {
    $gSystem{'system'} = 'Solaris';
  }

  $gSystem{'uts_release'} = direct_command(shell_string($gHelper{'uname'})
                                             . ' -r');
  chomp($gSystem{'uts_release'});
  $gSystem{'uts_version'} = direct_command(shell_string($gHelper{'uname'})
                                           . ' -v');
  chomp($gSystem{'uts_version'});

  if ($runSystem eq 'Linux') {

    ($version, $patchLevel, $subLevel) = split(/\./, $gSystem{'uts_release'});
    ***REMOVED*** Clean the subLevel in case there is an extraversion
    ($subLevel) = split(/[^0-9]/, $subLevel);
    $gSystem{'version_utsclean'} = $version . '.' . $patchLevel . '.'
                                   . $subLevel;

    $gSystem{'version_integer'} = kernel_version_integer($version, $patchLevel,
                                                         $subLevel);
    if ($gSystem{'version_integer'} < kernel_version_integer(2, 0, 0)) {
      error('You are running Linux version ' . $gSystem{'version_utsclean'}
            . '.  This product only runs on 2.0.0 and later kernels.' . "\n\n");
    }

    if (vmware_product() eq 'server') {
      $gSystem{'smp'} = 'no';
      $gSystem{'versioned'} = 'yes';
    } else {
      $gSystem{'smp'} = (direct_command(shell_string($gHelper{'uname'})
                                        . ' -v') =~ / SMP /) ? 'yes' : 'no';
      $gSystem{'versioned'} = (direct_command(shell_string($gHelper{'grep'}) . ' '
        . shell_string('^[0-9a-fA-F]\{8\} Using_Versions') . ' /proc/ksyms 2> /dev/null')
          eq '') ? 'no' : 'yes';
    }

    $gSystem{'distribution'} = distribution_info();

    if (is64BitKernel()) {
      $gSystem{'page_offset'} = '0000010000000000';
    } else {
      $gSystem{'page_offset'} = 'C0000000';
    }

    if ($gSystem{'version_integer'} >= kernel_version_integer(2, 1, 0)) {
      ***REMOVED*** 2.1.0+ kernels have hardware verify_area() support
      my @fields;

      @fields = split(' ', direct_command(
        shell_string($gHelper{'grep'}) . ' '
        . shell_string('^[0-9a-fA-F]\{8\} printk') . ' /proc/ksyms 2> /dev/null'));
      if (not defined($fields[0])) {
        @fields = split(' ', direct_command(
	  shell_string($gHelper{'grep'}) . ' '
	  . shell_string('^[0-9a-fA-F]\{8\} \w printk') . ' /proc/kallsyms 2> /dev/null'));
      }
      if (defined($fields[0])) {
        my $page_offset;

        ***REMOVED*** printk is always located in first 256KB of kernel - that is from
        ***REMOVED*** PAGE_OFFSET to PAGE_OFFSET + 256KB on normal kernel and
        ***REMOVED*** PAGE_OFFSET + 1MB to PAGE_OFFSET + 1.25MB for bzImage kernel.
        ***REMOVED*** Both ranges are well below 16MB granularity we are allowing.
        if ($fields[0] =~ /^([0-9a-fA-F]{2})/) {
          $page_offset = uc($1).'000000';
        } else {
	  $page_offset = undef;
        }
        $gSystem{'page_offset'} = $page_offset;
      } else {
        ***REMOVED*** Unable to find page_offset: accept anything
	$gSystem{'page_offset'} = undef;
      }
    }

    ***REMOVED*** Linux kernel build bug
    $gSystem{'build_bug'} = (direct_command(shell_string($gHelper{'grep'}) . ' '
      . shell_string('^[0-9a-fA-F]\{8\} __global_cli_R__ver___global_cli')
      . ' /proc/ksyms 2> /dev/null') eq '') ? 'no' : 'yes';
  }

  ***REMOVED*** Determine whether the kernel is complied for Athlon Processors
  if (vmware_product() eq 'tools-for-linux') {
    $gSystem{'athlonKernel'} = isAthlonKernel($version, $patchLevel);
  } else {
    $gSystem{'athlonKernel'} = 'no';
  }

  ***REMOVED*** Warning, the return after the end of the if statement
  ***REMOVED*** will void everything after.
  if (vmware_product() eq 'tools-for-linux' ||
      vmware_product() eq 'tools-for-freebsd' ||
      vmware_product() eq 'tools-for-solaris') {

    $gSystem{'product'} =
      direct_command(shell_string(vmware_check_vm_app_name()) . ' -p');
    if (direct_command(shell_string(vmware_check_vm_app_name())) =~ /good/) {
      $gSystem{'invm'} = 'yes';
    } else {
      $gSystem{'invm'} = 'no';
    }
    $gSystem{'resolution'} =
      direct_command(shell_string(vmware_check_vm_app_name()) . ' -r');
    chomp($gSystem{'resolution'});
    return;
  }

  ***REMOVED*** These commands are Linux-specific
  if (vmware_product() ne 'tools-for-freebsd' &&
      vmware_product() ne 'tools-for-solaris') {
    ***REMOVED*** C library
    ***REMOVED*** XXX This relies on the locale
    my @missing;
    my $ldd_out = direct_command(shell_string($gHelper{'ldd'}) . ' ' . vmware_vmx_app_name());
    foreach my $lib (split(/\n/, $ldd_out)) {
      if ($lib =~ '(\S+) => not found') {
         push(@missing, $1);
      }
    }

    if (scalar(@missing) > 0) {
       print wrap("The following libraries could not be found on your system:\n", 0);
       print join("\n", @missing);
       print "\n\n";

       query('You will need to install these manually before you can run ' .
             vmware_product_name() . ".\n\nPress enter to continue.", '', 0);
    }

    ***REMOVED*** Processor
    foreach my $instruction ('^cpuid', 'cmov') {
      if (direct_command(shell_string($gHelper{'grep'}) . ' '
          . shell_string($instruction) . ' /proc/cpuinfo') eq '') {
        ***REMOVED*** Read the current config file;
        open(CPUINFO, '/proc/cpuinfo')
           or error('Unable to open /proc/cpuinfo in read-mode' . "\n\n");
        my @cpuinfo = <CPUINFO>;
        close(CPUINFO);
        error('Your ' . (($gSystem{'smp'} eq 'yes') ? 'processors do'
                                                    : 'processor does') . ' not '
              . 'support the ' . $instruction . ' instruction. '
              . vmware_product_name() . ' will not run on this system.' . "\n\n"
              . 'Your /proc/cpuinfo is:' . "\n\n" . "@cpuinfo");
      }
    }
    ***REMOVED*** The "flags" field became the "features" field in 2.4.0-test11-pre5
    if (direct_command(shell_string($gHelper{'grep'}) . ' '
                       . shell_string('^\(flags\|features\).* tsc')
                       . ' /proc/cpuinfo') eq '') {
      error('Your ' . (($gSystem{'smp'} eq 'yes') ? 'processors do'
                                                  : 'processor does') . ' not '
            . 'have a Time Stamp Counter.  ' . vmware_product_name()
            . ' will not run on this system.' . "\n\n");
    }
  }
}

***REMOVED*** Point the user to a URL dealing with module-related problems and exits
sub module_error {
  error('For more information on how to troubleshoot module-related problems, '
        . 'please visit our Web site at "http://www.vmware.com/go/'
        . 'unsup-linux-products" and "http://www.vmware.com/go/'
        . 'unsup-linux-tools".' . "\n\n");
}

***REMOVED*** Install a module if it suitable
***REMOVED*** Return 1 if success, 0 if failure
sub try_module {
  my $name = shift;
  my $mod = shift;
  my $force = shift;
  my $silent = shift;
  my $dst_dir;
  my %patch;

  if (not (-e $mod)) {
    ***REMOVED*** The module does not exist
    return 0;
  }

  ***REMOVED*** NOTE: See bug 347401.  We don't want to unload the pvscsi kernel module
  ***REMOVED*** and try a new one, so we'll simply skip this step for pvscsi.
  ***REMOVED*** NOTE: See bug 349327.  We no longer want to interrupt networking during
  ***REMOVED*** tools configuration.
  if (vmware_product() ne 'server' && $name ne 'pvscsi' &&
      $name ne 'vmxnet' && $name ne 'vmxnet3') {
    ***REMOVED*** Probe the module without loading it or executing its code.  It is cool
    ***REMOVED*** because it avoids problems like 'Device or resource busy'
    ***REMOVED*** Note: -f bypasses only the kernel version check, not the symbol
    ***REMOVED*** resolution
    if(!kmod_load_by_path($mod, $silent, $force, 1)) {
      return 0;
    }

    ***REMOVED*** If we are using new module-init-tools, they just ignore
    ***REMOVED*** '-p' option, and they just loaded module into the memory.
    ***REMOVED*** Just try rmmod-ing it. Silently.
    kmod_unload($name, 0);
  }

  if (-d $cKernelModuleDir . '/'. $gSystem{'uts_release'}) {
    $dst_dir = $cKernelModuleDir . '/' . $gSystem{'uts_release'};
  } else {
    print wrap('This program does not know where to install the ' . $name
               . ' module because the "' . $cKernelModuleDir . '/'
               . $gSystem{'uts_release'} . '" directory (the usual '
               . 'location where the running kernel would look for the '
               . 'module) is missing.  Please make sure that this '
               . 'directory exists before re-running this program.'
               . "\n\n", 0);
    return 0;
  }
  create_dir($dst_dir . '/misc', $cFlagDirectoryMark);
  undef %patch;
  ***REMOVED*** Install the module with a .o extension, as the Linux kernel does
  my $modDest = $dst_dir . '/misc/' . $name;
  install_file($mod, $modDest . '.o', \%patch, $cFlagTimestamp);
  ***REMOVED*** install a .ko symlink for 2.6 kernels
  install_symlink($modDest . '.o', $modDest . '.ko');
  ***REMOVED*** The old installer allowed people to manually build modules without .o
  ***REMOVED*** extension.  Such modules were not removed by the old uninstaller, and
  ***REMOVED*** unfortunately, insmod tries them first.  Let's move them.
  if (file_name_exist($dst_dir . '/misc/' . $name)) {
    backup_file($dst_dir . '/misc/' . $name);
    if (not unlink($dst_dir . '/misc/' . $name)) {
      print STDERR wrap('Unable to remove the file ' . $dst_dir . '/misc/'
                        . $name . '.' . "\n\n", 0);
    }
  }

  return 1;
}

***REMOVED*** Remove a temporary directory
sub remove_tmp_dir {
  my $dir = shift;

  if (system(shell_string($gHelper{'rm'}) . ' -rf ' . shell_string($dir))) {
    print STDERR wrap('Unable to remove the temporary directory ' . $dir . '.'
                      . "\n\n", 0);
  };
}

sub get_cc {
  $gHelper{'gcc'} = '';
  if (defined($ENV{'CC'}) && (not ($ENV{'CC'} eq ''))) {
    $gHelper{'gcc'} = internal_which($ENV{'CC'});
    if ($gHelper{'gcc'} eq '') {
      print wrap('Unable to find the compiler specified in the CC environnment variable: "'
                 . $ENV{'CC'} . '".' . "\n\n", 0);
    }
  }
  if ($gHelper{'gcc'} eq '') {
    $gHelper{'gcc'} = internal_which('gcc');
    if ($gHelper{'gcc'} eq '') {
      $gHelper{'gcc'} = internal_which('egcs');
      if ($gHelper{'gcc'} eq '') {
        $gHelper{'gcc'} = internal_which('kgcc');
        if ($gHelper{'gcc'} eq '') {
          $gHelper{'gcc'} = DoesBinaryExist_Prompt('gcc');
        }
      }
    }
  }
  print wrap('Using compiler "' . $gHelper{'gcc'}
             . '". Use environment variable CC to override.' . "\n\n", 0);
  return $gHelper{'gcc'};
}

sub get_gcc_version {
  my ($gcc) = @_;
  ***REMOVED*** See bug 330893. Previously, we retrieved the gcc version from the output
  ***REMOVED*** of "gcc -dumpversion". Unfortunately, SuSE doesn't use this string like
  ***REMOVED*** any other distribution, and so we'll retrieve this from parsing the
  ***REMOVED*** output of "gcc -v" instead.
  my $gcc_version = direct_command(shell_string($gcc) . " -v 2>&1 | tail -1");
  chomp($gcc_version);
  ***REMOVED*** Two examples of $gcc_version at this stage are:
  ***REMOVED***
  ***REMOVED*** gcc version 4.1.2 20070115 (prerelease) (SUSE Linux)
  ***REMOVED*** gcc version 4.1.2 20071124 (Red Hat 4.1.2-42)
  ***REMOVED***
  ***REMOVED*** Parse through this to retrieve the version information.
  if ($gcc_version =~ /^gcc version (egcs-)?(\d+\.\d+(\.\d+)*)/) {
    return $2;
  } else {
    print wrap('Your compiler "' . $gHelper{'gcc'} . '" version "' .
	       $gcc_version . '" is not supported ' .
	       'by this version of ' . vmware_product_name() . '.' .
	       "\n\n", 0);
    return 'no';
  }

}

***REMOVED*** Verify gcc version, finding a better match if needed.
sub check_gcc_version {
  my ($kernel_gcc_version) = undef;

  ***REMOVED*** In kernels >= 2.6.19, we no longer have to worry about gcc version
  ***REMOVED*** differences between the kernel and the modules compiled for that kernel.
  ***REMOVED*** Hence, we can return yes if our kernel version is 2.6.19 or greater.
  ***REMOVED***
  ***REMOVED*** See bug 350735 for details.     -astiegmann
  if (defined ($gSystem{'version_integer'}) and
     $gSystem{'gcc_version'} ne 'no' and
     $gSystem{'version_integer'} >= kernel_version_integer (2, 6, 19)) {
    return 'yes';
  }

  if (open(PROC_VERSION, '</proc/version')) {
    my $line;
    if (defined($line = <PROC_VERSION>)) {
      close PROC_VERSION;
      if ($line =~ /gcc version (egcs-)?(\d+(\.\d+)*)/) {
        $kernel_gcc_version = $2;
        if ($kernel_gcc_version eq $gSystem{'gcc_version'}) {
          return 'yes';
        }
      }
    } else {
      close PROC_VERSION;
    }
  }
  my $msg;
  my $g_major = '0';
  if ($gSystem{'gcc_version'} =~ /^(\d+)\./) {
    $g_major = $1;
  }
  if (defined($kernel_gcc_version)) {
    my $k_major = '0';
    my $k_minor = '0';

    if ($kernel_gcc_version =~ /^(\d+)\.(\d+)/) {
      $k_major = $1;
      $k_minor = $2;
    }

    if ($g_major ne $k_major) {
      ***REMOVED*** Try a to find a gcc-x.y binary
      my $newGcc = internal_which("gcc-$k_major.$k_minor");
      if ($newGcc ne '') {
	***REMOVED*** We found one, we need to update the global values.
	$gHelper{'gcc'} = $newGcc;
	$gSystem{'gcc_version'} = get_gcc_version($newGcc);
	if ($gSystem{'gcc_version'} eq 'no') {
	  return 'no';
        } else {
	  $gSystem{'gcc_version'} =~ /^(\d+)\./;
	  $g_major = $1;
	  if ($kernel_gcc_version eq $gSystem{'gcc_version'}) {
	    return 'yes';
	  }
	}
      }
    }
    $msg = 'Your kernel was built with "gcc" version "' . $kernel_gcc_version .
           '", while you are trying to use "' . $gHelper{'gcc'} .
           '" version "' . $gSystem{'gcc_version'} . '". ';
    if ($g_major ne $k_major) {
      $msg .= 'This configuration is not supported and ' .
              vmware_product_name() . ' cannot work in such configuration. ' .
              'Please either recompile your kernel with "' . $gHelper{'gcc'} .
              '" version "'. $gSystem{'gcc_version'} . '", or restart ' . $0 .
              ' with CC environment variable pointing to the "gcc" version "' .
              $kernel_gcc_version . '".' . "\n\n";
      print wrap($msg, 0);
      return 'no';
    }
    $msg .= 'This configuration is not recommended and ' .
            vmware_product_name() . ' may crash if you\'ll continue. ' .
            'Please try to use exactly same compiler as one used for ' .
            'building your kernel. Do you want to go with compiler "' .
            $gHelper{'gcc'} .'" version "' . $gSystem{'gcc_version'} .'" anyway?';
  }
  if (defined($msg) and get_answer($msg, 'yesno', 'no') eq 'no') {
    return 'no';
  }
  return 'yes';
}

***REMOVED*** Determine whether it is remotely plausible to build a module from source
sub can_build_module {
  my $name = shift;

  if (vmware_product() eq 'tools-for-freebsd' ||
      vmware_product() eq 'tools-for-solaris') {
      return 'no'; ***REMOVED*** Right now we only build tools from source on Linux
  }

  return 'yes';
}

***REMOVED*** Build a module
sub build_module {
  my $name = shift;
  my $dir = shift;
  my $ideal = shift;
  my $build_dir;
  my $gcc_version;

  ***REMOVED*** Lazy initialization
  if ($gFirstModuleBuild == 1) {
    my $program;
    my $headerdir;

    foreach $program ('make', 'echo', 'tar', 'rm') {
      if (not defined($gHelper{$program})) {
        $gHelper{$program} = DoesBinaryExist_Prompt($program);
        if ($gHelper{$program} eq '') {
          return 'no';
        }
      }
    }

    if (get_cc() eq '') {
      return 'no';
    }

    $gSystem{'gcc_version'} = get_gcc_version($gHelper{'gcc'});
    if ($gSystem{'gcc_version'} eq 'no') {
      return 'no';
    }

    if (check_gcc_version() eq 'no') {
      return 'no';
    }

    ***REMOVED*** When installing the modules, kernels 2.4+ setup a symlink to the kernel
    ***REMOVED*** source directory
    $headerdir = $cKernelModuleDir . '/preferred/build/include';
    if (($gOption{'kernel_version'} ne '') or (check_answer_headerdir($headerdir, 'default') eq '')) {
      $headerdir = $cKernelModuleDir . '/' .
                   (($gOption{'kernel_version'} eq '')?
                    $gSystem{'uts_release'}:
                    $gOption{'kernel_version'})
                   . '/build/include';
      if (check_answer_headerdir($headerdir, 'default') eq '') {
        ***REMOVED*** Use a default usual location
        $headerdir = '/usr/src/linux/include';
      }
    }
    db_remove_answer("HEADER_DIR");
    get_persistent_answer('What is the location of the directory of C header '
                          . 'files that match your running kernel?',
                          'HEADER_DIR', 'headerdir', $headerdir);

    $gFirstModuleBuild = 0;
  }

  print wrap('Extracting the sources of the ' . $name . ' module.' . "\n\n",
             0);
  $build_dir = make_tmp_dir($cTmpDirPrefix);

  if (system(shell_string($gHelper{'tar'}) . ' -C ' . shell_string($build_dir)
             . ' -xopf ' . shell_string($dir . '/' . $name . '.tar'))) {
    print wrap('Unable to untar the "' . $dir . '/' . $name . '.tar'
               . '" file in the "' . $build_dir . '" directory.' . "\n\n", 0);
    return 'no';
  }

  print wrap('Building the ' . $name . ' module.' . "\n\n", 0);
  if (system(shell_string($gHelper{'make'}) . ' -C '
             . shell_string($build_dir . '/' . $name . '-only')
             . ' auto-build ' . (($gSystem{'smp'} eq 'yes') ? 'SUPPORT_SMP=1 '
                                                            : '')
             . (($gOption{'kernel_version'} ne '')?
                 shell_string('VM_UNAME=' . $gOption{'kernel_version'}) . ' ':'')
             . shell_string('HEADER_DIR=' . db_get_answer('HEADER_DIR')) . ' '
             . shell_string('CC=' . $gHelper{'gcc'}) . ' '
             . shell_string('GREP=' . $gHelper{'grep'}) . ' '
             . shell_string('IS_GCC_3='
             . (($gSystem{'gcc_version'} =~ /^3\./) ? 'yes' : 'no')))) {
    print wrap('Unable to build the ' . $name . ' module.' . "\n\n", 0);
    return 'no';
  }

  if ($gOption{'kernel_version'} eq '') {
    ***REMOVED*** Don't use the force flag: the module is supposed to perfectly load
    if (try_module($name, $build_dir . '/' . $name . '.o', 0, 1)) {
      print wrap('The ' . $name . ' module loads perfectly into the running kernel.'
                 . "\n\n", 0);
      return 'yes';
    }
  } else {
    print wrap('Not trying to load the module as it is for a different kernel version.' . "\n\n", 0);
    return 'yes';
  }
  ***REMOVED*** Don't remove the build dir so that the user can investiguate
  print wrap('Unable to make a ' . $name . ' module that can be loaded in the '
             . 'running kernel:' . "\n", 0);
  try_module($name, $build_dir . '/' . $name . '.o', 0, 0);
  ***REMOVED*** Try to analyze some usual suspects
  if ($gSystem{'build_bug'} eq 'yes') {
    print wrap('It appears that your running kernel has not been built from a '
               . 'kernel source tree that was completely clean (i.e. the '
               . 'person who built your running kernel did not use the "make '
               . 'mrproper" command).  You may want to ask the provider of '
               . 'your Linux distribution to fix the problem.  In the '
               . 'meantime, you can do it yourself by rebuilding a kernel '
               . 'from a kernel source tree that is completely clean.'
               . "\n\n", 0);
  } else {
    print wrap('There is probably a slight difference in the kernel '
               . 'configuration between the set of C header files you '
               . 'specified and your running kernel.  You may want to rebuild '
               . 'a kernel based on that directory, or specify another '
               . 'directory.' . "\n\n", 0);
  }
  return 'no';
}

***REMOVED*** Identify specific characteristics of the SuSE distro we're running on.
***REMOVED*** Takes a hash reference as a parameter.  Fills hash with the following:
***REMOVED***   variant       'sle' or 'opensuse', if defined
***REMOVED***   version       version string (e.g., '10' or '11.0'), if defined
***REMOVED***   patchlevel    patchlevel string (e.g., '1'), if defined
***REMOVED*** The caller is responsible for determining that we're running on some
***REMOVED*** version of SuSE.
sub identify_suse_variant {
  my %propRef;
  if (not open(FH, '</etc/SuSE-release')) {
    error("Unable to open /etc/SuSE-release in read-only mode.\n\n");
  }
  while (<FH>) {
    chomp;
    if (/^SUSE Linux Enterprise/) {
      $propRef{'variant'} = 'sle';
    } elsif (/^openSUSE/) {
      $propRef{'variant'} = 'opensuse';
    } elsif (/^VERSION\s+=\s+(.+)$/) {
      $propRef{'version'} = $1;
    } elsif (/^PATCHLEVEL\s+=\s+(.+)$/) {
      $propRef{'patchlevel'} = $1;
    }
  }
  close(FH);
  return %propRef;
}

***REMOVED*** Converts version to the opaque token - if tokens from two kernels
***REMOVED*** are identical, these two kernels are probably ABI compatible.
***REMOVED*** This is done for RHEL 3, 4, and 5, and for SLES 10 and 11.
sub get_module_compatible_version {
  my $utsrel = shift;

  ***REMOVED*** RHEL3: 2.4.21-9.0.1.ELhugemem => 2.4.21-ELhugemem
  ***REMOVED*** RHEL4: 2.6.9-11.ELsmp => 2.6.9-ELsmp
  if ($utsrel =~ /^(\d+\.\d+\.\d+-)[0-9.]+\.(EL.*)$/) {
    return $1.$2;
  }
  ***REMOVED*** RHEL5: 2.6.18-8.1.1.el5 => 2.6.18-el5
  if ($utsrel =~ /^(\d+\.\d+\.\d+-)[0-9.]+\.(el.*)$/) {
    return $1.$2;
  }
  ***REMOVED*** SLES 10/11: 2.6.16.46-0.12-default => 2.6.16.46-default
  if ($gSystem{'distribution'} eq 'suse') {
    my %prop = identify_suse_variant();
    if (defined($prop{'variant'}) and $prop{'variant'} eq 'sle' and
        defined($prop{'version'}) and $prop{'version'} =~ /^1[01]/) {
      if ($utsrel =~ /^(\d\.\d\.\d+\.\d+)-[0-9.]+(-.*)$/) {
        return $1.$2;
      }
    }
  }
  return $utsrel;
}

***REMOVED*** Create a list of modules suitable for the running kernel
***REMOVED*** The kernel module loader does quite a good job when modules are versioned.
***REMOVED*** But in the other case, we must be _very_ careful
sub get_suitable_modules {
  my $dir = shift;
  my @perfect = ();
  my @compatible = ();
  my @dangerous = ();
  my $candidate;
  my $uts_release = $gSystem{'uts_release'};
  my $uts_compatible = get_module_compatible_version($uts_release);

  foreach $candidate (internal_ls($dir)) {
    my %prop;
    my $list;

    ***REMOVED*** Read the properties file
    if (not open(PROP, '<' . $dir . '/' . $candidate . '/properties')) {
      print STDERR wrap('Unable to open the property file "' . $dir . '/'
                        . $candidate . '/properties".  Skipping this kernel.'
                        . "\n\n", 0);
      next;
    }
    undef %prop;
    while (<PROP>) {
      if (/^UtsVersion (.+)$/) {
        $prop{'UtsVersion'} = $1;
      } elsif (/^(\S+) (\S+)/) {
        $prop{$1} = $2;
      }
    }
    close(PROP);

    if (not (lc($gSystem{'smp'}) eq lc($prop{'SMP'}))) {
      ***REMOVED*** SMP does not match
      next;
    }
    if (defined($gSystem{'page_offset'}) and
        not (lc($gSystem{'page_offset'}) eq lc($prop{'PageOffset'}))) {
      ***REMOVED*** Page offset does not match
      next;
    }

    ***REMOVED*** Check if the kernel is from the Athlon family of kernels (athlon, k[78]).
    ***REMOVED*** If the kernel is compiled for Athlon processors, then we should only use
    ***REMOVED*** PBMs that are compiled for Athlon Kernels.  Otherwise... don't use the
    ***REMOVED*** Athlon modules at all.  See bug 360476 for more details.
    ***REMOVED***
    ***REMOVED*** Note: Assume (for now) that if AthlonKernel is not defined, then
    ***REMOVED*** this PBM is forbidden from running on AthlonKernels
    if ($gSystem{'athlonKernel'} eq 'yes') {
       ***REMOVED*** Then we should only load modules that are not forbidden
       if (not defined ($prop{'AthlonKernel'}) or
          (lc ($prop{'AthlonKernel'}) eq 'forbidden')) {
          next;
       }
    } else {
       ***REMOVED*** Then we should skip all PBMs that require Athlon Kernels to run
       if (defined ($prop{'AthlonKernel'}) and
          (lc ($prop{'AthlonKernel'}) eq 'required')) {
          next;
       }
   }

    ***REMOVED*** Confirm that the target architecture of the prebuilt module matches
    ***REMOVED*** that of the running kernel.  If the properties file specified
    ***REMOVED*** the target architecture, and if the specified target architecture does
    ***REMOVED*** not match the running kernel's architecture, this module will get
    ***REMOVED*** skipped.
    if (defined($prop{'UtsMachine'})) {
      if (is64BitKernel()) {
        if ($prop{'UtsMachine'} ne 'x86_64') {
          next;
        }
      } elsif ($prop{'UtsMachine'} ne 'i386') {
        next;
      }
    }

    ***REMOVED*** By default module is not good for anything
    $list = undef;

    ***REMOVED*** If module is versioned, try "compatible" match (ModVersion is requied
    ***REMOVED*** due to 2.4.19-4GB being delivered by both SuSE8.1 and SLES8)
    if (defined($prop{'ModVersion'}) and
        $prop{'ModVersion'} eq 'yes' and
        $uts_compatible eq get_module_compatible_version($prop{'UtsRelease'})) {
      $list = \@compatible;
    }
    ***REMOVED*** If version matches exactly, great.  But only if UtsVersion matches,
    ***REMOVED*** otherwise it is second class match equivalent to the "compatible" match
    if ($uts_release eq $prop{'UtsRelease'}
        && (!defined($prop{'UtsVersion'})
            || $gSystem{'uts_version'} eq $prop{'UtsVersion'})) {
      $list = \@perfect;
    }
    if (defined($list)) {
      push @$list, ($candidate, $prop{'ModVersion'});
    }
  }

  return (@perfect, @compatible, @dangerous);
}

***REMOVED*** Find the first file that exists from the list of files.
***REMOVED*** Returns undefined if none of them exists.
sub find_first_exist {
  my $return_val;
  my $file = shift;
  while (defined $file) {
    if (-e $file) {
      $return_val = $file;
      last;
    }
    $file = shift;
  }
  return $return_val;
}


***REMOVED***
***REMOVED*** Will either return a valid path to the GCC bin or will return
***REMOVED*** nothing.
***REMOVED***
sub getValidGccPath {
  my $gcc_path = shift;
  my $modconfig = shift;
  my $appLoaderArgs = shift;
  my $answer;
  my $query;
  my $default;

  while (1) {
    if (system("$modconfig --validate-gcc \"$gcc_path\" $appLoaderArgs " .
	       ">/dev/null 2>&1") == 0) {
      $query = "The path \"$gcc_path\" appears to be a valid path to the " .
	       "gcc binary.";
      $default = 'no';
    } else {
      $query = "The path \"$gcc_path\" is not valid path to the gcc binary.";
      $default = 'yes';
      $gcc_path = '';
    }

    $answer = get_answer($query . "\n Would you like to change it?",
			 'yesno', $default);
    if ($answer eq 'yes') {
      ***REMOVED*** Get new path.
      $gcc_path = query('What is the location of the gcc program ' .
			'on your machine?', $gcc_path, 0);
    } else {
      last;
    }
  }
  return $gcc_path;
}


***REMOVED***
***REMOVED*** Will either return a valid path to the kernel headers or will return
***REMOVED*** nothing.
***REMOVED***
sub getValidKernelHeadersPath {
  my $kh_path = shift;
  my $modconfig = shift;
  my $appLoaderArgs = shift;
  my $answer;
  my $query;
  my $default;

  ***REMOVED*** Handle the --kernel_version flag
  my $kInQuestion = getKernRel();
  my $mcKverOpt = "-k $kInQuestion";

  while (1) {
    if (system("$modconfig --validate-kernel-headers $mcKverOpt \"$kh_path\" " .
	       "$appLoaderArgs >/dev/null 2>&1") == 0) {
      $query = "The path \"$kh_path\" appears to be a valid path to the " .
               "$kInQuestion kernel headers.";
      $default = 'no';
    } else {
       $query = "The path \"$kh_path\" is not a valid path to the " .
                "$kInQuestion kernel headers.";
       $default = 'yes';
       $kh_path = '';
    }

    $answer = get_answer($query . "\n Would you like to change it?",
			 'yesno', $default);
    if ($answer eq 'yes') {
      ***REMOVED*** Get new path.
      $kh_path = query('Enter the path to the kernel header files for the ' .
                       "$kInQuestion kernel?", $kh_path, 0);
    } else {
      last;
    }
  }
  return $kh_path;
}

***REMOVED***
***REMOVED*** Asks the user if they want to compile modules for linux.
***REMOVED*** Display the requirements and check to see if they have a valid path
***REMOVED*** to both GCC and their kernel headers.
***REMOVED***
sub compile_module_linux {
  my $moduleName = shift;
  my $modconfig = shift;
  my $moduleDest = shift;
  my $destName = shift;
  my $appLoaderArgs = shift;
  my $makePath;
  my $msg;

  ***REMOVED*** Handle the --kernel_version flag
  my $mcKverOpt = "-k " . getKernRel();

  if ($gFirstModuleBuild == 1) {
    $gFirstModuleBuild = 0;
    $makePath = internal_which('make');
    $gGccPath = `$modconfig --get-gcc $appLoaderArgs`;
    $gKernelHeaders = `$modconfig --get-kernel-headers $mcKverOpt $appLoaderArgs`;

    ***REMOVED*** XXX important...
    ***REMOVED*** Check to make sure the installation is interactive.
    ***REMOVED*** If it is not, DO NOT ask questions.
    if ($gOption{'default'} eq 0) {
    print wrap("\n" .
	       "Before you can compile modules, you need to have the " .
	       "following installed... \n" .
	       "\n" .
	       "   make\n" .
	       "   gcc\n" .
	       "   kernel headers of the running kernel\n" .
	       "\n" .
               "\n", 0);

      ***REMOVED*** Print out some helpful info so the users know if we were able
      ***REMOVED*** to detect gcc/kernel headers on our own.
      print wrap("Searching for GCC...\n", 0);
      if ("$gGccPath" ne '' and system("$modconfig --validate-gcc " .
				       "\"$gGccPath\" $appLoaderArgs") == 0) {
	print wrap("Detected GCC binary at \"$gGccPath\".\n", 0);
      }
      $gGccPath = getValidGccPath($gGccPath, $modconfig, $appLoaderArgs);

      print wrap("Searching for a valid kernel header path...\n", 0);
      if ("$gKernelHeaders" ne '' and
	 system("$modconfig --validate-kernel-headers $mcKverOpt " .
                "\"$gKernelHeaders\" $appLoaderArgs") == 0) {
	print wrap("Detected the kernel headers at " .
		   "\"$gKernelHeaders\".\n", 0);
      }
      $gKernelHeaders = getValidKernelHeadersPath($gKernelHeaders, $modconfig,
						  $appLoaderArgs);
    }

    ***REMOVED*** Now check everything and if any check fails, let the user know why.
    ***REMOVED***
    ***REMOVED*** Currently modconfig will find make on its own.  So if make is not
    ***REMOVED*** in the PATH, then the compile will fail.  We check form make below so if
    ***REMOVED*** there is no make, our users will know exactly why we can't compile our
    ***REMOVED*** modules.
    if ("$makePath" ne '' and "$gGccPath" ne '' and "$gKernelHeaders" ne ''){
      $gCanCompileModules = 1;
    } else {
      $msg = "\nWARNING: This program cannot compile any modules for " .
	      "the following reason(s)...\n";
      if ("$makePath" eq '') {
	$msg .= " - This program could not find a valid path to make.  " .
	        "Please ensure that the make binary is installed " .
		"in the system path.\n\n";
      }
      if ("$gGccPath" eq '') {
	$msg .= " - This program could not find a valid path to the gcc " .
		"binary.  Please ensure that the gcc binary is " .
		"installed on this sytem.\n\n";
      }
      if ("$gKernelHeaders" eq '') {
	$msg .= " - This program could not find a valid path to the " .
		"kernel headers of the running kernel.  Please " .
		"ensure that the header files for the running kernel " .
		"are installed on this sytem.\n\n";
      }
      query($msg, ' Press Enter key to continue ', 0);
    }
  }

  ***REMOVED*** Now if we can compile the modules, make it happen.  Otherwise just
  ***REMOVED*** skip past this part.
  if ($gCanCompileModules eq 1) {
    unless (system(sprintf("$modconfig --build-mod %s %s %s %s %s %s $appLoaderArgs",
                           $mcKverOpt,
			   $moduleName,
			   shell_string($gGccPath),
			   shell_string($gKernelHeaders),
                           $moduleDest,
			   $destName)) != 0) {
      return 'yes';
    }
  }

  return 'no';
}

***REMOVED*** Configure a module for Linux using vmware-modconfig-console
sub configure_module_linux {
  my $name = shift;
  my $gcc_path;
  my $kernel_headers;
  my $is64BitUserland = is64BitUserLand();
  my $libdir = db_get_answer('LIBDIR');
  my $libsbindir = $libdir . ($is64BitUserland ? '/sbin64' : '/sbin32');
  my $modconfig = '';
  my $appLoaderArgs = '';
  my $result = 'no';
  my $modDest = get_module_install_dest($name);
  my $destName = get_module_name($name);

  if ($useApploader) {
    $modconfig = shell_string($libsbindir . '/vmware-modconfig-console');
    $appLoaderArgs = "-- -l \"$libdir\"";
  } else {
    $modconfig = 'VMWARE_USE_SHIPPED_GTK=yes ' .
      shell_string($libsbindir . '/vmware-modconfig-console-wrapper');
  }

  ***REMOVED*** First check to see if a PBM is available.  If so, try to install it.
  ***REMOVED***
  ***REMOVED*** Note that there is a check earlier on to ensure that prebuilt and compile
  ***REMOVED*** are mutually exclusive options.
  if ($gOption{'compile'} == 0 and
      system("$modconfig --pbm-available $name $appLoaderArgs") == 0) {
     print wrap("Found a compatible pre-built module for $name.  " .
                "Installing it...\n\n",0);

     if (system("$modconfig --install-pbm $name $modDest " .
                "$destName $appLoaderArgs") != 0) {
        print wrap("Failed to install the $name pre-built module.\n\n",0);
        $result = 'no';
     } else {
        $result = 'yes';
     }
  } elsif ($gOption{'prebuilt'} == 0) {
    ***REMOVED*** Otherwise try to compile it.
    $result = compile_module_linux($name, $modconfig, $modDest,
				   $destName, $appLoaderArgs);
  }

  ***REMOVED*** Because our modules can now change names, we need to maintain some
  ***REMOVED*** variables that tell us our modules names and locations so we can
  ***REMOVED*** use them in our startup scripts.
  if ($result eq 'yes') {
     my $mod_path = join('/',"/lib/modules", getKernRel(), $modDest, $destName);
     db_add_answer(getModDBKey($name, 'NAME'), $destName);
     db_add_answer(getModDBKey($name, 'PATH'), $mod_path);
     $gVmwareInstalledModules{"$name"} = $mod_path;
  }

  ***REMOVED*** Add some space between the compile output and output text.
  print "\n";
  return $result;
}

***REMOVED*** Configure a module
sub configure_module {
  my $name = shift;
  my $mod_dir;

  if (vmware_product() eq 'tools-for-linux') {
    return configure_module_linux($name);
  }

  if (defined($gDBAnswer{'ALT_MOD_DIR'})
      && ($gDBAnswer{'ALT_MOD_DIR'} eq 'yes')) {
    $mod_dir = db_get_answer('LIBDIR') . '/modules.new';
  } else {
    $mod_dir = db_get_answer('LIBDIR') . '/modules';
  }

  if ($gOption{'compile'} == 1
      && can_build_module($name) eq 'yes') {
    db_add_answer('BUILDR_' . $name, 'yes');
  } else {
    my @mod_list;

    @mod_list = get_suitable_modules($mod_dir . '/binary');
    while ($***REMOVED***mod_list > -1) {
      my $candidate = shift(@mod_list);
      my $modversion = shift(@mod_list);

      ***REMOVED*** Note: When using the force flag,
      ***REMOVED***        Non-versioned modules can load into a     versioned kernel.
      ***REMOVED***            Versioned modules can load into a non-versioned kernel.
      ***REMOVED***
      ***REMOVED*** Consequently, it is only safe to use the force flag if _both_ the
      ***REMOVED*** kernel and the module are versioned.
      ***REMOVED*** This is not always the case as demonstrated by bug 18371.
      ***REMOVED***
      ***REMOVED*** I would stop using force flag immediately, it does nothing good.

      if (try_module($name,
                     $mod_dir . '/binary/' . $candidate . '/objects/'
                     . $name . '.o',
                        ($gSystem{'versioned'} eq 'yes')
                     && ($modversion eq 'yes'), 1)) {
        print wrap('The ' . $candidate . ' - ' . $name . ' module '
                 . 'loads perfectly into the ' . 'running kernel.' . "\n\n", 0);
        return 'yes';
      }
    }

    if ($gOption{'prebuilt'} == 1) {
      db_add_answer('BUILDR_' . $name, 'no');
      print wrap('None of the pre-built ' . $name . ' modules for '
		 . vmware_product_name() . ' is suitable for your '
		 . 'running kernel.' . "\n\n", 0);
      return 'no';
    }

    ***REMOVED*** No more building modules for 'ws' unless forced to.
    if (vmware_product() eq 'ws' && !$gOption{'compile'}) {
       ***REMOVED*** don't restart services at the end, no modules are installed
       $gOption{'skip-stop-start'} = 1;
       return 'yes';
    }

    if (can_build_module($name) ne "yes"
	|| get_persistent_answer('None of the pre-built ' . $name . ' modules for '
			      . vmware_product_name() . ' is suitable '
                              . 'for your running kernel.  Do you want this '
                              . 'program to try to build the ' . $name
                              . ' module for your system (you need to have a '
                              . 'C compiler installed on your system)?',
                              'BUILDR_' . $name, 'yesno', 'yes') eq 'no') {
      return 'no';
    }
  }

  if (build_module($name, $mod_dir . '/source') eq 'no') {
    return 'no';
  }
  return 'yes';
}

***REMOVED*** Determines whether a solaris driver is already configured using the provided
***REMOVED*** driver name and alias (alias may be '' if none is required for this driver).
***REMOVED***  Results: yes if configured, no if not
sub solaris_driver_configured {
  my $driver = shift;
  my $alias = shift;

  if (system(shell_string($gHelper{'grep'}) . ' ' . shell_string($driver)
             . ' /etc/name_to_major > /dev/null 2>&1') == 0) {
    if ($alias eq '' ||
        direct_command('grep ' . $driver . ' /etc/driver_aliases') =~ /$alias/) {
      return 'yes';
    }
  }

  return 'no';
}

sub solaris_module_id {
   my $module=shift;
   my $moduleId=undef;

   ***REMOVED*** tail +2 skips the header line (why is it not +1?)
   open(MODINFO, 'modinfo | tail +2 |');
   while (<MODINFO>) {
     s/^\ +//;
     my @modinfo = split(/[ ]+/, $_);
     if ($module eq $modinfo[5]) {
        $moduleId=$modinfo[0];
     }
   }
   close(MODINFO);

   return $moduleId;
}

sub solaris_os_version {
  my $solVersion = direct_command(shell_string($gHelper{'uname'}) . ' -r');
  chomp($solVersion);
  my ($major, $minor) = split /\./, $solVersion;
  return ($major, $minor);
}

sub solaris_os_name {
  my $solName = direct_command(shell_string($gHelper{'uname'}) . ' -v');
  chomp($solName);
  return  $solName;
}

sub solaris_11_or_greater {
  my ($major, $minor) = solaris_os_version();

  if ($major > 5 || ($major == 5 &&  $minor >= 11)) {
    return 'yes';
  }

  return 'no';
}

sub solaris_10_or_greater {
  my ($major, $minor) = solaris_os_version();

  if ($major > 5 || ($major == 5 &&  $minor >= 10)) {
    return 'yes';
  }

  return 'no';
}

sub solaris_is_opensolaris {
  my ($major, $minor) = solaris_os_version();
  my $name = solaris_os_name();

  if ($minor == 11 && $name =~ m/^snv/) {
    return 'yes';
  }

  return 'no';
}


sub configure_module_solaris {
  my $module = shift;
  my %patch;
  my $dir = db_get_answer('LIBDIR') . '/modules/binary/';
  my ($major, $minor) = solaris_os_version();
  my $os_name = solaris_os_name();
  my $osDir;
  my $osFlavorDir;
  my $currentMinor = 10;   ***REMOVED*** The most recent version we build the drivers for

  if (solaris_10_or_greater() ne "yes") {
    print "VMware Tools for Solaris is only available for Solaris 10 and later.\n";
    return 'no';
  }

  if ($minor < $currentMinor) {
    $osDir = $minor;
  } else {
    $osDir = $currentMinor;
  }

  if ($os_name eq 'snv_111b') {
     $osFlavorDir = 2009.06;
  } else {
     $osFlavorDir = $osDir;
  }

  if ($module eq 'vmmemctl') {
    if ($minor == 11 && solaris_is_opensolaris() ne 'yes') {
       ***REMOVED*** On Solaris 11 kernel thread structure changed to we need to
       ***REMOVED*** use driver compiled for official Solaris 11
       $osDir = $minor;
    }

    ***REMOVED*** Install the corresponding 32-bit driver
    undef %patch;
    install_file($dir . $osDir . '/vmmemctl',
                 '/kernel/drv/vmmemctl', \%patch, $cFlagTimestamp);

    undef %patch;
    install_file($dir . $osDir . '_64/vmmemctl',
                 '/kernel/drv/amd64/vmmemctl', \%patch, $cFlagTimestamp);

    db_add_answer('VMMEMCTL_CONFED', 'yes');
    return 'yes';
  }

  if ($module eq 'vmhgfs') {
    my $newMinor;

    ***REMOVED*** vmhgfs is supported on Solaris 11
    if ($minor == 11) {
       $newMinor = $minor;
    } else {
       $newMinor = $osDir;
    }

    undef %patch;
    install_file($dir . $newMinor . '/vmhgfs',
                 '/kernel/drv/vmhgfs', \%patch, $cFlagTimestamp);

   undef %patch;
   install_file($dir . $newMinor . '_64/vmhgfs',
                '/kernel/drv/amd64/vmhgfs', \%patch, $cFlagTimestamp);

    ***REMOVED*** configure_vmhgfs() is nice enough to add the VMHGFS_CONFED entry for us
    return 'yes';
  }

  if ($module eq 'vmblock') {
    my $newMinor;

    if ($minor == 11) {
       $newMinor = $minor;
    } else {
       $newMinor = $osDir;
    }

    undef %patch;
    install_file($dir . $newMinor . '/vmblock',
                 '/kernel/drv/vmblock', \%patch, $cFlagTimestamp);

    undef %patch;
    install_file($dir . $newMinor . '_64/vmblock',
                 '/kernel/drv/amd64/vmblock', \%patch, $cFlagTimestamp);

    ***REMOVED*** configure_vmblock() is nice enough to add the VMBLOCK_CONFED entry for us
    return 'yes';
  }

  if ($module eq 'vmxnet') {

    my $pcnId;
    undef %patch;

    ***REMOVED*** Remove pcn's hold on "pci1022,2000".
    ***REMOVED*** Note that it's okay if this fails since the module can't be removed;
    ***REMOVED*** /etc/driver_aliases will still be updated and the change will take
    ***REMOVED*** effect on ***REMOVED***.
    system(shell_string($gHelper{'update_drv'}) . ' -d -i \'"pci1022,2000"\' '
                        . 'pcn >/dev/null 2>&1');

    ***REMOVED*** Installation of the vmxnet driver is comprised of placing the driver in
    ***REMOVED*** /kernel/drv and adding it to the system with add_drv(1M).  add_drv(1M)
    ***REMOVED*** usually handles adding an entry to /etc/driver_aliases, loading the
    ***REMOVED*** module and invoking devfsadm(1M) to add appropriate symlinks from /dev
    ***REMOVED*** to /devices.  Here we are only concerned with installing the driver on
    ***REMOVED*** the system (this should be done regardless of whether the VM currently
    ***REMOVED*** has a vmxnet device), and save the module loading and /dev symlinks
    ***REMOVED*** until there actually is a device.  As such, we invoke add_drv(1M) with
    ***REMOVED*** the -n flag so the driver is not loaded.  Later, in our /etc/init.d
    ***REMOVED*** script, we look for the vmxnet device and invoke devfsadm(1M) manually
    ***REMOVED*** ourselves (we don't invoke modload(1M) since the module is automatically
    ***REMOVED*** loaded when the interface is brought up).  More explicitly:
    ***REMOVED***  Here:   $ cp vmxnet /kernel/drv
    ***REMOVED***  Here:   $ /usr/sbin/add_drv -n -m '* 0600 root sys' \
    ***REMOVED***                              -i '"pci15ad,720" "pci1022,2000"' vmxnet
    ***REMOVED***  init.d: $ /usr/sbin/devfsadm -i vmxnet
    install_file($dir . $osFlavorDir . '/vmxnet', '/kernel/drv/vmxnet', \%patch, $cFlagTimestamp);

    undef %patch;
    install_file($dir . $osFlavorDir . '_64/vmxnet',
                 '/kernel/drv/amd64/vmxnet', \%patch, $cFlagTimestamp);

    ***REMOVED*** Prevent adding the driver if we already have; prevents errors on two
    ***REMOVED*** successive invocations of this script
    if (solaris_driver_configured('vmxnet', 'pci15ad,720') eq 'no') {
      system(shell_string($gHelper{'add_drv'}) . ' -n -m \'* 0600 root sys\''
             . ' -i \'"pci15ad,720" "pci1022,2000"\' vmxnet >/dev/null 2>&1');
    }
    migrate_network_files('/etc/hostname.pcn', '/etc/hostname.vmxnet', 'vmx');
    migrate_network_files('/etc/hostname6.pcn', '/etc/hostname6.vmxnet', 'vmx6');
    migrate_network_files('/etc/dhcp.pcn', '/etc/dhcp.vmxnet', 'dhcp');

    db_add_answer('VMXNET_CONFED', 'yes');
    return 'yes';
  }

  if ($module eq 'vmxnet3s') {
    my $result = 'no';
    my $options = '';

    ***REMOVED*** First copy vmxnet3s.conf to /kernel/drv/
    undef %patch;
    install_file($dir . $osFlavorDir . '/vmxnet3s.conf',
                 '/kernel/drv/vmxnet3s.conf',
                 \%patch, $cFlagTimestamp);
    ***REMOVED*** Then copy the module to /kernel/drv/ and /kernel/drv/amd64
    undef %patch;
    install_file($dir . $osFlavorDir . '/vmxnet3s',
                 '/kernel/drv/vmxnet3s',
                 \%patch, $cFlagTimestamp);
    undef %patch;
    install_file($dir . $osFlavorDir . '_64/vmxnet3s',
                 '/kernel/drv/amd64/vmxnet3s',
                 \%patch, $cFlagTimestamp);

    unless(solaris_11_or_greater() eq 'yes') {
      ***REMOVED*** In Solaris 11, the -n option leaves the driver in a bad state, and
      ***REMOVED*** devfsadm will not rescue it. See bug ***REMOVED***849803.
      $options = ' -n';
    }
    ***REMOVED*** Check if the module is already configured, otherwise run add_drv
    if (solaris_driver_configured('vmxnet3s', 'pci15ad,7b0') eq 'no') {
      system(shell_string($gHelper{'add_drv'}) . $options . ' -m \'* 0600 root sys\''
             . ' -i \'"pci15ad,7b0"\' vmxnet3s >/dev/null 2>&1');
    }
    $result = 'yes';

    db_add_answer('VMXNET3S_CONFED', $result);
    return $result;
  }

  if ($module eq 'vmci') {
    my $result = 'no';

    ***REMOVED*** Install the corresponding 32-bit driver
    undef %patch;
    install_file($dir . $osDir . '/vmci.conf',
                 '/kernel/drv/vmci.conf', \%patch, $cFlagTimestamp);
    undef %patch;
    install_file($dir . $osDir . '/vmci',
                 '/kernel/drv/vmci', \%patch, $cFlagTimestamp);

    ***REMOVED*** Also install the 64-bit version
    undef %patch;
    install_file($dir . $osDir . '_64/vmci',
                 '/kernel/drv/amd64/vmci', \%patch, $cFlagTimestamp);

    if (solaris_driver_configured('vmci', '') eq 'no') {
        system(shell_string($gHelper{'add_drv'}) . ' vmci >/dev/null 2>&1');
    }
    $result = 'yes';

    db_add_answer('VMCI_CONFED', $result);
    return $result;
  }

  return 'no';
}

***REMOVED***
***REMOVED*** Look for all of the network nodes based on the paths passed in and
***REMOVED*** copy from the first to the second.  In particular, when moving from
***REMOVED*** the pcnet driver on a 32bit machine to the vmxnet driver, the files
***REMOVED*** in etc, /etc/hostname.pcnet0, /etc/dhcp.pcn0, ..., need to reflect
***REMOVED*** the new vmxnet driver: /etc/hostname.vmxnet0, /etc/dhcp.vmxnet0.
***REMOVED***
sub migrate_network_files {
    my $index = 0;
    my $src_base = shift;
    my $trgt_base = shift;
    my $Id = shift;

    my $src = $src_base . $index;
    while (file_name_exist($src)) {
      my $trgt = $trgt_base  . $index;
      if ( ! -e $trgt) {
        system(shell_string($gHelper{'cp'}) . ' ' . $src . ' ' . $trgt);
        db_add_file($trgt, 0);
        backup_file_to_restore($src, 'SOLARIS_NET_' . $index . '_' . $Id);
      }
      $index++;
      $src = $src_base . $index;
    }
}

sub configure_module_bsd {
  my $module = shift;
  my %patch;
  my $dir = db_get_answer('LIBDIR') . '/modules/binary/FreeBSD';
  my $BSDModPath;
  my $moduleArch;
  my $moduleConfed = 'no';
  my $freeBSDVersion = getFreeBSDVersion();
  my $moduleVersion = '0.0';

  if (dot_version_compare("$freeBSDVersion", '8.1') >= 0) {
    $moduleVersion = '8.1';
  } elsif (dot_version_compare("$freeBSDVersion", '8.0') >= 0) {
    $moduleVersion = '8.0';
  } elsif (dot_version_compare("$freeBSDVersion", '7.3') >= 0) {
    $moduleVersion = '7.3';
  } elsif (dot_version_compare("$freeBSDVersion", '7.1') >= 0) {
    $moduleVersion = '7.1';
  } elsif (dot_version_compare("$freeBSDVersion", '7.0') >= 0) {
    $moduleVersion = '7.0';
  } elsif (dot_version_compare("$freeBSDVersion", '6.3') >= 0) {
    $moduleVersion = '6.3';
  } else {
    ***REMOVED*** If we get here, then tools is not supported.  Error out.
    error ('Tools is not supported on FreeBSD < 6.3.  ' .
	   "Detected FreeBSD version $freeBSDVersion.\n");
  }

  $BSDModPath = '/boot/modules';

  if (is64BitKernel()) {
    $moduleArch = "amd64";
  } else {
    $moduleArch = "i386";
  }

  if ($module eq 'vmmemctl') {
    undef %patch;
    install_file($dir . $moduleVersion . '-' . $moduleArch . '/vmmemctl.ko',
		 $BSDModPath . '/vmmemctl.ko',
		 \%patch, $cFlagTimestamp);
    $moduleConfed = 'yes';

     db_add_answer('VMMEMCTL_CONFED', $moduleConfed);
  } elsif ($module eq 'vmxnet') {
    undef %patch;
    install_file($dir . $moduleVersion . '-' . $moduleArch . '/vmxnet.ko',
		 $BSDModPath . '/vmxnet.ko',
		 \%patch, $cFlagTimestamp);
    $moduleConfed = 'yes';

    ***REMOVED*** Configure autoloading only if vmxnet_load is not mentioned in
    ***REMOVED*** loader config.  Besides that it fixes /boot/loader.conf growing
    ***REMOVED*** without limits we now honor administrator decision to disable
    ***REMOVED*** vmxnet loading.
    ***REMOVED*** We look for vmxnet_load even in the middle of line, so administrator
	***REMOVED*** can just comment out vmxnet_load line instead of setting it to NO.
    if (not block_match('/boot/loader.conf', 'vmxnet_load=')) {
      block_append('/boot/loader.conf',
		   $cMarkerBegin,
		   'vmxnet_load="YES"' . "\n",
		   $cMarkerEnd);
    }
    db_add_answer('VMXNET_CONFED', $moduleConfed);
  } elsif ($module eq 'vmxnet3' && ($moduleVersion eq '8.0' || $moduleVersion eq '8.1')) {
    undef %patch;
    install_file($dir . $moduleVersion . '-' . $moduleArch . '/vmxnet3.ko',
		 $BSDModPath . '/vmxnet3.ko',
		 \%patch, $cFlagTimestamp);
    $moduleConfed = 'yes';

    ***REMOVED*** Configure autoloading only if vmxnet3_load is not mentioned in
    ***REMOVED*** loader config.  Besides that it fixes /boot/loader.conf growing
    ***REMOVED*** without limits we now honor administrator decision to disable
    ***REMOVED*** vmxnet3 loading.
    ***REMOVED*** We look for vmxnet3_load even in the middle of line, so administrator
	***REMOVED*** can just comment out vmxnet3_load line instead of setting it to NO.
    if (not block_match('/boot/loader.conf', 'vmxnet3_load=')) {
      block_append('/boot/loader.conf',
		   $cMarkerBegin,
		   'vmxnet3_load="YES"' . "\n",
		   $cMarkerEnd);
    }
    db_add_answer('VMXNET3_CONFED', $moduleConfed);
  } elsif ($module eq 'vmhgfs') {
    undef %patch;
    install_file($dir . $moduleVersion . '-' . $moduleArch . '/vmhgfs.ko',
		 $BSDModPath . '/vmhgfs.ko',
		 \%patch, $cFlagTimestamp);
    $moduleConfed = 'yes';
    db_add_answer('VMHGFS_CONFED', $moduleConfed);
  } elsif ($module eq 'vmblock') {
    undef %patch;
    install_file($dir . $moduleVersion . '-' . $moduleArch . '/vmblock.ko',
		 $BSDModPath . '/vmblock.ko',
		 \%patch, $cFlagTimestamp);
    $moduleConfed = 'yes';
    db_add_answer('VMBLOCK_CONFED', $moduleConfed);
  }
  return $moduleConfed;
}

***REMOVED*** Create a device name
sub configure_dev {
   ***REMOVED*** Call the below function with 0 flags to ensure we don't timestamp file
   configure_dev_flags(shift, shift, shift, shift, 0);
}

sub configure_dev_flags {
  my $name = shift;
  my $major = shift;
  my $minor = shift;
  my $chr = shift;
  my $flags = shift;
  my $type;
  my $typename;

  if ($chr == 1) {
    $type = 'c';
    $typename = 'character';
  }
  else {
    $type = 'b';
    $typename = 'block';
  }
  uninstall_file($name);
  if (-e $name) {
    if (-c $name) {
      my @statbuf;

      @statbuf = stat($name);
      if (   defined($statbuf[6])
          && (($statbuf[6] >> 8) == $major)
          && (($statbuf[6] & 0xFF) == $minor)
          && ($chr == 1 && ($statbuf[2] & 0020000) != 0 ||
               $chr == 0 && ($statbuf[2] & 0020000) == 0)) {
         ***REMOVED*** The device is already correctly configured
         return;
      }
    }

    if (get_answer('This program wanted to create the ' . $typename . ' device '
                   . $name . ' with major number ' . $major . ' and minor '
                   . 'number ' . $minor . ', but there is already a different '
                   . 'kind of file at this location.  Overwrite?', 'yesno',
                   'yes') eq 'no') {
      error('Unable to continue.' . "\n\n");
    }

  }

  if (system('rm -f ' . shell_string($name) . ' && ' . shell_string($gHelper{'mknod'})
             . ' ' . shell_string($name) . ' ' . shell_string($type) . ' '
             . shell_string($major) . ' ' . shell_string($minor))) {
    error('Unable to create the ' . $typename . ' device ' . $name . ' with '
          . 'major number ' . $major . ' and minor number ' . $minor . '.'
          . "\n\n");
  }
  safe_chmod(0600, $name);
  db_add_file($name, $flags);
}

***REMOVED*** Determine whether /dev is populated dynamically
sub is_dev_dynamic {
  if (-e '/dev/.devfs' || -e '/dev/.udev.tdb' || -e '/dev/.udevdb' || -e '/dev/.udev') {
    ***REMOVED*** Either the devfs" or "udev" filesystem is mounted on the "/dev" directory
    return 'yes';
  }

  return 'no';
}

***REMOVED***
***REMOVED*** change_scsi_timeout
***REMOVED***
***REMOVED*** Changes the timeout value of all SCSI devices to the one specified
***REMOVED***
sub change_scsi_timeout {
  my $timeout = shift;
  my @files;
  my $file;
  ***REMOVED*** Now we need to adjust the timeout values here so the user doesn't need
  ***REMOVED*** to ***REMOVED*** their machine before this takes effect.
  @files = </sys/block/sd*>;
  foreach $file (@files) {
    ***REMOVED*** If the block device has a timeout file in its devices folder, then
    ***REMOVED*** set it to $timeout
    $file = $file . '/device/timeout';
    if (-e $file) {
      set_file_contents($file, $timeout);
    }
  }
}

sub get_udev_tags {
   my $adm = internal_which('udevadm');
   chomp($adm);
   if ($adm) {
      $adm = "$adm info";
   } else {  ***REMOVED*** Look for udevinfo
      $adm = internal_which('udevinfo');
      chomp($adm);
   }

   if (! $adm) {
      return {};
   }

   my $device=`$adm -q path -n /dev/sda`;
   my $tree = `$adm -a -p $device`;
   my @scsiNodes = ();
   my @nodeText = ();
   while ($tree =~ m/looking at.+?device (.*?)\n\n/sg) {
      my $txt = $1;
      if ($txt =~ m/{vendor}=="VMware/is) {
         ***REMOVED*** Get the udev device path from this node
         if ($txt =~ m/^'(.*?)':/s) {
            unshift(@scsiNodes, $1);
            unshift(@nodeText, $txt);
         } else {
            die "Could not find Parent Node...\n";
         }
      }
   }
   my $scsi = "";
   my $vendor = "";
   my $model = "";
   for (my $i=0; $i<=$***REMOVED***scsiNodes; $i++) {
      ***REMOVED*** Scan text for specific tags
      my $node = $scsiNodes[$i];
      my $txt = $nodeText[$i];

      ***REMOVED*** SCSI tag
      if ($txt =~ m/(BUS=="scsi")/) {
         $scsi = $1;
      }
      if ($txt =~ m/(SUBSYSTEMS=="scsi")/) {
         $scsi = $1;;
      }

      ***REMOVED*** Vendor tag
      if ($txt =~ m/\s+(\S+{vendor}==".*?")/) {
         $vendor = $1;
      }

      ***REMOVED*** Model tag
      if ($txt =~ m/\s+(\S+{model}==".*?")/) {
         $model = $1;
      }
}

return ("scsi" => $scsi,
        "vendor" => $vendor,
        "model" => $model);
}

***REMOVED***
***REMOVED*** configure_udev_scsi
***REMOVED***
***REMOVED*** Adds a Udev rule for GOS SCSI devices to change the timeout
***REMOVED*** from 60 to 180, and then modifies the timeout so as not to
***REMOVED*** require a ***REMOVED***.  For more info, see Bug 271286
***REMOVED***
sub configure_udev_scsi {
  ***REMOVED*** Check to make sure the Kernel Version is greater than 2.6.13
  if ($gSystem{'version_integer'} < kernel_version_integer(2, 6, 13)) {
    return;
  }

  my %tags = get_udev_tags();
  my $temp_dir = make_tmp_dir($cTmpDirPrefix);
  my $udev_file = "$temp_dir/99-vmware-scsi-udev.rules";

  open FOUT, ">$udev_file";
  print FOUT <<EOF;
***REMOVED***
***REMOVED*** VMware SCSI devices Timeout adjustment
***REMOVED***
***REMOVED*** Modify the timeout value for VMware SCSI devices so that
***REMOVED*** in the event of a failover, we don't time out.
***REMOVED*** See Bug 271286 for more information.

EOF
  print FOUT 'ACTION=="add", ' . $tags{'scsi'} . ', ' . $tags{'vendor'} . ', ' .
             $tags{'model'} . ', RUN+="/bin/sh -c \'echo 180 >/sys$DEVPATH/timeout\'"' . "\n\n";
  close FOUT;

  ***REMOVED*** Install the file
  installUdevRule($udev_file);

  ***REMOVED*** Now change the scsi timeout value to 180
  change_scsi_timeout(180);
}


***REMOVED*** configureDeviceKitVmmouse
***REMOVED***
***REMOVED*** Installs the necessary files to make vmmouse work with
***REMOVED*** device kit.  First it checks to make sure that no vmmouse rules file
***REMOVED*** exists.  If one doesn't exist, then it installs the rule we provide.
***REMOVED*** Also install the Xorg mouse file if it doesn't exist.
***REMOVED***
sub configureDeviceKitVmmouse {
   my $dkRulesSrc = join('/', db_get_answer('LIBDIR'),
                         'configurator/udev/69-vmware-vmmouse.rules');
   my $regex = qr/vmmouse\.rules/;
   my $ruleFound = searchForUdevRule($regex);

   installUdevRule($dkRulesSrc) if (not $ruleFound);

   ***REMOVED*** Now check for the X conf file for vmmouse and install it if we
   ***REMOVED*** don't find the file we are looking for.
   my $dkVmmouseConf = join('/', db_get_answer('LIBDIR'),
                            'configurator/xorg.conf.d/vmmouse.conf');
   my $dstDir = '/usr/lib/X11/xorg.conf.d/';
   my $dst = join('/', $dstDir, '10-vmmouse.conf');
   my %patch;
   undef %patch;

   ***REMOVED*** Currently this only applies to Ubuntu.  Will need to adapt this
   ***REMOVED*** as more distros move to DeviceKit.
   $regex = qr/vmmouse\.conf/;
   if (-d $dstDir and
       not searchDirsForMatchingFile($regex, $dstDir)) {
      install_file($dkVmmouseConf, $dst, \%patch, $cFlagTimestamp);
   }
}

***REMOVED*** searchForUdevRule
***REMOVED***
***REMOVED*** Searches udev rules for file names that match the given regex
***REMOVED*** @param - Regex to match files against.
***REMOVED*** @returns - True if a match was found, false otherwise.
***REMOVED***
sub searchForUdevRule {
   my $regex = shift;
   my @searchDirs = ("/lib/udev/rules.d/", "/etc/udev/rules.d");
   return searchDirsForMatchingFile($regex, @searchDirs);
}


***REMOVED*** searchDirsForMatchingFile
***REMOVED***
***REMOVED*** Searches a given list of directories for a file matching the
***REMOVED*** provided regex.  Return a list of file names that match.
***REMOVED***
sub searchDirsForMatchingFile {
   my $regex = shift;
   my @searchDirs = @_;
   my @matches;

   foreach my $dir (@searchDirs) {
      foreach my $file (internal_ls($dir)) {
         unshift(@matches, "$dir/$file") if ($file =~ $regex);
      }
   }

   return @matches;
}


***REMOVED*** installUdevRule
***REMOVED***
***REMOVED*** Installs a udev rule to the proper location.
***REMOVED*** @param - The path to the rule to install
***REMOVED*** @returns - True if successful, false otherwise.
***REMOVED***
sub installUdevRule {
   my $src = shift;
   my $ruleName = internal_basename($src);
   my $dstDir = '/etc/udev/rules.d';
   my $dst = join('/', $dstDir, $ruleName);
   my %patch;
   undef %patch;

   if (not -e $src or not -d $dstDir) {
      print STDERR "Warning: Could not find $src or $dstDir.\n\n";
      return 0;
   }

   return install_file($src, $dst, \%patch, $cFlagTimestamp);
}


***REMOVED*** Configuration related to the monitor
sub configure_mon {
  if (configure_module('vmmon') eq 'no') {
    module_error();
  }

  if (is_dev_dynamic() eq 'yes') {
    ***REMOVED*** Either the devfs" or "udev" filesystem is mounted on the "/dev" directory,
    ***REMOVED*** so the "/dev/vmmon" block device file is magically created/removed when the
    ***REMOVED*** "vmmon" module is loaded/unloaded (was bug 15571 and 72114)
  } else {
    configure_dev('/dev/vmmon', 10, 165, 1);
  }
}

***REMOVED*** Configuration related to parallel ports
sub configure_pp {
  my $i;

  ***REMOVED*** The parport numbering scheme in 2.2.X is confusing:
  ***REMOVED*** Because devices can be daisy-chained on a port, the first port
  ***REMOVED*** (/proc/parport/0) is /dev/parport0, but the second one (/proc/parport/1)
  ***REMOVED*** is /dev/parport16 (not /dev/parport1), and so on...

  ***REMOVED*** This message is wrong.  I have found no evidence for this.
  ***REMOVED*** On all the linux machines that I've looked at /dev/parport1 is the 2nd port
  ***REMOVED*** That's my story and I'm sticking to it  - DavidE

  if (is_dev_dynamic() eq 'no') {
    for ($i = 0; $i < 4; $i++) {
      configure_dev_flags('/dev/parport' . $i, 99, $i, 1, 0x1);
    }
  }
}

***REMOVED*** Configuration of the vmmemctl tools device
sub configure_vmmemctl {
  my $result;
  if (vmware_product() eq 'tools-for-freebsd') {
    $result = configure_module_bsd('vmmemctl');
  } elsif (vmware_product() eq 'tools-for-solaris') {
    $result = configure_module_solaris('vmmemctl');
  } else {
    ***REMOVED*** First check to make sure we should install this module.
    $result = mod_pre_install_check('vmmemctl');
    if ($result eq 'yes') {
      $result = configure_module('vmmemctl');
      if ($result eq 'no') {
	query('The memory manager driver (vmmemctl module) is used by '
	      . 'VMware host software to efficiently reclaim memory from a '
	      . 'virtual machine.' . "\n"
	      . 'If the driver is not available, VMware host software may '
	      . 'instead need to swap guest memory to disk, which may reduce '
	      . 'performance.' . "\n"
	      . 'The rest of the software provided by '
	      . vmware_product_name()
	      . ' is designed to work independently of '
	      . 'this feature.' . "\n"
	      . 'If you want the memory management feature,'
	      . $cModulesBuildEnv
	      . "\n", ' Press Enter key to continue ', 0);
      }
    }
    module_post_configure('vmmemctl', $result);
  }
}

***REMOVED*** Configuration of the vmhgfs tools device
sub configure_vmhgfs {
  ***REMOVED*** vmhgfs is supported only since 2.4.0 Linux kernels, Solaris 10, and FreeBSD 6.0
  if (   (   vmware_product() eq 'tools-for-linux'
	     && $gSystem{'uts_release'} =~ /^(\d+)\.(\d+)/
	     && $1 * 1000 + $2 >= 2004)
	 || (   vmware_product() eq 'tools-for-solaris'
		&& solaris_10_or_greater())
     ) {
    ***REMOVED*** Add a version check here for FreeBSD
    ***REMOVED*** The check is also NOT in at the moment, as the FreeBSD
    ***REMOVED*** driver is not yet ready for prime time, and not being built.
    ***REMOVED*** this is the line that will need to be uncommented, as well as
    ***REMOVED*** a version check added when it is ready to be added.
    ***REMOVED*** CODE -> || (   vmware_product() eq 'tools-for-freebsd') && <BSD Version Check Here>) {

    ***REMOVED*** By default we don't want HGFS installed in guests runnning on ESX virtual enviroments
    ***REMOVED*** since its useless there.  However we want HGFS to be installed by default on VMs
    ***REMOVED*** running in WS/Fusion virtul environments.  Hence ask users and set the default answer based
    ***REMOVED*** on whether or not we are running in an ESX environment vs a WS/Fusion environment.
    my $defAns = is_esx_virt_env() ? 'no' : 'yes';
    my $hgfsQ = 'The VMware Host-Guest Filesystem allows for shared folders between the ' .
                'host OS and the guest OS in a Fusion or Workstation virtual environment.  ' .
                'Do you wish to enable this feature?';

    ***REMOVED*** Moved the FreeBSD question up here so we don't ask an equivilent question twice.
    ***REMOVED*** Still experimental on FreeBSD.
    if (vmware_product() eq 'tools-for-freebsd') {
        $hgfsQ = '[EXPERIMENTAL] ' . $hgfsQ;
        $defAns = 'no';
    }

    if (get_persistent_answer($hgfsQ, 'ENABLE_HGFS', 'yesno', $defAns) eq 'no') {
       ***REMOVED*** Then disable HGFS.
       disable_module('vmhgfs');
       return;
    }

    my $result;
    my $dispInstallMsg = 1;
    if (vmware_product() eq 'tools-for-linux') {
      if (mod_pre_install_check('vmhgfs') eq 'yes') {
         ***REMOVED*** vmhgfs now depends on vmci.  Check to ensure it's configured.
         if (defined(db_get_answer_if_exists('VMCI_CONFED')) &&
             db_get_answer('VMCI_CONFED') ne 'yes') {
            return 1;
         }
         if (create_dir('/mnt/hgfs', $cFlagDirectoryMark | $cFlagFailureOK)
             != $cCreateDirFailure) {
            $result = configure_module('vmhgfs');
         } else {
            $result = 'no';
            my $msg = "Could not create the '/mnt/hgfs' directory.  Please make sure " .
               "it is writeable and/or not currently in use.\n"; 
            print wrap($msg, 0);
         }

         configure_updatedb() if ($result eq 'yes');
      } else {
        ***REMOVED*** Failed the preinstall check.  result has to equal 0, but don't display
        ***REMOVED*** the message about installing the driver as it is already installed.
        $result = 'no';
        $dispInstallMsg = 0;
      }
    } elsif (vmware_product() eq 'tools-for-solaris') {
      ***REMOVED*** It's common to mount over /mnt in Solaris so we use /hgfs
      if (create_dir('/hgfs', $cFlagDirectoryMark | $cFlagFailureOK)
          != $cCreateDirFailure) {
        symlink_if_needed('/hgfs', '/mnt/hgfs');
        $result = configure_module_solaris('vmhgfs');
      } else {
        $result = 'no';
        my $msg = "Could not create the '/hgfs' directory.\n";
        print wrap($msg, 0);
      }
    } elsif (vmware_product() eq 'tools-for-freebsd') {
      if (create_dir('/mnt/hgfs', $cFlagDirectoryMark | $cFlagFailureOK)
          != $cCreateDirFailure) {
	$result = configure_module_bsd('vmhgfs');
      } else {
        $result = 'no';
        my $msg = "Could not create the '/mnt/hgfs' directory.\n";
        print wrap($msg, 0);
      }
    }
    if ($result eq 'no' and $dispInstallMsg != 0) {
      my $msg = 'The filesystem driver (vmhgfs module) is used only for the '
              . 'shared folder feature. The rest of the software provided by '
              .  vmware_product_name() . ' is designed to work independently of '
              . 'this feature.' . "\n\n" . 'If you wish to have the shared folders '
              . 'feature,' . $cModulesBuildEnv . "\n";
      query ($msg, ' Press Enter key to continue ', 0);
    }

    module_post_configure('vmhgfs', $result);
  }
}

***REMOVED*** Configuration of the vmxnet3 ethernet driver
sub configure_vmxnet3 {
  my $result = 'no';
  ***REMOVED*** vmxnet3 is supported only since 2.6.0 Linux kernels
  if ($gSystem{'version_integer'} < kernel_version_integer(2, 6, 0)) {
    query('You are running Linux version ' . $gSystem{'version_utsclean'}
	  . '.  The driver for the VMXNET 3 virtual network card is '
	  . 'only available for 2.6.0 and later kernels.'
	  . "\n", ' Press Enter key to continue ', 0);
  } else {
    $result = mod_pre_install_check('vmxnet3');
    if ($result eq 'yes') {
      $result = configure_module('vmxnet3');
      if ($result eq 'no') {
	query('The driver for the VMXNET 3 virtual '
	      . 'network card is used only for '
	      . 'our advanced networking interface. '
	      . 'The rest of the software provided by '
	      . vmware_product_name()
	      . ' is designed to work independently of '
	      . 'this feature.' . "\n"
	      . 'If you wish to have the advanced network driver enabled,'
	      . $cModulesBuildEnv
	      . "\n", ' Press Enter key to continue ', 0);
      }
    }
  }

  module_post_configure('vmxnet3', $result);
}

sub configure_vmci {
  my $result = 'no';

  if (!(isDesktopProduct() || isServerProduct() ||
      vmware_product() eq 'tools-for-linux' )) {
    return undef;
  }

  $result = mod_pre_install_check('vmci');
  if ($result eq 'yes') {
    $result = configure_module('vmci');
    if ($result eq 'no') {
      query('The communication service is used in addition to the '
            . 'standard communication between the guest and the host.  '
            . 'The rest of the software provided by ' . vmware_product_name()
            . ' is designed to work independently of this feature.' . "\n"
            . 'If you wish to have the VMCI feature,'
            . $cModulesBuildEnv
            . "\n", ' Press Enter key to continue ', 0);
    }
  }

  module_post_configure('vmci', $result);
}

sub configure_vsock {
   my $result = 'no';

   $result = mod_pre_install_check('vsock');
   if ($result eq 'yes') {
     ***REMOVED*** vsock needs the vmci module loaded first.
     ***REMOVED*** Note, now that we use modconfig to build the modules on tools-for-linux,
     ***REMOVED*** we no longer need to load the vmci modules as it is handled automatically
     ***REMOVED*** by modconfig.
     if (vmware_product() ne 'tools-for-linux') {
       if (defined(db_get_answer_if_exists('VMCI_CONFED')) &&
           db_get_answer('VMCI_CONFED') ne 'yes') {
	  return 1;
       }
     }

     $result = configure_module('vsock');
     if ($result eq 'no') {
       query("The VM communication interface socket family is used in conjunction " .
	     "with the VM communication interface to provide a new communication " .
	     "path among guests and host.  The rest of this software " .
             "provided by " . vmware_product_name() . " is designed to work " .
	     "independently of this feature.  If you wish to have the VSOCK " .
	     "feature " . $cModulesBuildEnv . "\n",
	     " Press the Enter key to continue.", 0);
     }
   }

   module_post_configure('vsock', $result);
}

sub configure_pvscsi {
   my $result = 'no';

   ***REMOVED*** pvscsi is supported on only kernel versions >= 2.6.18.
   if ($gSystem{'version_integer'} >= kernel_version_integer(2, 6, 18)) {
     $result = mod_pre_install_check('pvscsi');

     if ($result eq 'yes') {
       ***REMOVED*** NOTE: See bug 347401. We do not want to interrupt pvscsi services by
       ***REMOVED*** unloading the kernel module.
       ***REMOVED*** kmod_unload('pvscsi');

       $result = configure_module('pvscsi');
       if ($result eq 'no') {
	 query('Unable to compile the pvscsi module.  '
	       . 'If you wish to have the pvscsi feature,'
	       . $cModulesBuildEnv
	       . "\n", ' Press Enter key to continue ', 0);
       }
     }
   } else {
     print wrap ("The VMware pvscsi module is only supported on kernel " .
          "version 2.6.18 and newer.\n", 0);
   }

   module_post_configure('pvscsi', $result);
}

***REMOVED*** Configuration related to vmwgfx
sub configure_vmwgfx {
  my $udev_file = db_get_answer('LIBDIR') . '/configurator/udev/00-vmwgfx.rules';
  my $result = 'no';

  $result = mod_pre_install_check('vmwgfx');
  if ($result eq 'yes') {
     $result = configure_module('vmwgfx');
     if ($result eq 'yes') {
	 installUdevRule($udev_file);
         system(db_get_answer('INITSCRIPTSDIR') .  '/udev restart > /dev/null 2>&1');
         ***REMOVED*** vmwgfx is loaded by /etc/modules. If it is loaded by the initrd, it
         ***REMOVED*** conflicts with the initrd splash code. If it is loaded by
         ***REMOVED*** /etc/init.d/vmware-tools it conflicts with X starting to early on some
         ***REMOVED*** systems (Ubuntu starts X in rcS). By using /etc/modules, vmwgfx is loaded
         ***REMOVED*** after the initrd splash and before rcS.
         if (not block_match('/etc/modules', 'vmwgfx')) {
        block_append('/etc/modules',
                $cMarkerBegin,
                'vmwgfx force_stealth=1' . "\n",
                $cMarkerEnd);
         }
         configure_compiz_wrapper_whitelist();
     } else {
         query('Unable to compile the vmwgfx module. '
	       . 'If you wish to have the vmwgfx feature,'
	       . $cModulesBuildEnv
	       . "\n", ' Press Enter key to continue ', 0);
     }
  }
  module_post_configure('vmwgfx', $result);
}

sub configure_vmsync {
   my $result = 'no';

   ***REMOVED*** Skip kernel version > 3.8.0 as vmsync can't compatible with new kernel
   ***REMOVED*** structures.
   $result = mod_pre_install_check('vmsync');
   if ($result eq 'yes' and
       $gSystem{'version_integer'} >= kernel_version_integer(2, 6, 6) and
       $gSystem{'version_integer'} < kernel_version_integer(3, 8, 0)) {
     if (get_persistent_answer(
                     '[EXPERIMENTAL] The VMware FileSystem Sync Driver '
                   . '(vmsync) is a new feature that creates backups '
                   . 'of virtual machines. '
                   . 'Please refer to the VMware Knowledge Base for more '
                   . 'details on this capability. Do you wish to enable '
                   . 'this feature?', 'XPRMNTL_VMSYNC',
                   'yesno', 'no') eq 'yes') {
         $result = configure_module('vmsync');
         if ($result eq 'no') {
            query('The file system sync driver (vmsync) is only used to create safe '
               . 'backups of the virtual machine. The rest of the software '
               . 'provided by ' . vmware_product_name()
               . ' is designed to work independently of this feature.' . "\n"
               . 'If you wish to have the vmsync feature,'
               . $cModulesBuildEnv
               . "\n", ' Press Enter key to continue ', 0);
         }
      }
   }

   module_post_configure('vmsync', $result);
}


***REMOVED***
***REMOVED*** In $infile, look for a line defining $var and append the contents of $content to
***REMOVED*** the list, making sure not to add duplicates. If no match on $var is found, then
***REMOVED*** "$var = $content" is added to the end of $infile.
***REMOVED***
***REMOVED*** This is probably best explained with an example:
***REMOVED*** $outfile = '/etc/foo.conf'
***REMOVED*** $var = 'drivers'
***REMOVED*** $content = 'vmwgfx foo vmxnet'
***REMOVED***
***REMOVED*** Calling the function with the above parameters will find a line like:
***REMOVED***   drivers = 'foo bar baz'
***REMOVED*** and transform it into:
***REMOVED***   drivers = 'foo bar baz vmwgfx vmxnet'
***REMOVED***
sub add_to_list_variable {
   my $infile = shift;
   my $outfile = shift;
   my $var = shift;
   my $content = shift;
   my $regexpat = '^\s*' . $var . '\s*=\s*\"(.+)\"\s*$';
   my $added_content = 0;
   if (open(IN, $infile) && open(OUT, ">$outfile")) {
      while (<IN>) {
         ***REMOVED*** Don't match commented $var lines.
         if (/$regexpat/) {
            $var = "$var=\"$1";  ***REMOVED*** we add the terminating quote later
            ***REMOVED*** $content is the space-separated list of strings.
            ***REMOVED*** Check each string against the existing list in the file
            ***REMOVED*** before adding it, so as to avoid duplicates.
            foreach my $string (split(' ', $content)) {
               next if ($var =~ m/\b$string\b/);
               $var .= " $string";
            }
            $var .= "\"";                ***REMOVED*** terminating quote
            print OUT $var, "\n";
            $added_content = 1;
         } else {
            print OUT $_;
         }
      }
      if (!$added_content) {
         ***REMOVED*** If there were no drivers, add them now
         $var = "$var=\"$content\"";
         print OUT $var, "\n";
      }
      close OUT;
      close IN;
   }
}

***REMOVED***
***REMOVED*** Configure dracut, Fedora (12+)'s and RHEL 6(+?)'s initrd creation
***REMOVED*** and management mechanism
***REMOVED***
sub configure_dracut {
   my $addedDrivers = shift;
   my $addDriversText = "add_drivers+=\"" . $addedDrivers . "\"";
   my $dracutConfFile = '/etc/dracut.conf.d/vmware-tools.conf';

   ***REMOVED*** first check if the OS does things the 'dot d' way, the preferred
   ***REMOVED*** method. Fedora 12 does not, while the rest mentioned above do.
   if (-d '/etc/dracut.conf.d/') {
      if (not open(VMWARETOOLSCONF, ">$dracutConfFile")) {
         error('Unable to open ' . $dracutConfFile . ' for writing.');
      }

      print VMWARETOOLSCONF $addDriversText;
      print VMWARETOOLSCONF "\n";
      close (VMWARETOOLSCONF);

      ***REMOVED*** add file to the db so that it will be removed by our normal uninstall
      ***REMOVED*** process
      db_add_file($dracutConfFile, $cFlagTimestamp);

   } elsif (-e '/etc/dracut.conf') {
      ***REMOVED*** special case for Fedora 12 and those without the ".d" mechanism
      $dracutConfFile = '/etc/dracut.conf';
      my $key = 'add_drivers';
      my $regex = '^\s*(' . $key . '\s*=\s*")(.*)(")$';

      ***REMOVED*** first, let's try to edit the file inline, as in configure_initrd_suse
      if(not addTextToKVEntryInFile($dracutConfFile, $regex, ' ', $addedDrivers)) {
         ***REMOVED*** otherwise, append to the file
         if (not open(DRACUTCONF, ">>$dracutConfFile")) {
            error("Unable to open " . $dracutConfFile . " to append.");
         }
         print DRACUTCONF "\n";
         print DRACUTCONF $addDriversText;
         print DRACUTCONF "\n";

         close (DRACUTCONF);
      }

      db_add_answer('INITRDMODS_CONF_VALS', $addedDrivers);
      db_add_answer('INITRDMODS_CONF_KEY', $key);
   } else {
      error("Unable to find /etc/dracut.conf or /etc/dracut.conf.d/ .");
   }

   db_add_answer('INITRDMODS_CONF_FILE', $dracutConfFile);
}

***REMOVED***
***REMOVED*** Configure suse's initrd modules by appending them to
***REMOVED*** INITRD_MODULES in /etc/sysconfig/kernel
***REMOVED***
sub configure_initrd_suse {
   my $entry = shift;

   my $file = "/etc/sysconfig/kernel";
   my $key = "INITRD_MODULES";

   return 0 unless (-e $file);

   db_add_answer('INITRDMODS_CONF_FILE', $file);
   db_add_answer('INITRDMODS_CONF_KEY', $key);

   my $regex = '^\s*(' . $key . '\s*=\s*")(.*)(")$';
   my $delim = ' ';

   ***REMOVED*** Append the list (string-ified) of necessary initrd modules to the
   ***REMOVED*** appropriate variable in the initrd file.
   if(addTextToKVEntryInFile($file, $regex, $delim, $entry)) {
      db_add_answer('INITRDMODS_CONF_VALS', $entry);
   } else {
      error('Unable to configure the initrd modules file at ' . $file . ".");
   }
}


***REMOVED***
***REMOVED*** On some distributions, /usr/bin/compiz is a shell script and had a whitelist
***REMOVED*** of drivers. In that case, add vmwgfx to the list.
***REMOVED***
sub configure_compiz_wrapper_whitelist {
    my $compizfile = '/usr/bin/compiz';
    my $magicnumber;
    if (-e $compizfile && open(IN, $compizfile)) {
	binmode(IN);
	read(IN, $magicnumber, 2, 0);
    }
    if ($magicnumber eq '***REMOVED***!') {
	backup_file_to_restore($compizfile, 'COMPIZ_WRAPPER');
	add_to_list_variable($compizfile . $cBackupExtension, $compizfile, 'WHITELIST',
			     'vmwgfx');
	safe_chmod(0755, $compizfile);
    }
}

***REMOVED***
***REMOVED*** Post configuration steps common to every module
***REMOVED***
sub module_post_configure {
  my $mod = shift;
  my $result = shift;

  if ($result eq 'yes' && vmware_product() eq 'tools-for-linux') {
    set_manifest_component("$mod", 'TRUE');
  }

  db_add_answer(uc("$mod") . '_CONFED', $result);
  module_ramdisk_check("$mod");
}

***REMOVED***
***REMOVED*** Update or replace the kernel's boot ramfs so that certain vmware drivers
***REMOVED*** are loaded at boot
***REMOVED***
***REMOVED*** Create a helper app command to use to restore the initrd on uninstall.
***REMOVED***
sub configure_kernel_initrd {
  my $initmodfile;
  my ($syscmd, $restorecmd, $content, $binary, $style);
  $syscmd = $restorecmd = $content = $binary = $style = '';
  my $kernRel = getKernRel();

  ***REMOVED*** NOTE: In RESTORE_RAMDISK_CMD, use KREL as the template for the
  ***REMOVED***       kernel release.  Then when tools are removed from the system,
  ***REMOVED***       the command in RESTORE_RAMDISK_CMD is run one time for every
  ***REMOVED***       kernel entry in RESTORE_RAMDISK_KERNEL.  Set
  ***REMOVED***       RESTORE_RAMDISK_ONECALL if the RESTORE_RAMDISK_CMD only needs
  ***REMOVED***       to be run once.

  if (-f '/etc/initramfs-tools/modules') {
     $initmodfile = '/etc/initramfs-tools/modules';
     $binary = internal_which('update-initramfs');
     if (not defined($binary)) {
        my $msg = "Cannot find update-initramfs, necessary to update "
            . "the kernel initrd image.\n";
        error($msg);
     }
     $syscmd = join(' ',$binary, '-u', '-k', $kernRel);
     $restorecmd = $binary . ' -u -k all';
     db_add_answer('RESTORE_RAMDISK_CMD', "$restorecmd");
     db_add_answer('RESTORE_RAMDISK_ONECALL', '1');
     foreach my $key (@gRamdiskModules) {
        $content .= get_module_name($key) ."\n";
     }
  ***REMOVED*** !!! It is important for the 'dracut' check to appear before the 'mkinitrd' check,
  ***REMOVED*** !!! since both exist on Fedora 13 and we want to use dracut in that case.
  } elsif (internal_which('dracut') ne '') {
    ***REMOVED*** Dracut is the replacement for mkinitrd first appearing in Fedora 12.
    $binary = internal_which('dracut');
    $initmodfile = "/etc/dracut.conf";
    $style = "dracut";
    foreach my $key (@gRamdiskModules) {
      $content .=  get_module_name($key) . ' ';
    }
    chop($content);
    my $image_file = "/boot/initramfs-" . $kernRel . ".img";
    $syscmd = join(' ', $binary, '--force', '--add-drivers', "\"$content\"",
                   $image_file, $kernRel,'>/dev/null 2>&1');
    db_add_answer('RESTORE_RAMDISK_CMD', join(' ', $binary, '--force',
                                          '/boot/initramfs-KREL.img', 'KREL'));
    addEntDBList('RESTORE_RAMDISK_KERNELS', $kernRel);
  } elsif (internal_which('mkinitrd') ne '') {
    $binary = internal_which('mkinitrd');

    $style = '';
    ***REMOVED*** See if the version of mkinitrd is the Fedora/Redhat one or the SuSE one.  Check
    ***REMOVED*** whether the help message mentions "--with=<module>" or not.  If it does then
    ***REMOVED*** we're using a Redhat/Fedora style mkinitrd.  Else SuSE.
    ***REMOVED***
    ***REMOVED*** Also, mkinitrd prints out its help message through stderr, hence '2>&1.'
    if (not open(FILE, $binary. " --help 2>&1 |")) {
      error("Unable to run 'mkinitrd --help.'\n");
    }
    while  (<FILE>) {
      if (/--with=/) {
        $style = 'redhat';
        last;
      }
    }
    close(FILE);

    foreach my $key (@gRamdiskModules) {
      if ($style eq 'redhat') {
        $content .= " --with=" . get_module_name($key) . "  ";
      } else {
        $content .=  get_module_name($key) . ' ';
      }
    }

    if ($style eq 'redhat') {
      my $image_file = '/boot/initrd-' . $kernRel . ".img";
      $syscmd = join(' ', $binary, '-f', $content, $image_file, $kernRel);
      db_add_answer('RESTORE_RAMDISK_CMD', join(' ', $binary, '-f',
                                            '/boot/initrd-KREL.img', 'KREL'));
      addEntDBList('RESTORE_RAMDISK_KERNELS', $kernRel);
    } else {
      ***REMOVED*** Assuming this is a SuSE system, you have to specify the kernel image and the
      ***REMOVED*** initrd image that you want to remake.  If its not a SuSE system, then leave
      ***REMOVED*** it the way it was before.
      my $kernelList = "-k vmlinuz-$kernRel";
      my $initrdList = "-i initrd-$kernRel";

      $initmodfile = '/etc/sysconfig/kernel';
      if ($gSystem{'distribution'} eq 'suse') {
	  $syscmd = join(' ', $binary, $kernelList, $initrdList);
      } else {
	  $syscmd = $binary;
      }

      ***REMOVED*** SuSE's version of mkinitrd will remake the initrd for all kernels
      ***REMOVED*** found in /boot if no -k or -i parameters are passed.
      db_add_answer('RESTORE_RAMDISK_CMD', $binary);
      db_add_answer('RESTORE_RAMDISK_ONECALL', '1');
    }
  } else {
    ***REMOVED*** We can't rebuild the initrd if we get here.  Not fatal, but we need
    ***REMOVED*** to let the users know about it.
    print wrap("\n Warning: This script could not find mkinitrd or " .
	       "update-initramfs and cannot remake the initrd file!\n\n", 0);
    $syscmd = undef;
  }

  ***REMOVED*** Only need to modify the $initmodfile for Ubuntu, SuSE, and Fedora 12 (Dracut) style initrd.
  if ( defined($initmodfile) && file_name_exist($initmodfile) && defined($content)) {
    if ($style eq "dracut") {
      configure_dracut($content);
    } elsif ($gSystem{'distribution'} eq 'suse') {
      configure_initrd_suse($content);
    } else {
      block_restore($initmodfile, $cMarkerBegin, $cMarkerEnd);
      block_append_with_db_answer_entry($initmodfile, $content);
    }
  }

  system(shell_string($gHelper{'depmod'}) . ' -a');
  ***REMOVED*** Make the initrd.
  if (defined $syscmd and $syscmd ne '') {
    print wrap("Creating a new initrd boot image for the kernel.\n", 0);
    if (system($syscmd) != 0) {
      ***REMOVED*** Check to ensure that the command succeded.  If it didn't the system may
      ***REMOVED*** not boot.  We need to error out if that is the case.
      error( wrap("ERROR: \"$syscmd\" exited with non-zero status.\n" .
		  "\n" .
		  'Your system currently may not have a functioning init ' .
		  'image and may not boot properly.  DO NOT REBOOT!  ' .
		  'Please ensure that you have enough free space available ' .
		  'in your /boot directory and run this configuration ' .
		  "script again.\n\n", 0));
    }
  }
}


***REMOVED***
***REMOVED*** This is for module-init-tools (2.6 kernels) and hotplug
***REMOVED*** The first argument is a complete path to a file which will be read and
***REMOVED*** overwritten with the result.
***REMOVED*** The second argument will be only read and should be the system file present
***REMOVED*** before configuration.
***REMOVED***
sub configure_pci_dot_handmap {
  my ($newPciHandmap, $systemPciHandmap)
      = @_;
  my $inline;
  my $emittedVmnics = 0;
  my $emittedVmxnet = 0;

  if (not open(SYSHANDMAP, "<$systemPciHandmap")) {
    error('Unable to open the file "' . $systemPciHandmap . '".' . "\n\n");
  }

  if (not open(NEWHANDMAP, ">$newPciHandmap")) {
    error('Unable to open the file "' . $newPciHandmap . '".' . "\n\n");
  }

  ***REMOVED*** Look for matches and selectively replace drivers
  while (defined($inline = <SYSHANDMAP>)) {
    if ($inline =~ /^\s*(\w+)\s+(\w+)/) {
      my ($cmd, $val) = ($1, $2);

      if ($cmd eq 'vmxnet') {
	  $inline = 'vmxnet\t\t0x000015ad 0x00000720 ' .
	      '0xffffffff 0xffffffff 0x00000000 0x00000000 0x0' . "\n";
	  $emittedVmxnet = 1;
      } elsif ($cmd eq 'vmnics') {
	  $inline = 'vmnics\t\t0x00001022 0x00002000 ' .
	      '0xffffffff 0xffffffff 0x00000000 0x00000000 0x0' . "\n";
	  $emittedVmnics = 1;
      }
    }
    print NEWHANDMAP $inline;
  }

  my @output;

  if ($emittedVmxnet == 0 ) {
      push @output, "vmxnet\t\t0x000015ad 0x00000720 0xffffffff 0xffffffff 0x00000000 0x00000000 0x0\n";
  }
  if ($emittedVmnics ==  0) {
      push @output, "vmnics\t\t0x00001022 0x00002000 0xffffffff 0xffffffff 0x00000000 0x00000000 0x0\n";
  }
  if (scalar @output) {
    print NEWHANDMAP "***REMOVED*** Added by " . vmware_product_name() . "\n";
    print NEWHANDMAP join('', @output);
}
  close (SYSHANDMAP);
  close (NEWHANDMAP);
}


***REMOVED******REMOVED***
***REMOVED*** configure_updatedb
***REMOVED***
***REMOVED*** Configures updatedb.conf inline to prevent the scanning of file systems
***REMOVED*** mounted via hgfs
***REMOVED***
sub configure_updatedb {
   my @fkPairs = (['/etc/updatedb.conf', 'PRUNEFS'],
                  ['/etc/sysconfig/locate', 'UPDATEDB_PRUNEFS']);

   my $file;
   my $key;
   foreach my $fkPair (@fkPairs) {
      ($file, $key) = @$fkPair;
      last if (-e $file);
   }

   return 0 unless (-e $file);
   db_add_answer('UPDATEDB_CONF_FILE', $file);
   db_add_answer('UPDATEDB_CONF_KEY', $key);

   my $regex = '^\s*(' . $key . '\s*=\s*")(.*)(")$';
   my $delim = ' ';
   my $entry = 'vmhgfs';
   return addTextToKVEntryInFile($file, $regex, $delim, $entry);
}


***REMOVED*** Enumerate devices we are interested on. Returns array of 3 elements:
***REMOVED*** 1. number of vmxnet adapters
***REMOVED*** 2. number of pcnet32 adapters
***REMOVED*** 3. number of es1371 adapters
***REMOVED*** We do not attempt to find ISA vlance or sb.
sub get_devices_list {
  my ($vmxnet, $pcnet32, $es1371) = (0, 0, 0);
  my $line;

  ***REMOVED*** Per bug ***REMOVED***41349 the lspci version provided by Mandrake has unwanted
  ***REMOVED*** interaction with the sound device. The alternate lspcidrake tool
  ***REMOVED*** works fine but it unnecessarily complicates the configuration script.
  ***REMOVED*** Using /proc/bus/pci/devices instead of the output of lspci/lspcidrake
  ***REMOVED*** is consistent on all supported distributions.
  if (open PCI, '</proc/bus/pci/devices') {
    while (defined($line = <PCI>)) {
      $line = lc($line);
      if ($line =~ /^[0-9a-f]*\t([0-9a-f]*)\t/) {
        my $dev = $1;
        if ($dev eq '10222000') {
          $pcnet32++;
        } elsif ($dev eq '15ad0720') {
          $vmxnet++;
        } elsif ($dev eq '12741371') {
          $es1371++;
        }
      }
    }
    close PCI;
  }
  return ($vmxnet, $pcnet32, $es1371);
}

***REMOVED*** Configuration of drivers for PCI devices
sub write_module_config {
  my $modprobe_file = '';
  my $result;

  if (vmware_product() ne 'tools-for-linux') {
    return;
  }

  ***REMOVED*** PR 848092 -
  ***REMOVED*** We special case the vmxnet driver - since we do not support this NIC on
  ***REMOVED*** Linux kernels > 3.2, we don't even want to allow the user to clobber.
  ***REMOVED*** Just return (with message) in all cases where kernel > 3.2
  if ($gSystem{'version_integer'} >= kernel_version_integer(3,3,0)) {
    print wrap("The vmxnet driver is no longer supported on kernels " .
        "3.3 and greater. Please upgrade to a newer virtual NIC. " .
        "(e.g., vmxnet3 or e1000e)\n\n", 0);
    return;
  }

  $result = mod_pre_install_check('vmxnet');
  if ($result eq 'yes') {
    $result = configure_module('vmxnet');
    if ($result eq 'no') {
      query('The fast network device driver (vmxnet module) is used only for '
            . 'our fast networking interface. '
            . 'The rest of the software provided by '
            . vmware_product_name()
            . ' is designed to work independently of '
            . 'this feature.' . "\n"
            . 'If you wish to have the fast network driver enabled,'
            . $cModulesBuildEnv
            . "\n", ' Press Enter key to continue ', 0);
    } else {
      my $initmodfile = '/etc/initramfs-tools/modules';
      if ( -f $initmodfile ) {
        backup_file_to_restore($initmodfile, 'INITRAMFS_MODULES');
        system(shell_string($gHelper{'cp'}). ' ' . $initmodfile . $cBackupExtension . ' ' .
               $initmodfile);
        if (not block_match($initmodfile, '^vmxnet$')) {
          block_append($initmodfile,
                       $cMarkerBegin,
                       "vmxnet\n",
                       $cMarkerEnd);
        }
      }
    }

    ***REMOVED*** modprobe looks for module info first in modprobe.d<vmware-tools>
    ***REMOVED*** and then in modprobe.conf>.  However, SLES9 includes a new
    ***REMOVED*** wrinkle: the file modprobe.conf.local.  That gets included into
    ***REMOVED*** modprobe.conf and SLES9 wants user modified entries in that
    ***REMOVED*** local file.
    ***REMOVED*** It's very important that modprobe.d is checked *first*.  We
    ***REMOVED*** want to use it if it exists and doing so makes this work
    ***REMOVED*** correctly on RHEL 5.
    ***REMOVED*** Need to special-case RHEL 4 because it doesn't actually pay attention to
    ***REMOVED*** files in the /etc/modprobe.d/ directory
    my $isRhel4Rel = system(shell_string($gHelper{'grep'}) . ' ' .
       "-q 'Red Hat Enterprise Linux .* release 4' /etc/redhat-release " .
       "> /dev/null 2>&1");

    if (file_name_exist('/etc/modprobe.d') && not ($isRhel4Rel == 0)) {
      $modprobe_file = '/etc/modprobe.d/vmware-tools.conf';
    } elsif (file_name_exist('/etc/modprobe.conf.local')) {
      $modprobe_file = '/etc/modprobe.conf.local';
    } elsif (file_name_exist('/etc/modprobe.conf')) {
      $modprobe_file = '/etc/modprobe.conf';
    } elsif (file_name_exist('/etc/modules.conf')) {
      $modprobe_file = '/etc/modules.conf';
    } elsif (file_name_exist('/etc/conf.modules')) {
      $modprobe_file = '/etc/conf.modules';
    }

    if (($modprobe_file eq '/etc/modprobe.conf.local') ||
        ($modprobe_file eq '/etc/modprobe.conf')) {

        my $modprobe_command = '';

        if ($gSystem{'version_integer'} < kernel_version_integer(2, 6, 22) ) {
           $modprobe_command .=  "install pciehp /sbin/modprobe -q " .
                                  "--ignore-install acpiphp; /bin/true\n";
        }
        $modprobe_command .= 'install pcnet32 (/sbin/modprobe -q ' .
                              '--ignore-install vmxnet ; /sbin/modprobe -q ' .
                              '--ignore-install pcnet32 $CMDLINE_OPTS); ' .
                              "/bin/true\n";

        ***REMOVED*** Append modprobe_command to the end of /etc/modprobe.conf(.local),
        ***REMOVED*** inside a block that can be removed later.
        block_append_with_db_answer_entry($modprobe_file, $modprobe_command);

    } elsif ($modprobe_file eq '/etc/modprobe.d/vmware-tools.conf') {
      my @netopt = ('install pcnet32 /sbin/modprobe -q --ignore-install vmxnet; ' .
                    '/sbin/modprobe --ignore-install pcnet32 $CMDLINE_OPTS' . "\n");
      if (vmware_product() eq 'tools-for-linux'
          && $gSystem{'version_integer'} < kernel_version_integer(2, 6, 22) ) {
        push(@netopt, 'install pciehp /sbin/modprobe -q --ignore-install acpiphp;'
             . "/bin/true\n");
      }
      if (not open(NEWMODCONF, ">$modprobe_file")) {
        error('Unable to open the file "' . $modprobe_file . '".' . "\n\n");
      }

      print NEWMODCONF "***REMOVED*** Created by " . vmware_product_name() . "\n";
      print NEWMODCONF join('', @netopt);
      close(NEWMODCONF);

      db_add_file($modprobe_file, 0x0);

      ***REMOVED*** Older kernels use conf.modules or modules.conf; the required command
      ***REMOVED*** is also a little different, which was taken from files in the new
      ***REMOVED*** configurator
    } elsif (file_name_exist('/etc/conf.modules') ||
             file_name_exist('/etc/modules.conf')) {

      my $modules_file = file_name_exist('/etc/conf.modules') ?
                           '/etc/conf.modules' : '/etc/modules.conf';

      my $modconf_command = "pre-install pcnet32 " .
         "/sbin/modprobe -q vmxnet &> /dev/null || true\n";

      ***REMOVED*** append the modconf_command to modules.conf or conf.modules,
      ***REMOVED*** inside a block that can be removed later
      block_append_with_db_answer_entry($modules_file, $modconf_command);
    }

    if (file_name_exist('/etc/hotplug/pci.handmap')) {
      my $handmap_file = '/etc/hotplug/pci.handmap';
      backup_file_to_restore($handmap_file, 'PCI_HANDMAP');
      configure_pci_dot_handmap($handmap_file,
				$handmap_file . $cBackupExtension);
    }
  }

  ***REMOVED*** The initramfs rebuilding process happens in the
  ***REMOVED*** configure_kernel_initrd function, which is called later.  Defer
  ***REMOVED*** that configuration until then.
  module_post_configure('vmxnet', $result);
}

***REMOVED*** There is no /usr/X11R6 directory for X window in some distribution like
***REMOVED*** Fedora 5. Instead binary files are put in /usr/bin. Please refer to bug
***REMOVED*** 86254.

sub xserver_bin {
  my $path;

  if (vmware_product() eq 'tools-for-solaris' && -e '/usr/X11/bin') {
    return '/usr/X11/bin';
  }

  ***REMOVED*** Search PATH for Xorg then X, in case it is somewhere else. Some OSs put
  ***REMOVED*** X in /usr/local/bin, so we use the original path rather than the cut down
  ***REMOVED*** one this script normally uses.
  $path = internal_which('Xorg', 1);
  if ($path eq '') {
    $path = internal_which('X', 1)
  }
  if ($path ne '') {
    ***REMOVED*** Only return path, so remove file name.
    return internal_dirname($path);
  }

  if (-e '/usr/X11R6/bin') {
     return '/usr/X11R6/bin';
  }

  return '';
}

sub xserver_xorg {
  return xserver_bin() . '/Xorg';
}

sub xserver4 {
  return xserver_bin() . '/XFree86';
}

sub xserver3 {
  return xserver_bin() . '/XF86_VMware';
}

sub xconfig_file_abs_path {
  my $xconfig_path = shift;
  my $xconfig_file_name = shift;
  return $xconfig_path . '/' . $xconfig_file_name;
}

***REMOVED***
***REMOVED*** path_compare(dir, path1, path2)
***REMOVED***
***REMOVED*** Compare the two paths, and return true if they are identical
***REMOVED*** Evaluate the paths with respect to the passed in directory
***REMOVED***
sub path_compare {
  my ($dir, $path1, $path2) = @_;

  ***REMOVED*** Prepend directory for relative paths
  $path1 =~ s|^([^/])|$dir/$1|;
  $path2 =~ s|^([^/])|$dir/$1|;

  ***REMOVED*** Squash out ..'s in paths
  while ($path1 =~ /\/.*\/\.\.\//) {
    $path1 =~ s|/[^/]*/\.\./|/|;
  }

  while ($path2 =~ /\/.*\/\.\.\//) {
    $path2 =~ s|/[^/]*/\.\./|/|;
  }

  ***REMOVED*** Squash out .'s in paths
  while ($path1 =~ /\/\.\//) {
    $path1 =~ s|/\./|/|;
  }

  while ($path2 =~ /\/\.\//) {
    $path2 =~ s|/\./|/|;
  }

  ***REMOVED*** Squash out //'s in paths
  while ($path1 =~ /\/\//) {
    $path1 =~ s|//|/|;
  }

  while ($path2 =~ /\/\//) {
    $path2 =~ s|//|/|;
  }

  if ($path1 eq $path2) {
    return 'yes';
  } else {
    return 'no';
  }
}

***REMOVED*** check_link
***REMOVED*** Checks that a given link is pointing to the given file.
sub check_link {
  my $file = shift;
  my $link = shift;
  my $linkDest;
  my $dirname;
  $linkDest = readlink($link);
  if (!defined $linkDest) {
    return 'no';
  }
  $dirname = internal_dirname($link);
  return path_compare($dirname, $linkDest, $file);
}

***REMOVED*** Install one link, symbolic or hard
sub install_link {
   my $symbolic = shift;
   my $to = shift;
   my $name = shift;

   uninstall_file($name);
   if (file_check_exist($name)) {
      return;
   }
   ***REMOVED*** The file could be a link to another location.  Remove it
   unlink($name);
   if ($symbolic) {
      if (not symlink($to, $name)) {
         return 'no';
      }
   } else {
      if (not link($to, $name)) {
         return 'no';
      }
   }
   db_add_file($name, 0);
   return 'yes';
}

sub install_symlink {
   my $to = shift;
   my $from = shift;

   if (install_link(1, $to, $from) eq 'no') {
         error('Unable to create symlink "' . $from . '" pointing to file "'
               . $to . '".' . "\n\n");
   }
}

sub install_hardlink {
   my $to = shift;
   my $from = shift;

   return install_link(0, $to, $from);
}

my $gLinkCount = 0;
sub symlink_if_needed {
  my $file = shift;
  my $link = shift;
  if (file_name_exist($file)) {
    if (-l $link && check_link($file, $link) eq 'yes') {
      return;
    }
    $gLinkCount = $gLinkCount + 1;
    backup_file_to_restore($link, 'LINK_' . $gLinkCount);
    install_symlink($file, $link);
  }
}

sub set_uid_X_server {
  my $x_server_file = shift;
  if (!-u $x_server_file) {
    safe_chmod(04711, $x_server_file);
  }
}

sub getXorgVersionAll {

  my $packedVersion = direct_command(shell_string(xserver_xorg()) . ' -version 2>&1');
  my $xorgServerVersion;
  if ($packedVersion =~ /X Protocol Version 11.* Release (\d+\.\d+)/) {
     $packedVersion = $1 ? $1 : '0.0.0';
  } elsif ($packedVersion =~ /X Server (\d+\.\d+\.?\d*)/) {
	$packedVersion = $1 ? $1 : '0.0.0';
        $xorgServerVersion = $packedVersion;
  }
  my ($xorgMajorVer, $xorgMinorVer, $xorgSubVer) = split_X_version($packedVersion);
  if (!defined($xorgSubVer)) {
     $xorgSubVer = 0;
  }

  ***REMOVED*** The 1.3.0 release of the X-server had a little goof where it would say
  ***REMOVED*** X Window System, Release 1.3.0. so $major == 1 and $minor == 3. But
  ***REMOVED*** truly, it's a standalone X server release that came out after Xorg 7.2.
  ***REMOVED*** Similarly, Release 1.4.0 came out as part of Xorg 7.3.
  ***REMOVED***
  ***REMOVED*** See bug***REMOVED***185281 for all the deets.
  if ($xorgMajorVer == 1) {
    $packedVersion = "7." . ($xorgMinorVer - 1) . "." . $xorgSubVer;
  }

  return ($packedVersion, $xorgServerVersion);
}

sub split_X_version {

  my $xversionAll = shift;
  my $major;
  my $minor;
  my $sub;

  if ($xversionAll =~ /(\d+)\.(\d+)\.?(\d*)/) {
    $major = $1;
    $minor = $2;
    $sub = $3 eq '' ? 0 : $3;
  } else {
    $major = 0;
    $minor = 0;
    $sub = 0;
  }
  return ($major, $minor, $sub);
}

***REMOVED*** If the vmwgfx_drv.so driver exists, then attempt to install it.
***REMOVED*** If that installation succeeds, then also install vmwgfx_dri.so
***REMOVED*** and libexa.so. Return 1 if installation succeeded, 0 otherwise.
sub configure_vmware_gfx_driver {
   my $xorg_modules_dir = shift;
   my $compat = shift;
   my $result = 0;

   my $xorg_libdir = db_get_answer('LIBDIR') . "/configurator/XOrg/7.$compat" . ($gIs64BitX ? '_64' : '');

   ***REMOVED*** Identify where the vmwgfx_drv.so display driver lives
   my $vmwgfx_drv = $xorg_libdir .  '/vmwgfx_drv.so';
   my $vmwgfx_dri = $xorg_libdir . '/vmwgfx_dri.so';
   my $libexa = $xorg_libdir . '/libexa.so';

   if (-e $vmwgfx_drv && -e $vmwgfx_dri && -e $libexa &&
      (vmware_product() eq 'tools-for-linux') &&
      ($gOption{'install-vmwgfx'} == 1) &&
      $gSystem{'version_integer'} >= kernel_version_integer(2, 6, 25) &&
      (get_persistent_answer(
        '[EXPERIMENTAL] The VMware Video Driver (vmwgfx) is '
        . 'a new feature that enables graphical capabilities '
        . 'such as Kernel Mode Setting (KMS) and RandR 1.2 '
        . 'in virtual machines. '
        . 'Please refer to the VMware Knowledge Base for more '
        . 'details on this capability. Do you wish to enable '
        . 'this feature?', 'XPRMNTL_VMWGFX',
        'yesno', 'no') eq 'yes')) {

      configure_vmwgfx();
      if ((get_module_status("vmwgfx") ne 'not_installed' and
           get_module_status("vmwgfx") ne 'compiled_in') &&
         install_x_module($vmwgfx_drv, $xorg_modules_dir . '/drivers/vmwgfx_drv.so')) {

         install_x_module_no_checks($vmwgfx_dri, '/usr/lib' . ($gIs64BitX ? '64' : '') . '/dri/vmwgfx_dri.so');
         install_x_module_no_checks($libexa, $xorg_modules_dir . '/libexa.so');

         ***REMOVED*** Find the libkms and libdrm used by the system and replace them.
         my $libdrm = 'libdrm.so.2.4.0';
         my $libkms = 'libkms.so.1.0.0';
         my $is64BitUserLand = is64BitUserLand();
         my $libdirname = db_get_answer('LIBDIR');
         my $usrlibdir = '/usr/lib' . ($is64BitUserLand ? '64/' : '/');

         my $dstDrm = findreqlib($vmwgfx_drv, $libdrm);
         if (!defined($dstDrm)) { $dstDrm = $usrlibdir . $libdrm; }

         my $dstKms = findreqlib($vmwgfx_drv, $libkms);
         if (!defined($dstKms)) { $dstKms = $usrlibdir . $libkms; }

         my $srcDir = $libdirname . '/lib/drm';
         my $tmpDir = $libdirname . '/backupdir';
         my %patch;
         undef %patch;

         safe_mkdir($tmpDir);
         if ($dstDrm eq '') { $dstDrm = $usrlibdir . $libdrm; }
         if ($dstKms eq '') { $dstKms = $usrlibdir . $libkms; }
         backup_file_to_restore($dstDrm, 'LIBDRM', $tmpDir);
         install_file($srcDir . '/' . $libdrm, $dstDrm, \%patch, $cFlagTimestamp);
         backup_file_to_restore($dstKms, 'LIBKMD', $tmpDir);
         install_file($srcDir . '/' . $libkms, $dstKms, \%patch, $cFlagTimestamp);
         system('ldconfig &> /dev/null');

         $result = 1;
      }
   }
   return $result;
}

***REMOVED*** findreqlib(objname, libname);
***REMOVED***
***REMOVED*** Attempt to find the location of the shared library
***REMOVED*** $libname that dynamically-linked object $objname
***REMOVED*** requires.
***REMOVED***
***REMOVED*** Returns the string path to the library, or undef
***REMOVED*** if no library is found.
***REMOVED***
***REMOVED*** Consider the following ldd command and its output
***REMOVED*** (this is from openSuSE 11.3 m3):
***REMOVED***
***REMOVED*** % ldd /usr/lib/vmware-tools/configurator/XOrg/7.6_64/vmwgfx_drv.so
***REMOVED*** ldd: warning: you do not have execution permission for `/usr/lib/vmware-tools/configurator/XOrg/7.6_64/vmwgfx_drv.so'
***REMOVED*** 	linux-vdso.so.1 =>  (0x00007fff9e586000)
***REMOVED*** 	libkms.so.1 => /usr/lib64/libkms.so.1 (0x00007f88cac42000)
***REMOVED*** 	libdrm.so.2 => /usr/lib64/libdrm.so.2 (0x00007f88caa37000)
***REMOVED*** 	libc.so.6 => /lib64/libc.so.6 (0x00007f88ca6d7000)
***REMOVED*** 	/lib64/ld-linux-x86-64.so.2 (0x00007f88cb13d000)
***REMOVED*** 	librt.so.1 => /lib64/librt.so.1 (0x00007f88ca4ce000)
***REMOVED*** 	libpthread.so.0 => /lib64/libpthread.so.0 (0x00007f88ca2b0000)
***REMOVED***
***REMOVED*** For each line, look for $objname, and assume that when and if
***REMOVED*** we find it, it has the form:
***REMOVED***
***REMOVED*** 	libkms.so.1 => /usr/lib64/libkms.so.1 (0x00007f88cac42000)
***REMOVED***
***REMOVED*** Split this and take the 3rd substring (at index 2) as the
***REMOVED*** location of the library. Require it to be an absolute path.
***REMOVED***
***REMOVED*** If any of this fails, return undef
***REMOVED***
sub findreqlib {
   my $objname = shift;
   my $libname = shift;

   my @fields;
   my $location = undef;
   my $lddbin = shell_string($gHelper{'ldd'});

   if (open(LDD, "$lddbin $objname 2>&1 |")) {
      while (<LDD>) {
         next if not m/$libname/;
         @fields = split;
      }
      close LDD;

      ***REMOVED*** Expect the location to be an absolute path.
      ***REMOVED*** Anything else will be treated as "not found."
      if (defined($fields[2]) && $fields[2] =~ m|^/|) {
         $location = $fields[2];
      }
   }
   return $location;
}

sub fix_X_link {
  my $x_version = shift;
  my $x_server_link;
  my $x_server_link_bin = xserver_bin() . '/X';
  my $x_wrapper_file_name = 'Xwrapper';
  my $x_wrapper_file = xserver_bin() . '/' . $x_wrapper_file_name;
  my $x_server_file;
  my $x_server_file_name;

  if ($x_version == 3) {
      $x_server_file = xserver3();
  } elsif ($x_version == 4) {
      $x_server_file = xserver4();
  } elsif ($x_version == 6) {
      $x_server_file = xserver_xorg();
  } elsif ($x_version == 7) {
      $x_server_file = xserver_xorg();
  }

  $x_server_file_name = internal_basename($x_server_file);

  ***REMOVED*** Case 1:
  ***REMOVED*** In this case, the Xwrapper is used if /etc/X11/X exists (could be broken)
  ***REMOVED*** _and_ /usr/X11R6/bin/X points to Xwrapper.
  ***REMOVED*** In this case, the Xwrapper will execute setuid anything /etc/X11/X
  ***REMOVED*** is pointing to. So /etc/X11/X has to be pointing to the correct X
  ***REMOVED*** server, this is XFree86 if XFree 4 is used, our driver if XFree 3 is used.
  ***REMOVED*** WARNING: In this case, someone could very easily create a link /etc/X11/X
  ***REMOVED*** pointing to the Xwrapper, which, of course creates and infinite loop.
  ***REMOVED*** On SuSE, this mechanism is completely broken because Xwrapper tries to run
  ***REMOVED*** /usr/X11R6/bin/X !
  ***REMOVED*** In general, The wrapper is stupid.
  $x_server_link = '/etc/X11/X';
  if (-l $x_server_link &&
      check_link($x_wrapper_file, $x_server_link_bin) eq 'yes') {
    symlink_if_needed($x_server_file, $x_server_link);
    set_uid_X_server($x_server_file);
    return;
  }

  ***REMOVED*** Case 2:
  ***REMOVED*** This case is often encountered on a SuSE system.
  ***REMOVED*** Where /var/X11R6/bin/X is a little like /etc/X11/X but the Xwrapper is
  ***REMOVED*** never used on a SuSE system, of course, there could be special cases.
  ***REMOVED*** We might be tempted to zap the use of this var place
  ***REMOVED*** but startx checks for X link and refuses to start if not present in var.
  ***REMOVED*** Of course, it doesn't check where it points to :-)
  $x_server_link = '/var/X11R6/bin/X';
  if (-d internal_dirname($x_server_link)) {
    symlink_if_needed($x_server_file, $x_server_link);
    symlink_if_needed($x_server_link, $x_server_link_bin);
    set_uid_X_server($x_server_file);
    return;
  }

  ***REMOVED*** Case 3:
  ***REMOVED*** All the remaining cases, where the /usr/X11R6/bin/X bin link should be
  ***REMOVED*** pointing to a setuid root X server.
  $x_server_link = '/usr/X11R6/bin/X';
  symlink_if_needed($x_server_file, $x_server_link_bin);
  set_uid_X_server($x_server_file);
}

sub xorg {
  my $xconfig_path = '/etc/X11';
  my $xconfig_file_name = 'xorg.conf';
  my $xversion = 6;
  my $xversionAll = '';
  my $xorgServerVersion = '';
  my $xserver_link = '';
  my $major;
  my $minor;
  my $disableHotPlug = 'no';
  my $sub;
  my %p;
  undef %p;

  ($xversionAll, $xorgServerVersion) = getXorgVersionAll();

  if (defined $ENV{'XORGCONFIG'} && file_name_exist('/etc/X11/' .
      $ENV{'XORGCONFIG'})) {
    $xconfig_path = '/etc/X11';
    $xconfig_file_name = $ENV{'XORGCONFIG'};
  } elsif (defined $ENV{'XORGCONFIG'} &&
           file_name_exist('/usr/X11R6/etc/X11/' . $ENV{'XORGCONFIG'})) {
    $xconfig_path = '/usr/X11R6/etc/X11';
    $xconfig_file_name = $ENV{'XORGCONFIG'};
  } elsif (file_name_exist('/etc/X11/xorg.conf-4')) {
    $xconfig_path = '/etc/X11';
    $xconfig_file_name = 'xorg.conf-4';
  } elsif (file_name_exist('/etc/X11/xorg.conf')) {
    $xconfig_path = '/etc/X11';
    $xconfig_file_name = 'xorg.conf';
  } elsif (file_name_exist('/etc/xorg.conf')) {
    $xconfig_path = '/etc';
    $xconfig_file_name = 'xorg.conf';
  } elsif (file_name_exist('/usr/X11R6/etc/X11/xorg.conf-4')) {
    $xconfig_path = '/usr/X11R6/etc/X11';
    $xconfig_file_name = 'xorg.conf-4';
  } elsif (file_name_exist('/usr/X11R6/etc/X11/xorg.conf')) {
    $xconfig_path = '/usr/X11R6/etc/X11';
    $xconfig_file_name = 'xorg.conf';
  } elsif (file_name_exist('/usr/X11R6/lib/X11/xorg.conf-4')) {
    $xconfig_path = '/usr/X11R6/lib/X11';
    $xconfig_file_name = 'xorg.conf-4';
  } elsif (file_name_exist('/usr/X11R6/lib/X11/xorg.conf')) {
    $xconfig_path = '/usr/X11R6/lib/X11';
    $xconfig_file_name = 'xorg.conf';
  } elsif (file_name_exist('/etc/X11/.xorg.conf') && ! -e '/etc/X11/xorg.conf') {
    ***REMOVED*** For Solaris so that we patch the xorg file shipped
    install_file('/etc/X11/.xorg.conf', '/etc/X11/xorg.conf', \%p, 0);
    $xconfig_path = '/etc/X11';
    $xconfig_file_name = 'xorg.conf';
  }

  print wrap("\n\n Detected " .
             ($xorgServerVersion ? "X server version $xorgServerVersion" :
              "X version $xversionAll") .
             "\n\n", 0);

  ($major, $minor, $sub) = split_X_version($xversionAll);

  ***REMOVED*** vmmouse binary shipped with some distribution is buggy
  ***REMOVED*** Input hotplug needs to be turned off for X Server > 1.4.0.
  ***REMOVED*** The workaround is to add
  ***REMOVED***       Option      "NoAutoAddDevices"
  ***REMOVED*** in ServerFlags section for build 1.4.0 and upwards.
  ***REMOVED*** See 291453 and
  ***REMOVED*** http://docs.fedoraproject.org/release-notes/f9/en_US/sn-Desktop.html***REMOVED***vmmouse-driver
  ***REMOVED*** Release 1.4.0 came out as part of Xorg 7.3
  if ($major == 7 && $minor >= 3) {
    $disableHotPlug = 'yes';
  }

  ***REMOVED*** If there is an existing driver, replace it by ours.
  if ($major == 6) {
    ***REMOVED*** If there is an existing driver replace it by ours, backing up the existing driver.

    ***REMOVED*** Install the drivers.
    if ($minor == 7) {
      install_x_module(db_get_answer('LIBDIR')  . '/configurator/XOrg/6.7.x' .
                       ($gIs64BitX ? '_64' : '') . '/vmware_drv.o',
                       $gXVideoDriverFile);
      install_x_module(db_get_answer('LIBDIR')  . '/configurator/XOrg/6.7.x' .
                       ($gIs64BitX ? '_64' : '') . '/vmmouse_drv.o',
                       $gXMouseDriverFile);

      if (vmware_product() eq 'tools-for-linux') {
        if (!$gIs64BitX) {
          set_manifest_component('svga67', 'TRUE');
          set_manifest_component('vmmouse67', 'TRUE');
        } else {
          set_manifest_component('svga67_64', 'TRUE');
          set_manifest_component('vmmouse67_64', 'TRUE');
        }
      }
    } elsif ($minor == 8) {
      ***REMOVED*** Solaris is an early adopter and is using .so drivers on 6.8.x
      my $suffix = vmware_product() eq 'tools-for-solaris' ? '.so' : '.o';

      install_x_module(db_get_answer('LIBDIR')  . '/configurator/XOrg/6.8.x' .
                       ($gIs64BitX ? '_64' : '') . '/vmware_drv' . $suffix,
                       $gXVideoDriverFile);
      install_x_module(db_get_answer('LIBDIR')  . '/configurator/XOrg/6.8.x' .
                       ($gIs64BitX ? '_64' : '') . '/vmmouse_drv' . $suffix,
                       $gXMouseDriverFile);

      if (vmware_product() eq 'tools-for-linux') {
        if (!$gIs64BitX) {
          set_manifest_component('svga68', 'TRUE');
          set_manifest_component('vmmouse68', 'TRUE');
        } else {
          set_manifest_component('svga68_64', 'TRUE');
          set_manifest_component('vmmouse68_64', 'TRUE');
        }
      }
    } elsif ($minor == 9 && (vmware_product() eq 'tools-for-solaris'
			     || vmware_product() eq 'tools-for-linux')) {
       ***REMOVED*** The 7.0 drivers work on 6.9.x as well (see bug 92501)
       ***REMOVED*** gxMouseDriverFile and gxVideoDriverFile have already been set for Solaris
       ***REMOVED*** by configure_X().  Use xorg paths for 6.9 instead of old XFree ones.
       if (vmware_product() ne 'tools-for-solaris') {
          my $xorg_modules_dir = xorg_find_modules_dir();
          $gXMouseDriverFile = $xorg_modules_dir . '/input/vmmouse_drv.so';
          $gXVideoDriverFile = $xorg_modules_dir . '/drivers/vmware_drv.so';
       }
      install_x_module(db_get_answer('LIBDIR')  . '/configurator/XOrg/7.0' .
                       ($gIs64BitX ? '_64' : '') . '/vmware_drv.so',
                       $gXVideoDriverFile);
      install_x_module(db_get_answer('LIBDIR')  . '/configurator/XOrg/7.0' .
                       ($gIs64BitX ? '_64' : '') . '/vmmouse_drv.so',
                       $gXMouseDriverFile);
    } elsif ($minor == 9 && vmware_product() eq 'tools-for-freebsd') {
      install_x_module(db_get_answer('LIBDIR') . '/configurator/XOrg/6.9' .
                       ($gIs64BitX ? '_64' : '') . '/vmware_drv.so',
                       $gXVideoDriverFile);
      install_x_module(db_get_answer('LIBDIR') . '/configurator/XOrg/6.9' .
                       ($gIs64BitX ? '_64' : '') . '/vmmouse_drv.so',
                       $gXMouseDriverFile);
    } else {
       print wrap("\n\n No drivers for " .
                  ($xorgServerVersion ? "X server version $xorgServerVersion" :
                   "X version $xversionAll") .
                  "\n\n", 0);
       $gNoXDrivers = 1; ***REMOVED*** Use this variable to alert about missing drivers
    }
    fix_X_link('6');
  } elsif ($major == 7 && $minor >= 0 && $minor <= 6) {

     my $compat = $minor;

     ***REMOVED*** use 7.1 drivers for 7.2
     if ($minor == 2 && vmware_product() ne 'tools-for-solaris') {
        $compat = 1;
     }

     ***REMOVED*** gxMouseDriverFile and gxVideoDriverFile have already been set for Solaris
     ***REMOVED*** by configure_X().
     if (vmware_product() ne 'tools-for-solaris') {
        my $xorg_modules_dir = xorg_find_modules_dir();
        $gXMouseDriverFile = $xorg_modules_dir . '/input/vmmouse_drv.so';
        $gXVideoDriverFile = $xorg_modules_dir . '/drivers/vmware_drv.so';
     }

     ***REMOVED*** If there is an existing driver replace it by ours, backing up
     ***REMOVED*** the existing driver.

     ***REMOVED*** Just in case the destination directories don't exist.
     safe_mkdir(internal_dirname($gXVideoDriverFile));
     safe_mkdir(internal_dirname($gXMouseDriverFile));

     ***REMOVED*** Install the drivers.
     my %p;
     undef %p;
     ***REMOVED*** 7.3.99 is a special case under Linux with a special driver
     if ((vmware_product() eq 'tools-for-linux') && ($major == 7) && ($minor == 3) && ($sub == 99)) {
        install_x_module(db_get_answer('LIBDIR') . "/configurator/XOrg/7.$compat.99" .
                         ($gIs64BitX ? '_64' : '') . '/vmware_drv.so',
                         $gXVideoDriverFile);
        install_x_module(db_get_answer('LIBDIR') . "/configurator/XOrg/7.$compat.99" .
                         ($gIs64BitX ? '_64' : '') . '/vmmouse_drv.so',
                         $gXMouseDriverFile);
     } else {
        ***REMOVED*** For minor versions > 5, if the sub is == 99, assume that it's a pre-release for
        ***REMOVED*** the next version of xorg-server and treat it as the next version.
        ***REMOVED*** The minor version of 5 was chosen to prevent regressions from appearing
        ***REMOVED*** in code that is known to work with older versions of xorg-server
        if ((vmware_product() eq 'tools-for-linux') && ($minor > 5) && ($sub == 99)) {
           $compat ++;
           print wrap("Detected a pre-release version of Xorg X server.\n");
        }

        my $xorg_modules_dir = xorg_find_modules_dir();
        my $xorgModSrcDir32 = db_get_answer('LIBDIR')  . "/configurator/XOrg/7.$compat";
        my $xorgModSrcDir64 = $xorgModSrcDir32 . '_64';
        my $xorgModSrcDir = $gIs64BitX ? $xorgModSrcDir64 : $xorgModSrcDir32;

        ***REMOVED*** Now check to make sure the drivers exist.
        if ( -d $xorgModSrcDir ) {
           if (vmware_product() eq 'tools-for-solaris') {
              ***REMOVED*** Need to attempt to install both 32 and 64 bit versions of the
              ***REMOVED*** xorg drivers on Solaris.

              ***REMOVED*** 32 bit
              my $xorgModsDriverDir32 = join('/', $xorg_modules_dir, 'drivers');
              my $xorgModsInputDir32 = join('/', $xorg_modules_dir, 'input');
              install_x_module($xorgModSrcDir32 . '/vmware_drv.so',
                               $xorgModsDriverDir32 . '/vmware_drv.so');
              install_x_module($xorgModSrcDir32 . '/vmmouse_drv.so',
                               $xorgModsInputDir32 . '/vmmouse_drv.so');
              ***REMOVED*** For 2 and above on Solaris, vmware_drv.so is just a shim which
              ***REMOVED*** loads vmwlegacy or vmwgfx, so we need to lay those down.
              if ($compat >= 2) {
                 install_x_module($xorgModSrcDir32 . '/vmwlegacy_drv.so',
                                  $xorgModsDriverDir32 . '/vmwlegacy_drv.so');
              }

              ***REMOVED*** 64 bit.
              ***REMOVED*** The 64 bit dest path is the 32 bit dest path with
              ***REMOVED*** the amd64 directory appended to the end of the path.
              my $xorgModsDriverDir64 = join('/', $xorgModsDriverDir32, 'amd64');
              my $xorgModsInputDir64 = join('/', $xorgModsInputDir32, 'amd64');
              if (-d $xorgModsDriverDir64 and -d $xorgModsInputDir64) {
                 install_x_module($xorgModSrcDir64 . '/vmware_drv.so',
                                  $xorgModsDriverDir64 .'/vmware_drv.so');
                 install_x_module($xorgModSrcDir64 . '/vmmouse_drv.so',
                                  $xorgModsInputDir64 .'/vmmouse_drv.so');
                 ***REMOVED*** For 2 and above on Solaris, vmware_drv.so is just a shim which
                 ***REMOVED*** loads vmwlegacy or vmwgfx, so we need to lay those down.
                 if ($compat >= 2) {
                    install_x_module($xorgModSrcDir64 . '/vmwlegacy_drv.so',
                                     $xorgModsDriverDir64 . '/vmwlegacy_drv.so');
                 }
              }
           } else {
              install_x_module($xorgModSrcDir . '/vmware_drv.so',
                               $xorg_modules_dir . '/drivers/vmware_drv.so');
              install_x_module($xorgModSrcDir . '/vmmouse_drv.so',
                               $xorg_modules_dir . '/input/vmmouse_drv.so');

              ***REMOVED*** For minor >= 6 on FreeBSD and minor >= 1 on Linux, install vmwlegacy.
              ***REMOVED*** vmware_drv.so is just a shim which loads vmwlegacy
              ***REMOVED*** or vmwgfx, so we need to lay those down.
              if ((vmware_product() eq 'tools-for-freebsd' && $compat >= 6) ||
                  (vmware_product() eq 'tools-for-linux' && $compat >= 1)) {
                 install_x_module($xorgModSrcDir . '/vmwlegacy_drv.so',
                                  $xorg_modules_dir . '/drivers/vmwlegacy_drv.so');
                 configure_vmware_gfx_driver($xorg_modules_dir, $compat);
              }
           }
        } else {
           ***REMOVED*** No Xorg drivers.  Stop configuring X.
           print wrap("\n\n No drivers for " .
                      ($xorgServerVersion ? "X server version $xorgServerVersion" :
                       "X version $xversionAll") .
                      "\n\n", 0);
           $gNoXDrivers = 1; ***REMOVED*** Use this variable to alert about missing drivers
           return ($xversion, xconfig_file_abs_path($xconfig_path, $xconfig_file_name),
                   $xversionAll, $disableHotPlug);
        }
     }

     ***REMOVED*** Now for all of the HAL configuration.  Only attempt to configure HAL if
     ***REMOVED*** we are Linux or Solaris and minor version >= 4.
     if ($compat >= 4 &&
         (vmware_product() eq 'tools-for-linux' ||
          vmware_product() eq 'tools-for-solaris')) {
        ***REMOVED*** Install vmmouse_detect always for compat >= 4
        backup_file_to_restore('/usr/bin/vmmouse_detect', 'VMMOUSE_DETECT');
        install_file(db_get_answer('LIBDIR') . "/configurator/XOrg/7.$compat" .
                     ($gIs64BitX ? '_64' : '') . '/vmmouse_detect',
                     '/usr/bin/vmmouse_detect', \%p, 1);

        ***REMOVED*** Check if they use HAL.  If HAL's dirs are present, install our bits.
        ***REMOVED*** Note: The order of directories in @halDirs is important!
        my $halScript = undef;
        my $halName = undef;
        ($halScript, $halName) = get_hal_script_name();
        if (defined($halName)) {
           my @halDirs = ('/usr/lib/hal/scripts', '/usr/lib/hal', '/usr/libexec');
           db_add_answer('HAL_RESTART_ON_UNINSTALL', 'no');
           foreach my $dir (@halDirs) {
              if (-d $dir) {
                 backup_file_to_restore("$dir/hal-probe-vmmouse", 'HAL_PROBE_VMMOUSE');
                 install_file(db_get_answer('LIBDIR') . "/configurator/XOrg/7.$compat" .
                              ($gIs64BitX ? '_64' : '') . '/hal-probe-vmmouse',
                              "$dir/hal-probe-vmmouse", \%p, 1);

                 my $vmmouseFDIPath;
                 if (vmware_product() eq 'tools-for-solaris') {
                    $vmmouseFDIPath = '/etc/hal/fdi/policy/' .
                        '20thirdparty/11-x11-vmmouse.fdi';
                 } else {
                    $vmmouseFDIPath = '/usr/share/hal/fdi/policy/' .
                        '20thirdparty/11-x11-vmmouse.fdi';
                 }

                 backup_file_to_restore($vmmouseFDIPath, 'VMMOUSE_FDI');
                 install_file(db_get_answer('LIBDIR') . "/configurator/XOrg/7.$compat" .
                              ($gIs64BitX ? '_64' : '') . '/11-x11-vmmouse.fdi',
                              $vmmouseFDIPath, \%p, 1);
                 restart_hal();
                 db_add_answer('HAL_RESTART_ON_UNINSTALL', 'yes');
                 ***REMOVED*** Don't search for any more HAL directories.
                 last;
              }
           }
        }
     }

     if (vmware_product() eq 'tools-for-linux') {
        if ($compat == 0) {
           if (!$gIs64BitX) {
              set_manifest_component('svga70', 'TRUE');
              set_manifest_component('vmmouse70', 'TRUE');
           } else {
              set_manifest_component('svga70_64', 'TRUE');
              set_manifest_component('vmmouse70_64', 'TRUE');
           }
        }
        ***REMOVED*** Use 7.1 driver for 7.1 through 7.3.98
        if ($compat == 1) {
           if (!$gIs64BitX) {
              set_manifest_component('svga71', 'TRUE');
              set_manifest_component('vmmouse71', 'TRUE');
           } else {
              set_manifest_component('svga71_64', 'TRUE');
              set_manifest_component('vmmouse71_64', 'TRUE');
           }
        }
        ***REMOVED*** Use 7.3 driver for most 7.3,
        ***REMOVED*** Use 7.3.99 driver for 7.3.99 only.
        if ($compat == 3) {
           if ($sub == 99) {
              if (!$gIs64BitX) {
                 set_manifest_component('svga73_99', 'TRUE');
                 set_manifest_component('vmmouse73_99', 'TRUE');
              } else {
                 set_manifest_component('svga73_99_64', 'TRUE');
                 set_manifest_component('vmmouse73_99_64', 'TRUE');
              }
           }
           else {
              if (!$gIs64BitX) {
                 set_manifest_component('svga73', 'TRUE');
                 set_manifest_component('vmmouse73', 'TRUE');
              } else {
                 set_manifest_component('svga73_64', 'TRUE');
                 set_manifest_component('vmmouse73_64', 'TRUE');
              }
           }
        }

        if ($compat >= 4) {
           ***REMOVED*** Ubuntu 10.04 (and eventually other distros) use device kit to load vmmouse
           ***REMOVED*** instad of HAL.  Note both HAL and DeviceKit can be installed side by side.
           if ($minor >= 6) {
              configureDeviceKitVmmouse();
           }

           ***REMOVED*** Update the Manifest.  Entries look something like svga74_64.
           my $bitExt = ($gIs64BitX) ? '_64' : '';
           my $manifestExt = join('', $major, $compat, $bitExt);
           my $svgaManifestTxt = join('', 'svga', $manifestExt);
           my $vmmouseManifestTxt = join('', 'vmmouse', $manifestExt);
           set_manifest_component($svgaManifestTxt, 'TRUE');
           set_manifest_component($vmmouseManifestTxt, 'TRUE');
        }
     }
  } elsif ($major == 7 && $minor > 6) {
     $gNoXDrivers = 1; ***REMOVED*** Drivers are upstreamed
     print wrap("\n\nDistribution provided drivers for Xorg X server are used.\n\n", 0);
  } else {
     $gNoXDrivers = 1; ***REMOVED*** Use this variable to alert about missing drivers
       print wrap("\n\n No drivers for " .
                  ($xorgServerVersion ? "X server version $xorgServerVersion" :
                   "X version $xversionAll") .
                  "\n\n", 0);
  }
  return ($xversion, xconfig_file_abs_path($xconfig_path, $xconfig_file_name),
          $xversionAll, $disableHotPlug);
}

***REMOVED*** Different xorg installations may store their modules in different places.
sub xorg_find_modules_dir {
   ***REMOVED*** have to add /usr/X11R6/lib/modules to work with SLES 10 which has xorg
   ***REMOVED*** but uses this old path.  lib64 must come before lib because both are
   ***REMOVED*** present on x64 machines with drivers being in lib64.
   ***REMOVED*** if the updates dir presents, assume it is using SuSE's "Xserver module
   ***REMOVED*** update mechanism".
   my @modDirs = qw(/usr/lib64/xorg/modules/updates
                    /usr/lib64/xorg/modules
                    /usr/lib/xorg/modules/updates
                    /usr/lib/xorg/modules
                    /usr/X11R6/lib64/modules
                    /usr/local/lib/xorg/modules
                    /usr/X11R6/lib/modules
                    /usr/X11R6/lib/xorg/modules);
   foreach my $modDir (@modDirs) {
      if (-d $modDir) {
         return $modDir;
      }
   }

   return get_persistent_answer('What is the location of the directory which contains ' .
      'your XOrg modules?', 'XORGMODULEDIR', 'dirpath_existing', '');
}

sub xfree_4 {
  my $xconfig_path;
  my $xconfig_file_name;
  my $xversionAll = '';
  my $xserver_link = '';
  my $major;
  my $minor;
  my $sub;

  $xversionAll = direct_command(shell_string(xserver4()) . ' -version 2>&1') =~
    /XFree86 Version (\d+\.\d+\.?\d*)/ ? $1: '0.0.0';

  ***REMOVED*** This search order is issued from the XF86Config man page.
  if (defined $ENV{'XF86CONFIG'} &&
      file_name_exist('/etc/X11/' . $ENV{'XF86CONFIG'})) {
    $xconfig_path = '/etc/X11';
    $xconfig_file_name = $ENV{'XF86CONFIG'};
  } elsif (defined $ENV{'XF86CONFIG'} &&
           file_name_exist('/usr/X11R6/etc/X11/' . $ENV{'XF86CONFIG'})) {
    $xconfig_path = '/usr/X11R6/etc/X11';
    $xconfig_file_name = $ENV{'XF86CONFIG'};
  } elsif (file_name_exist('/etc/X11/XF86Config-4')) {
    $xconfig_path = '/etc/X11';
    $xconfig_file_name = 'XF86Config-4';
  } elsif (file_name_exist('/etc/X11/XF86Config')) {
    ***REMOVED*** In this case, we are in the situation of having a mix between
    ***REMOVED*** XFree 3 and XFree 4, which is usually the case on RH 7.x and
    ***REMOVED*** Mandrake 7.x systems. As far as the syntax is concerned, XF86Config
    ***REMOVED*** is the 3.x version and XF86Config-4 is the 4.x version.
    ***REMOVED*** fix_X_conf patches some of the fields of the old config file into the new
    ***REMOVED*** one. There are issues if 3.x syntax fields are patched in a 4.x config
    ***REMOVED*** file. By providing a non existing file fix_X_conf will generate a correct
    ***REMOVED*** one or if the XF86Config file has the XFree 4 syntax, we can use it.
    ***REMOVED*** See bug 23196.
    $xconfig_path = '/etc/X11';
    if (direct_command(shell_string($gHelper{'grep'}) . ' '
                       . shell_string('.*') . ' '
                       . '/etc/X11/XF86Config') =~ /Section\s+\"ServerLayout\"/i) {
      $xconfig_file_name = 'XF86Config';
    } else {
      $xconfig_file_name = 'XF86Config-4';
    }
  } elsif (file_name_exist('/etc/XF86Config')) {
    $xconfig_path = '/etc';
    $xconfig_file_name = 'XF86Config';
  } elsif (file_name_exist('/usr/X11R6/etc/X11/XF86Config-4')) {
    $xconfig_path = '/usr/X11R6/etc/X11';
    $xconfig_file_name = 'XF86Config-4';
  } elsif (file_name_exist('/usr/X11R6/etc/X11/XF86Config')) {
    $xconfig_path = '/usr/X11R6/etc/X11';
    $xconfig_file_name = 'XF86Config';
  } elsif (file_name_exist('/usr/X11R6/lib/X11/XF86Config')) {
    ***REMOVED*** FreeBSD 5.2 after running xf86config in graphic mode
    $xconfig_path = '/usr/X11R6/lib/X11';
    $xconfig_file_name = 'XF86Config';
  } else {
    ***REMOVED*** X config file not found
    return (4, undef, $xversionAll);
  }

  if (defined $xconfig_file_name) {
     print wrap("\n\n" . 'Detected XFree86 version ' . $xversionAll . '.'
                . "\n\n", 0);
  }

  ***REMOVED*** If there is an existing driver, replace it by ours.
  backup_file_to_restore($gXVideoDriverFile, 'OLD_X4_DRV');
  if (file_name_exist($gXVideoDriverFile)) {
      unlink $gXVideoDriverFile;
  }

  ($major, $minor, $sub) = split_X_version($xversionAll);
  if ($major == 4) {
    if ($minor == 2) {
      ***REMOVED*** For XFree 4.2.x, we need to replace xaa and shadowfb
      my $xaaDrv = '/usr/X11R6/lib/modules/libxaa.a';
      my $shadowFbDrv = '/usr/X11R6/lib/modules/libshadowfb.a';
      backup_file_to_restore($xaaDrv, 'OLD_X4_XAA_DRV');
      backup_file_to_restore($shadowFbDrv, 'OLD_X4_SHADOW_FB_DRV');
      unlink $xaaDrv;
      unlink $shadowFbDrv;
      my %p;
      undef %p;
      install_file(db_get_answer('LIBDIR')
                   . '/configurator/XFree86-4/4.2.x/libxaa.a',
                   $xaaDrv, \%p, 1);
      install_file(db_get_answer('LIBDIR')
                   . '/configurator/XFree86-4/4.2.x/libshadowfb.a',
                   $shadowFbDrv, \%p, 1);
      install_file(db_get_answer('LIBDIR')
                   . '/configurator/XFree86-4/4.2.x/vmware_drv.o',
                   $gXVideoDriverFile, \%p, 1);

      if (vmware_product() eq 'tools-for-linux') {
        set_manifest_component('svga42', 'TRUE');
      }
    } elsif ($minor > 2) {
      ***REMOVED*** In this case, all the XAA and ShadowFB changes are present
      ***REMOVED*** in the XFree Code and we only need to install the latest
      ***REMOVED*** driver.
      my %p;
      undef %p;
      install_file(db_get_answer('LIBDIR') . '/configurator/XFree86-4/4.3.x' .
		   ($gIs64BitX ? '_64' : '') . '/vmware_drv.o',
		   $gXVideoDriverFile, \%p, 1);

      if ($minor == 3 && vmware_product() eq 'tools-for-linux') {
        if (!$gIs64BitX) {
          set_manifest_component('svga43', 'TRUE');
        } else {
          set_manifest_component('svga43_64', 'TRUE');
        }
      }
    } elsif ($minor < 2) {
      ***REMOVED*** The default, install the X free 4 driver which works with
      ***REMOVED*** the first versions of X.
      my %p;
      undef %p;
      install_file(db_get_answer('LIBDIR')
                   . '/configurator/XFree86-4/4.x/vmware_drv.o',
                   $gXVideoDriverFile, \%p, 1);

      if (vmware_product() eq 'tools-for-linux') {
        set_manifest_component('svga4', 'TRUE');
      }
    }
    ***REMOVED*** Absolute pointing device.
    if ($major == 4 && $minor == 2) {
      my %p;
      undef %p;
      install_file(db_get_answer('LIBDIR')
		   . '/configurator/XFree86-4/4.2.x/vmmouse_drv.o',
		   $gXMouseDriverFile, \%p, 1);

      if (vmware_product() eq 'tools-for-linux') {
        set_manifest_component('vmmouse42', 'TRUE');
      }
    } elsif ($major == 4 && $minor == 3) {
        my %p;
        undef %p;
        install_file(db_get_answer('LIBDIR') . '/configurator/XFree86-4/4.3.x' .
           ($gIs64BitX ? '_64' : '') . '/vmmouse_drv.o',
           $gXMouseDriverFile, \%p, 1);

        if (vmware_product() eq 'tools-for-linux') {
          if (!$gIs64BitX) {
            set_manifest_component('vmmouse43', 'TRUE');
          } else {
            set_manifest_component('vmmouse43_64', 'TRUE');
          }
        }
      }
    fix_X_link('4');
  } else {
    error ('Problem extracting version of XFree 4' . "\n\n");
  }
  return (4, xconfig_file_abs_path($xconfig_path, $xconfig_file_name),
          $xversionAll);
}

sub xfree_3 {
  my $xconfig_path = '/etc';
  my $xconfig_file_name = 'XF86Config';
  my $xversion = 3;
  my $xversionAll = 0;
  my $xserver3default = xserver_bin() . '/XF86_VGA16';
  my $xserver_link = '';

  $xversionAll = file_name_exist($xserver3default) ?
              direct_command(shell_string($xserver3default) .
                             ' -version 2>&1') =~
                             /XFree86 Version (\d+\.\d+\.?\d*)/ ? $1: '3.0'
                             : '3.0';

  if (file_name_exist('/etc/XF86Config')) {
    $xconfig_path = '/etc';
    $xconfig_file_name = 'XF86Config';
  } elsif (file_name_exist('/usr/X11R6/lib/X11/XF86Config') &&
           (not -l '/usr/X11R6/lib/X11/XF86Config')) {
    $xconfig_path = '/usr/X11R6/lib/X11';
    $xconfig_file_name = 'XF86Config';
  } else {
    $xconfig_path = '/etc';
    $xconfig_file_name = 'XF86Config';
  }
  print wrap("\n\n" . 'Detected XFree86 version ' . $xversionAll . '.'
             . "\n\n", 0);

  if (file_name_exist(xserver3())) {
    backup_file(xserver3());
    unlink xserver3();
  }

  if (vmware_product() eq 'tools-for-freebsd' &&
      $gSystem{'uts_release'} =~ /^(\d+)\.(\d+)/ &&
      $1 >= 4 && $2 >= 5) {
    my %p;
    undef %p;
    install_file(db_get_answer('LIBDIR')
                 . '/configurator/XFree86-3/XF86_VMware_4.5',
                 xserver3(), \%p, 1);
  } else {
    my %p;
    undef %p;
    install_file(db_get_answer('LIBDIR')
                 . '/configurator/XFree86-3/XF86_VMware',
                 xserver3(), \%p, 1);
  }

  if (vmware_product() eq 'tools-for-linux') {
    set_manifest_component('svga33', 'TRUE');
  }

  fix_X_link('3');
  return ($xversion, xconfig_file_abs_path($xconfig_path, $xconfig_file_name),
          $xversionAll);
}

sub fix_mouse_file {
  my $mouse_file = '/etc/sysconfig/mouse';
  ***REMOVED***
  ***REMOVED*** If gpm supports imps2, use that as the gpm mouse driver
  ***REMOVED*** for both X & gpm. If gpm doesn't support imps2, or isn't set
  ***REMOVED*** in this mode, the mouse will be erratic when exiting X if
  ***REMOVED*** X was set to use imps2
  ***REMOVED***
  my $enableXImps2 = 'no';
  my $GPMBinary = internal_which('gpm');
  if (file_name_exist($GPMBinary) && file_name_exist($mouse_file)) {
    my $enableGpmImps2;

    if (vmware_product() eq 'tools-for-solaris') {
      $enableGpmImps2 =
        (system(shell_string($GPMBinary) . ' -t help | ' . $gHelper{'grep'}
                . ' imps2 > /dev/null 2>&1')) == 0 ? 'yes': 'no';
    } else {
      $enableGpmImps2 =
        (system(shell_string($GPMBinary) . ' -t help | '
                . $gHelper{'grep'} . ' -q imps2')) == 0 ? 'yes': 'no';
    }
    $enableXImps2 = $enableGpmImps2;

    if ($enableGpmImps2 eq 'yes' ) {
      backup_file_to_restore($mouse_file, 'MOUSE_CONF');
      unlink $mouse_file;
      my %p;
      undef %p;
      $p{'^MOUSETYPE=.*$'} = 'MOUSETYPE=imps2';
      $p{'^XMOUSETYPE=.*$'} = 'XMOUSETYPE=IMPS/2';
      internal_sed($mouse_file . $cBackupExtension,
                   $mouse_file, 0, \%p);
    }
  }
  return $enableXImps2;
}

***REMOVED*** Create a list of available resolutions for the VMware virtual monitor
sub get_suitable_resolutions {
  my $xf86config = shift;
  my @list;
  my $in;
  my $identifier;

  open(XF86CONFIG, '<' . $xf86config) or
   error('Unable to open the XFree86 configuration file "'
         . $xf86config . '" in read-mode.' . "\n\n");

  $in = 0;
  while (<XF86CONFIG>) {
    if (/^[ \t]*Section[ \t]*"Monitor"[ \t]*$/) {
      $in = 1;
      $identifier = '';
      @list = ();
    } elsif ($in) {
      if (/^[ \t]*Identifier[ \t]*"(\S+)"[ \t]*$/) {
        $identifier = $1;
      } elsif (/^[ \t]*ModeLine[ \t]*(\S+)[ \t]*(\S+)[ \t]*(\S+)[ \t]*(\S+)[ \t]*(\S+)[ \t]*(\S+)[ \t]*(\S+)[ \t]*(\S+)[ \t]*(\S+)[ \t]*(\S+)[ \t]*$/) {
        push(@list, ($1, $3, $7));
      } elsif (/^[ \t]*EndSection[ \t]*$/) {
        if ($identifier eq 'vmware') {
          last;
        }
        $in = 0;
      }
    }
  }

  close(XF86CONFIG);

  return @list;
}

***REMOVED*** Pull data out of the config file.  The format is expected to be 'ModeLine "1111x9999"'
sub get_supported_modes {
   my $xf86config = shift;
   my @list;

   open(XF86CONFIG, '<' . $xf86config) or error("Unable to open " . $xf86config . ".\n");
   while (<XF86CONFIG>) {
      if (/ModeLine\D+(\d+)x(\d+)/) {
         push(@list, '"' . $1 . "x" . $2 . '"', $1, $2);
      }
   }
   close(XF86CONFIG);

   return @list;
}

***REMOVED*** Determine the name of the maximum available resolution that can fit in the
***REMOVED*** VMware virtual monitor
sub get_best_resolution {
  my $xf86config = shift;
  my $width = shift;
  my $height = shift;
  my @avail_modes;
  my $best_name;
  my $best_res;

  @avail_modes = get_supported_modes($xf86config);

  $best_name = '';
  $best_res = -1;
  while ($***REMOVED***avail_modes > -1) {
    my $mode_name = shift(@avail_modes);
    my $mode_width = shift(@avail_modes);
    my $mode_height = shift(@avail_modes);

    if (($mode_width < $width)
        && ($mode_height < $height)
        && ($mode_width * $mode_height > $best_res)) {
      $best_res = $mode_width * $mode_height;
      $best_name = $mode_name;
    }
  }
  return $best_name;
}

***REMOVED*** Sort available resolutions for the VMware virtual monitor in increasing order
sub sort_resolutions {
  my $xf86config = shift;
  my @avail_modes;
  my %resolutions;
  my $res;
  my $names;

  @avail_modes = get_supported_modes($xf86config);

  undef %resolutions;
  while ($***REMOVED***avail_modes > -1) {
    my $mode_name = shift(@avail_modes);
    my $mode_width = shift(@avail_modes);
    my $mode_height = shift(@avail_modes);

    $resolutions{$mode_width * $mode_height} .= $mode_name . ' ';
  }

  $names = '';
  foreach $res (sort { $a <=> $b } keys %resolutions) {
    $names .= $resolutions{$res};
  }
  if (not ($names eq '')) {
    chomp($names);
  }
  return $names;
}

***REMOVED*** Look for an x config file that first contains a list of modes the driver
***REMOVED*** is expected to support, then look for the more general XF86Config(-4) file,
***REMOVED***  some of whose modes are unsupported by the driver.
sub find_suitable_XConfigFile {
   my $xversion = shift;
   my $XFile;

   ***REMOVED*** ModeList is based in bora/public/modelist.h.  It contains the resolutions
   ***REMOVED*** supported by the driver, whereas XF86Config is a more general list.
   $XFile = db_get_answer('LIBDIR') . '/configurator/ModeLines';
   if (!-f $XFile) {
      my $YFile = $XFile;
      $XFile = db_get_answer('LIBDIR') . '/configurator/XFree86-'
                         . ($xversion >= 4 ? '4' : $xversion) . '/XF86Config'
                         . ($xversion >= 4 ? '-4': '');
      if (!-f $XFile) {
        error("Unable to find " . $YFile . ' or ' . $XFile . ".\n");
      }
   }

   return $XFile;
}

***REMOVED***
***REMOVED*** Try to determine the current screen size
***REMOVED***
sub get_screen_mode {
  my $xversion = shift;
  my $best_resolution = '';
  my $chosen_resolution = '';
  my $suggested_choice = 3;
  my $i = 0;
  my $mode;
  my $choice;
  my @mode_list;
  my $width;
  my $height;
  my $cXPreviousResolution = 'X_PREVIOUS_RES';
  my $cXConfigFile = find_suitable_XConfigFile($xversion);

  my $resolution_string = sort_resolutions($cXConfigFile);
  @mode_list = split(' ', $resolution_string);

  ***REMOVED***
  ***REMOVED*** Set mode according to what was previously chosen in case of an upgrade
  ***REMOVED*** or ask the user a valid range of resolutions.
  ***REMOVED***
  my $prev_res;
  if (defined(db_get_answer_if_exists($cXPreviousResolution))) {
      $prev_res = db_get_answer($cXPreviousResolution);
    if ($resolution_string =~ $prev_res) {
      if (get_answer("\n\n" .
                     'Do you want to change the starting screen display size? (yes/no)',
                     'yesno', 'no') eq 'no') {
        return $prev_res;
      }
    }
  }

  ($width, $height) = split(' ', $gSystem{'resolution'});

  ***REMOVED*** Tell the user what resolution was detected on their host system.
  ***REMOVED*** Do this only for non-ESX systems.
  if (not is_esx_virt_env()) {
     print wrap( "\n" .
                 "Host resolution detected as \"$width x $height\".\n" .
                 "\n ",
                 0);
  }

  $best_resolution =
    get_best_resolution($cXConfigFile, $width, $height);

  print wrap("\n" . 'Please choose one of the following display sizes that X '
                  . 'will start with:' . "\n\n",
             0);
  foreach $mode (@mode_list) {
    my $header;
    $i = $i + 1;
    if ($best_resolution eq $mode) {
      $suggested_choice = $i;
      $header = '<';
      print wrap('[' . $i . ']' . $header . ' ' . $mode . "\n", 0);
      last;
    } else {
      $header = ' ';
      print wrap('[' . $i . ']' . $header . ' ' . $mode . "\n", 0);
    }
  }

  $gMaxNumber = $i;
  $gAnswerSize{'number'} = length($gMaxNumber);
  $choice = get_persistent_answer('Please enter a number between 1 and ' . $i
                                  . ':' . "\n\n", 'XRESNUMBER', 'number',
                                  $suggested_choice);

  $chosen_resolution = $mode_list[$choice - 1];
  db_add_answer($cXPreviousResolution, $chosen_resolution);
  return $chosen_resolution;
}

***REMOVED***
***REMOVED*** The first argument is a complete path to a new xconfig file
***REMOVED*** The second argument will be only read and should be current xconfig file
***REMOVED*** The third argument is the version of XFree86
***REMOVED*** The fourth is a boolean informing weather the Imwheel mouse is used
***REMOVED*** in gpm or not.
***REMOVED*** The fifth is a boolean informing weather an extra section must be added
***REMOVED*** to disable hotplug (see bug 291453).
***REMOVED***
sub fix_X_conf {
  my ($newXF86Config, $existingXF86Config, $xversion, $enableXImps2,
  $xversionAll, $disableHotPlug) = @_;

  my $inSection = 0;
  my $inDevice = 0;
  my $inMonitor = 0;
  my $gotMouseSection = 0;
  my $gotServerLayout = 0;
  my $gotServerFlagsSection = 0;
  my $gotKeyboardSection = 0;
  my $xorgScreenIdentifier = '';
  my @currentSection;
  my $sectionLine;
  my $sectionName;
  my $mouseRegex = '^\s*driver\s+\"(?:mouse|vmmouse)\"';
  my $isMouseSection = 0;

  my $XFree4_scanpci = xserver_bin() . '/scanpci';
  my $major;
  my $minor;
  my $sub;
  my $line;
  my $screen_mode = get_screen_mode($xversion);
  my $needMonitor = 0;
  my %mouseOption = ('"ZAxisMapping"' => '"4 5"',
                     '"Emulate3Buttons"' => '"true"');
  ($major, $minor, $sub) = split_X_version($xversionAll);

  ***REMOVED***
  ***REMOVED*** Check to see if the vmware svga driver is non-unified b/c we have to
  ***REMOVED*** specifiy the BusId in the XF86Config-4 file in that case
  ***REMOVED***
  my $writeBusIDLine = 0;
  if ($xversion >= 4 && file_name_exist($XFree4_scanpci)) {
    my $found = 0;
    if (vmware_product() eq 'tools-for-solaris') {
      if ((system(shell_string($XFree4_scanpci) . ' | '
                 . shell_string($gHelper{'grep'})
                 . ' 0x0710 > /dev/null 2>&1')/256) == 0 ) {
        $found = 1;
      }
    } elsif ((system(shell_string($XFree4_scanpci) . ' | '
                     . shell_string($gHelper{'grep'})
                     . ' -q 0x0710')/256) == 0 ) {
      $found = 1;
    }

    if ($found == 1) {
      $writeBusIDLine = 1;
      ***REMOVED*** print wrap ('Found the device 0x0710' . "\n\n", 0);
    }
  }

  if (not open(EXISTINGXF86CONFIG, "<$existingXF86Config")) {
    error('Unable to open the file "' . $existingXF86Config . '".' . "\n\n");
  }

  if (not open(NEWXF86CONFIG, ">$newXF86Config")) {
    error('Unable to open the file "' . $newXF86Config . '".' . "\n\n");
  }


  while (defined($line = <EXISTINGXF86CONFIG>)) {
    if ($line =~ /^\s*Section\s*"([a-zA-Z]+)"/i) {
      ***REMOVED*** We only deal with lines within sections. For other lines,
      ***REMOVED*** just copy to new file.
      $sectionName = lc($1);
      $inSection = 1;
      push @currentSection, $line;
    } else {
      if ($inSection == 1) {
        if ($line =~ /^\s*EndSection/i) {
          ***REMOVED*** All lines within a section will first be read into
          ***REMOVED*** currentSection, then process those lines.
          push @currentSection, $line;

          if (($sectionName eq 'inputdevice') || ($sectionName eq 'pointer')) {
            ***REMOVED*** There are several different kinds of inputdevice section, such as
            ***REMOVED*** mouse, keyboard, and only mouse section will be re-processed,
            ***REMOVED*** others just copy to new file. 'pointer' is the mouse section name
            ***REMOVED*** for some x config file.
            $isMouseSection = 0;
            if ($sectionName eq 'pointer') {
              $isMouseSection = 1;
            }
            foreach $sectionLine (@currentSection) {
              if ($sectionLine =~ /$mouseRegex/i) {
                $isMouseSection = 1;
                last;
              }
            }

            if ($isMouseSection == 1) {
              $gotMouseSection = 1;
              my $seenDeviceSection = 0;
              foreach $sectionLine (@currentSection) {
                ***REMOVED*** Replace mouse driver
                if ($sectionLine =~ /^\s*Driver\s+\"(.+)\"/i) {
		  ***REMOVED*** Install a mouse driver for all X versions >= 4.2
                  if (file_name_exist($gXMouseDriverFile) &&
		      ($major > 4 || ($major == 4 && $minor >= 2))) {
                    $sectionLine =~ s/$1/vmmouse/g;
                  }
                }

                ***REMOVED*** Replace mouse protocol. There are 2 different formats for mouse
                ***REMOVED*** protocol, so should be handled seperately.
                if (($sectionLine =~ /^\s*Option\s+\"Protocol\"\s+\"(.+)\"/i) ||
                    ($sectionLine =~ /^\s*Protocol\s+\"(.+)\"/i)) {
                  my $tmpmouse = $1;
                  if (vmware_product() eq 'tools-for-freebsd') {
                    if (direct_command(shell_string($gHelper{'grep'}) . ' '
                                       . shell_string('moused_enable') . ' '
                                       . shell_string('/etc/rc.conf')) =~ /yes/i) {
                      $sectionLine =~ s/$tmpmouse/SysMouse/;
                    } else {
                      $sectionLine =~ s/$tmpmouse/ps\/2/;
                    }
                  } elsif ($enableXImps2 eq 'yes') {
                    $sectionLine =~ s/$tmpmouse/IMPS\/2/g;
                  } else {
                    $sectionLine =~ s/$tmpmouse/ps\/2/g;
                  }
                }

                if ($sectionLine =~ /^\s*Option\s+\"ZAxisMapping\"\s+\"(.+)\"/i) {
                   $mouseOption{'"ZAxisMapping"'} = "";
                }
                if ($sectionLine =~ /^\s*Option\s+\"Emulate3Buttons"\s+\"(.+)\"/i) {
                   $mouseOption{'"Emulate3Buttons"'} = "";
                }

                ***REMOVED*** Replace mouse device. There are 2 different formats for mouse
                ***REMOVED*** device, so should be handled seperately.
                if (($sectionLine =~ /^\s*Option\s+\"Device\"\s+\"(.+)\"/i) ||
                    ($sectionLine =~ /^\s*Device\s+\"(.+)\"/i)) {
                  $seenDeviceSection = 1;
                  my $tmpdev = $1;
                  if (vmware_product() eq 'tools-for-freebsd') {
                    if (direct_command(shell_string($gHelper{'grep'}) . ' '
                                       . shell_string('moused_enable') . ' '
                                       . shell_string('/etc/rc.conf')) =~ /yes/i) {
                      $sectionLine =~ s/$tmpdev/\/dev\/sysmouse/;
                    } else {
                      $sectionLine =~ s/$tmpdev/\/dev\/psm0/;
                    }
                  } elsif (vmware_product() eq 'tools-for-linux') {
                     ***REMOVED*** If we have to create a xorg.conf file, the default
                     ***REMOVED*** mouse device is /dev/mouse. Most machines don't have
                     ***REMOVED*** /dev/mouse these days, so check if it's going to fail
                     ***REMOVED*** and try the other alternatives.
                     if (!file_name_exist("$tmpdev")) {
                        ***REMOVED*** Most common case: /dev/input/mice
                        if (file_name_exist("/dev/input/mice")) {
                           $sectionLine =~ s/$tmpdev/\/dev\/input\/mice/;
                        ***REMOVED*** 2.4 case: /dev/psaux
                        } elsif (file_name_exist("/dev/psaux")) {
                           $sectionLine =~ s/$tmpdev/\/dev\/psaux/;
                        }
                     }
                  }
                }

                ***REMOVED*** Solaris guests should use the PS/2 device /dev/kdmouse
                if (vmware_product() eq 'tools-for-solaris') {
                  if (($sectionLine =~ /^\s*Option\s+\"Device\"\s+\"(.+)\"/i) ||
                      ($sectionLine =~ /^\s*Device\s+\"(.+)\"/i)) {
                    my $tmpdev = $1;
                    $sectionLine =~ s/$tmpdev/\/dev\/kdmouse/;
                  }
                }

                ***REMOVED*** Normalize the identifier name
                if ($sectionLine =~ /^\s*Identifier\s+\"/) {
                  $sectionLine = "$&VMwareMouse[1]\"\n";
                }

                ***REMOVED*** In the mouse section, if we end the section and we haven't
                ***REMOVED*** yet seen a Device line, add it, because vmmouse will not
                ***REMOVED*** work without one. Not sure what to do if there is no mouse
                ***REMOVED*** at all, but this is better than nothing for now.
                ***REMOVED***
                ***REMOVED*** Ubuntu 8.04's mouse config section by default does not
                ***REMOVED*** specify a device (the driver probes for one and finds it.)
                ***REMOVED***
                ***REMOVED*** To mitigate the risk of affecting behavior on other guests,
                ***REMOVED*** enable this behavior only for tools-for-linux. It hasn't
                ***REMOVED*** ever been a problem on other guests anyway AFAICT.

                if (vmware_product() eq 'tools-for-linux' &&
                    $sectionLine =~ /^\s*EndSection/i &&
                    $seenDeviceSection == 0) {
                  if (file_name_exist("/dev/input/mice")) {
                     print NEWXF86CONFIG "   Option \"Device\" \"/dev/input/mice\"\n";
                  ***REMOVED*** 2.4 case: /dev/psaux
                  } elsif (file_name_exist("/dev/psaux")) {
                     print NEWXF86CONFIG "   Option \"Device\" \"/dev/psaux\"\n";
                  }
                }

                ***REMOVED*** Insert any of the mouse options not already accounted for
                ***REMOVED*** before the end of the section
                if (vmware_product() eq 'tools-for-linux' &&
                  $sectionLine =~ /^\s*EndSection/i) {
                  foreach my $option (keys %mouseOption) {
                    if ($mouseOption{$option} eq '') {
                      next;
                    }
                    print NEWXF86CONFIG "\tOption\t\t" . $option . "\t"
                                        .  $mouseOption{$option} . "\n";
                  }
                }

                print NEWXF86CONFIG $sectionLine;
              }
            } else {
              ***REMOVED*** First check if it's keyboard and we can rename its identifier.
              my $isKeyboardSection = 0;
              foreach $sectionLine (@currentSection) {
                ***REMOVED*** SLES9-SP4 uses "Keyboard" instead "keyboard" as Driver name.
                ***REMOVED*** 'k' should be case-insensitive.
                if ($sectionLine =~ /^\s*Driver\s+\"((?i)keyboard|kbd)\"/) {
                  $isKeyboardSection = 1;
                }
              }

              ***REMOVED*** In inputdevice section, if it is not mouse or keyboard, just copy
              ***REMOVED*** to new file directly. Otherwise, rename the keyboard identifier
              foreach $sectionLine (@currentSection) {
                if ($isKeyboardSection && $sectionLine =~ /^\s*Identifier\s+\"/) {
		   $gotKeyboardSection = 1;
                   print NEWXF86CONFIG "$&VMwareKeyboard[0]\"\n";
                } else {
                   print NEWXF86CONFIG $sectionLine;
                }
              }
            }
          } elsif ($sectionName eq 'device') {
            ***REMOVED*** Regenerate whole device section, and only one device section
            if ($inDevice == 0) {
              print NEWXF86CONFIG "Section \"Device\"\n";
              print NEWXF86CONFIG "    Identifier  \"VMware SVGA\"\n";
              if ($xversion >= 4) {
                ***REMOVED*** For config with newer format.
                print NEWXF86CONFIG "    Driver      \"vmware\"\n";
                if ($writeBusIDLine) {
                  print NEWXF86CONFIG "    BusID       \"PCI:0:15:0\"\n";
                }
              } else {
                ***REMOVED*** For config with old format.
                print NEWXF86CONFIG "    Chipset      \"generic\"\n";
              }
              print NEWXF86CONFIG "EndSection\n";
              $inDevice = 1;
            }
          } elsif ($sectionName eq 'screen') {
            ***REMOVED*** Regenerate whole screen section. This is done below.
	    ***REMOVED*** Only the identifier will stay the same. Everything else
	    ***REMOVED*** is regenreated.
            foreach $sectionLine (@currentSection) {
              if ($sectionLine =~ /^\s*Identifier\s+\"(.+)\"/i) {
		$xorgScreenIdentifier = "$1";
                last;
              }
            }
          } elsif ($sectionName eq 'monitor') {
            ***REMOVED*** Regenerate whole monitor section, and only one monitor section
            if ($inMonitor == 0) {
              $inMonitor = 1;
              $needMonitor = 1;
            }
          } elsif ($sectionName eq 'serverlayout') {
	    $gotServerLayout = 1;
            ***REMOVED*** Copy other sections directly to new file.
            foreach $sectionLine (@currentSection) {
              if ($sectionLine =~ 'EndSection') {
                ***REMOVED*** See matching 'XWorkAround' InputDevice section below.
                ***REMOVED***
                ***REMOVED*** X 7.2(.X) thinks no default mouse is loaded even when
                ***REMOVED*** vmmouse has already loaded.  So provide a workaround void
                ***REMOVED*** driver InputDevice section in xorg.conf to fool X.
                ***REMOVED***
                ***REMOVED*** Bug 156988 has all the cory details.
                if (($major == 7 && ($minor == 2 || ($minor == 1 && ($sub == 99 || distribution_info() eq 'redhat')))) || ($major == 1 && $minor == 3)) {
                  print NEWXF86CONFIG "	InputDevice	\"XWorkAround\"\n";
                }

                ***REMOVED*** Since we can't know for sure that all InputDevice sections have
                ***REMOVED*** been read before getting here, we have to just force these to
                ***REMOVED*** standard names.
                print NEWXF86CONFIG "	InputDevice	\"VMwareKeyboard[0]\"	\"CoreKeyboard\"\n";
                print NEWXF86CONFIG "	InputDevice \"VMwareMouse[1]\"	\"CorePointer\"\n";
              }

              if (!($sectionLine =~ /^\s*InputDevice\s+/) &&
                  !($sectionLine =~ /^\s*Pointer\s+/)) {
                 print NEWXF86CONFIG $sectionLine;
              }
            }
          } elsif ($sectionName eq 'serverflags' && $disableHotPlug eq
                   'yes') {
            foreach $sectionLine (@currentSection) {
               ***REMOVED*** The option NoAutoAddDevices needs to be added.
               if ($sectionLine =~ 'EndSection' && $gotServerFlagsSection == 0) {
                  print NEWXF86CONFIG "    Option  \"NoAutoAddDevices\"\n";
                  print NEWXF86CONFIG "EndSection\n";
                  $gotServerFlagsSection = 1;
               }
               elsif ($sectionLine =~
                      /^\s*Option\s+\"AutoAddDevices\"\s+\"(.+)\"/i &&
                        $gotServerFlagsSection == 0) {
                  ***REMOVED*** The user specified AutoAddDevice something.
                  ***REMOVED*** Using input hotplug isn't recommended inside a VM anyways.
                  ***REMOVED*** We override his choice
                  print NEWXF86CONFIG "    Option  \"NoAutoAddDevices\"\n";
                  $gotServerFlagsSection = 1;
               }
               else {
                  print NEWXF86CONFIG $sectionLine;
                  ***REMOVED*** If the option was already there.
                  if ($sectionLine =~ /^\s*Option\s+\"NoAutoAddDevices\"/i) {
                     $gotServerFlagsSection = 1;
                  }
               }
            }
          } else {
            ***REMOVED*** Copy other sections directly to new file.
            foreach $sectionLine (@currentSection) {
              print NEWXF86CONFIG $sectionLine;
            }
          }
          ***REMOVED*** Reset for next section.
          $inSection = 0;
          @currentSection = ();
        } else {
          push @currentSection, $line;
        }
      } else {
        ***REMOVED*** Copy other lines outside sections directly to new file.
        print NEWXF86CONFIG $line;
      }
    }
  }

  ***REMOVED*** First bring up the new screen section, preserving the identifer.
  ***REMOVED*** If one does not exist, make one.

  if ("$xorgScreenIdentifier" eq '') {
    $xorgScreenIdentifier = 'VMware Screen';
  }

  if ($xversion >= 4) {
    ***REMOVED*** For config with newer format.
    print NEWXF86CONFIG "Section \"Screen\"\n";
    print NEWXF86CONFIG "    Identifier     \"$xorgScreenIdentifier\"\n";
    print NEWXF86CONFIG <<EOF;
    Device      "VMware SVGA"
    Monitor     "vmware"
    ***REMOVED*** Don't specify DefaultColorDepth unless you know what you're
    ***REMOVED*** doing. It will override the driver's preferences which can
    ***REMOVED*** cause the X server not to run if the host doesn't support the
    ***REMOVED*** depth.
    Subsection "Display"
        ***REMOVED*** VGA mode: better left untouched
        Depth       4
        Modes       "640x480"
        ViewPort    0 0
    EndSubsection
    Subsection "Display"
        Depth       8
        Modes       $screen_mode
        ViewPort    0 0
    EndSubsection
    Subsection "Display"
        Depth       15
        Modes       $screen_mode
        ViewPort    0 0
    EndSubsection
    Subsection "Display"
        Depth       16
        Modes       $screen_mode
        ViewPort    0 0
    EndSubsection
    Subsection "Display"
        Depth       24
        Modes       $screen_mode
        ViewPort    0 0
    EndSubsection
EndSection
EOF
    $needMonitor = 1;
  } else {
    ***REMOVED*** For config with old format.
    print NEWXF86CONFIG <<EOF;
    Driver "accel"
    Device "VMware SVGA"
    Monitor "vmware"
    Subsection "Display"
	Modes $screen_mode
***REMOVED***	Modes "1600x1200" "1280x1024" "1152x864" "1024x768" "800x600" "640x480"
***REMOVED***	Modes "640x480"
***REMOVED***	Modes "800x600"
***REMOVED***	Modes "1024x768"
***REMOVED***	Modes "1152x864"
***REMOVED***	Modes "1152x900"
***REMOVED***	Modes "1280x1024"
***REMOVED***	Modes "1376x1032"
***REMOVED***	Modes "1600x1200"
***REMOVED***	Modes "2364x1773"
        ViewPort 0 0
    EndSubsection
EndSection
EOF
  }

  if ($gotMouseSection == 0) {
    print NEWXF86CONFIG <<EOF;
Section "InputDevice"
    Driver "vmmouse"
    Identifier "VMwareMouse[1]"
    Option "Buttons" "5"
    Option "Device" "/dev/input/mice"
    Option "Protocol" "IMPS/2"
    Option "ZAxisMapping" "4 5"
    Option "Emulate3Buttons" "true"
EndSection
EOF
    $gotMouseSection = 1;
  }

  if ($gotKeyboardSection == 0) {
    print NEWXF86CONFIG <<EOF;
Section "InputDevice"
    Identifier  "VMwareKeyboard[0]"
    Driver      "keyboard"
    Option "AutoRepeat" "500 30"
    Option "XkbRules"   "xfree86"
    Option "XkbModel"   "pc104"
    Option "XkbLayout"  "us"
    Option "XkbCompat"  ""
EndSection
EOF
    $gotKeyboardSection = 1;
  }

  if ($needMonitor == 1) {
    print NEWXF86CONFIG <<EOF;
Section "Monitor"
    Identifier      "vmware"
    VendorName      "VMware, Inc"
    HorizSync       1-10000
    VertRefresh     1-10000
EndSection
EOF
    $needMonitor = 0;
  }
  ***REMOVED*** See matching XWorkAround layout entry above.
  ***REMOVED***
  if (($major == 7 && ($minor == 2 || ($minor == 1 && ($sub == 99 || distribution_info() eq 'redhat')))) || ($major == 1 && $minor == 3)) {
    print NEWXF86CONFIG <<EOF;

Section "InputDevice"
	Identifier  "XWorkAround"
	Driver      "void"
EndSection

EOF
  }
  ***REMOVED*** See bug 291453
  ***REMOVED***
  if ($gotServerFlagsSection == 0 && $disableHotPlug eq 'yes') {
    print NEWXF86CONFIG <<EOF;
Section "ServerFlags"
    Option "NoAutoAddDevices"
EndSection
EOF
    $gotServerFlagsSection = 1;
  }

  ***REMOVED***
  ***REMOVED*** So some distros forget to create the ServerLayout section of the
  ***REMOVED*** Xorg.conf file (Debian 5.1 is a great example).  If they don't have
  ***REMOVED*** it, it means we have to generate it for them...
  ***REMOVED***
  if ($gotServerLayout == 0) {
    ***REMOVED*** Check to ensure the screen identifier was found.  Otherwise we
    ***REMOVED*** have to bail out.
    if ($xorgScreenIdentifier eq '') {
      error("No Identifier for the screen section in xorg.conf found\n");
    }

    print NEWXF86CONFIG <<EOF;
Section "ServerLayout"
    Identifier "VMware ServerLayout"
EOF

    print NEWXF86CONFIG "    Screen      \"$xorgScreenIdentifier\"\n";

    print NEWXF86CONFIG <<EOF;
    InputDevice "VMwareMouse[1]" "CorePointer"
    InputDevice "VMwareKeyboard[0]" "CoreKeyboard"
EndSection
EOF
    $gotServerLayout = 1;
  }

  close (EXISTINGXF86CONFIG);
  close (NEWXF86CONFIG);
}

***REMOVED*** Return next free X display number, or undef on error.
sub find_free_X_display {
   for (0..99) {
      if ( ! -e "/tmp/.X${_}-lock" ) {
         return $_;
      }
   }
   return undef;
}

sub try_X_conf {
  my $xConfigFile = shift;
  my $xLogFile = shift;
  my $childPid;
  my $childStatus;
  my $vtNext;

  unless(defined(&VT_OPENQRY)) {   ***REMOVED*** find available vt
    sub VT_OPENQRY () { 0x5600; }
  }

  my $TTY0;
  open($TTY0, '/dev/tty0') or die "open /dev/tty0 : $!\n";

  my $data = pack("I", 0);
  if (ioctl($TTY0, VT_OPENQRY, $data)) {
    $vtNext = unpack("I", $data);
  } else {
    error("VT_OPENQRY ioctl() error: $!\n");
  }

  close($TTY0);

  my $display_num = find_free_X_display();
  if (!defined($display_num)) {
   error("Could not find unused X display while testing X11 config.\n");
  }
  my @xargs = (xserver_bin() . '/X', ":$display_num", 'vt' . $vtNext,
                '-logfile', $xLogFile,
                '-once', '-logverbose', '3');
  ***REMOVED*** Handle cases where there is no config file.
  push (@xargs, ('-xf86config',  $xConfigFile)) if (-e $xConfigFile);

  ***REMOVED***
  ***REMOVED*** Set Autoflush.  Setting this avoids duplicate output and seems
  ***REMOVED*** to keep X from crashing/hanging when we are testing the new config
  ***REMOVED*** file.  See bug 347610 for more details.  -astiegmann
  ***REMOVED***
  $| = 1;

  if ($childPid = fork()) {
    ***REMOVED*** Run parent code, reading from child
    eval {
      $SIG{ALRM} = sub { die "alarm\n" };
      alarm 5;   ***REMOVED*** Seconds
      do {
        $childStatus = waitpid($childPid,0);
      } until $childStatus == -1;
      alarm 0;
    };

    if ($@) {
      ***REMOVED*** Propagate unexpected errors
      die unless $@ eq "alarm\n";
      ***REMOVED*** Timed out
      print wrap("\n" . 'X is running fine with the new config file.' .
                 "\n\n", 0);
      kill(15, $childPid);
      return 1;
    } else {
      print wrap ('Error: ' . "$childStatus" . '. X did not start.' .
            (-e "$xLogFile" ? "Details in $xLogFile" : '') . "\n", 0);
      return 0;
    }
  } else {
    error('Can not fork: ' . "$!\n") unless defined $childPid;
    ***REMOVED*** Child code
    exec @xargs;
  }

  $| = 0;
}

sub configure_X {
  my $xversion = '';
  my $xconfig_file = '';
  my $enableXImps2 = '';
  my $disableHotPlug = 'no';
  my $xversionAll = '';
  my $xconfig_backup = '';
  my $createNewXConf = 0;
  my $changeXConf = 1;
  my $addXconfToDb = 0;
  my $major;
  my $minor;
  my $sub;

  if (xserver_bin() eq '') {
     print wrap ('No X install found.' . "\n\n", 0);
     return 'no';
  }

  if (vmware_product() eq 'tools-for-solaris' &&
      solaris_10_or_greater() eq 'yes' &&
      direct_command(shell_string($gHelper{'svcprop'}) . ' -p options/server '
                     . 'application/x11/x11-server') =~ /Xsun/) {
     if (get_answer("\n\n" . 'You are currently using the Solaris Xsun server.  '
                    . 'VMware Tools for Solaris only supports the Xorg server '
                    . '(which can be switched to by running kdmconfig(1M) as '
                    . 'root).  Would you like to configure the Xorg server now '
                    . 'so that you have the option of switching to it in the '
                    . 'future? (yes/no)', 'yesno', 'yes') eq 'no') {
        print wrap('Skipping X configuration.' . "\n\n", 0);
        return 'no';
     }
  }

  if (file_name_exist(xserver_xorg())) {
    if (is64BitElf(xserver_xorg())) {
      $gIs64BitX = 1;
      ***REMOVED*** 64-bit FreeBSD puts it's 64-bit X modules in lib not lib64
      if (vmware_product() ne 'tools-for-freebsd') {
	  $gXMouseDriverFile = "$cX64ModulesDir/input/vmmouse_drv.o";
	  $gXVideoDriverFile = "$cX64ModulesDir/drivers/vmware_drv.o";
      } elsif (vmware_product() eq 'tools-for-solaris') {
          $gXMouseDriverFile = "/usr/X11/lib/modules/input/amd64/vmmouse_drv.so";
          $gXVideoDriverFile = "/usr/X11/lib/modules/drivers/amd64/vmware_drv.so";
      } else {
	  $gXMouseDriverFile = "$cXModulesDir/input/vmmouse_drv.o";
	  $gXVideoDriverFile = "$cXModulesDir/drivers/vmware_drv.o";
      }
    } else {
      ***REMOVED*** Solaris' Xorg installation is in /usr/X11 (not /usr/X11R6)
      if (vmware_product() eq 'tools-for-solaris') {
        $gXMouseDriverFile = "/usr/X11/lib/modules/input/vmmouse_drv.so";
        $gXVideoDriverFile = "/usr/X11/lib/modules/drivers/vmware_drv.so";
      } else {
        $gXMouseDriverFile = "$cXModulesDir/input/vmmouse_drv.o";
        $gXVideoDriverFile = "$cXModulesDir/drivers/vmware_drv.o";
      }
    }
    ($xversion, $xconfig_file, $xversionAll, $disableHotPlug) = xorg();
  } elsif (file_name_exist(xserver4())){
    if (is64BitElf(xserver4())) {
      $gIs64BitX = 1;
      $gXMouseDriverFile = "$cX64ModulesDir/input/vmmouse_drv.o";
      $gXVideoDriverFile = "$cX64ModulesDir/drivers/vmware_drv.o";
    } else {
      $gXMouseDriverFile = "$cXModulesDir/input/vmmouse_drv.o";
      $gXVideoDriverFile = "$cXModulesDir/drivers/vmware_drv.o";
    }
    ($xversion, $xconfig_file, $xversionAll) = xfree_4();
  } elsif (file_name_exist(xserver_bin() . '/xterm')) {
    ($xversion, $xconfig_file, $xversionAll) = xfree_3();
  } else {
     print wrap ('No X install found.' . "\n\n", 0);
     return 'no';
  }

  ($major, $minor, $sub) = split_X_version($xversionAll);

  ***REMOVED*** $gNoXDrivers set to 1 means VMware tools didn't include
  ***REMOVED*** appropriate drivers for the detected X version.
  if ($gNoXDrivers == 1) {
    print wrap('Skipping X configuration because X drivers are not included.' . "\n\n", 0);
    return 'no';
  }

  ***REMOVED*** 7.4 and 7.5 do not need a new xorg.conf file.
  ***REMOVED***
  ***REMOVED*** See bug 360333
  ***REMOVED*** If the OS is Fedora 9 or SLES11, then it needs to have
  ***REMOVED*** its xorg file modified.
  ***REMOVED***
  ***REMOVED*** XXX The polarity of this boolean is inverted. 0 is true.
  my $isFedoraRel = system(shell_string($gHelper{'grep'}) . ' ' .
			   "-q 'Fedora release 9' /etc/fedora-release " .
			   ">/dev/null 2>&1");

  ***REMOVED*** XXX The polarity of this boolean is inverted. 0 is true.
  my $isSuseRel11 = 1;
  if ($gSystem{'distribution'} eq 'suse') {
     my %prop = identify_suse_variant();
     if (((defined($prop{'variant'}) and $prop{'variant'} eq 'sle') or
         (defined($prop{'variant'}) and $prop{'variant'} eq 'opensuse')) and
          defined($prop{'version'}) and $prop{'version'} =~ /^11(\.[012])*$/) {
           $isSuseRel11 = 0;
     }
  }

  if ($major == 7 and $minor >= 4 and
      $isFedoraRel != 0 and
      $isSuseRel11 != 0 and
      vmware_product() ne 'tools-for-freebsd') {
         $changeXConf = 0;
         ***REMOVED*** If there is a .conf file there, back it up so that we properly use
         ***REMOVED*** the Xorg auto-conf logic.
         if (defined $xconfig_file and -e $xconfig_file) {
            backup_file_to_restore($xconfig_file, 'XCONFIG_FILE');
         }
  }

  if (not defined $xconfig_file) {
    if (get_answer("\n\n" . 'Could not locate X ' . $xversionAll
                   . ' configuration file. Do you want to create a new'
                   . ' one? (yes/no)', 'yesno', 'yes') eq 'no') {
      print wrap ("\n\n" . 'Could not locate X ' . $xversionAll .
                  ' configuration file. X configuration skipped.' . "\n\n", 0);
      return 'no';
    }
    $xconfig_file = "/etc/X11/XF86Config" . ($xversion >= 4 ? '-4' : '');
    $createNewXConf = 1;
  } elsif (not file_name_exist($xconfig_file) and $changeXConf) {
    if (get_answer("\n\n" . 'The configuration file ' . $xconfig_file
                   . ' can not be found. Do you want to create a new'
                   . ' one? (yes/no)', 'yesno', 'yes') eq 'no') {
      print wrap ("\n\n" . 'The configuration file ' . $xconfig_file .
                  ' can not be found. X configuration skipped.' . "\n\n", 0);
      return 'no';
    }
    $createNewXConf = 1;
  }

  if (-l $xconfig_file && !-e $xconfig_file) {
     print wrap ("\n\n" . 'The configuration file ' . $xconfig_file .
		 ' is a broken symlink. X configuration skipped.' . "\n\n", 0);
     return 'no';
  }

  $enableXImps2 = fix_mouse_file();

  $xconfig_backup = $xconfig_file . $cBackupExtension;
  ***REMOVED*** -e must be also tested because we don't want to unlink
  ***REMOVED*** a non-existed file
  if ((-e $xconfig_backup) && (!-s $xconfig_backup)) {
    unlink $xconfig_backup or
      die "Failed to cleanup empty $xconfig_backup file : $!\n";
  }

  ***REMOVED*** If the X config file does not exist, we need to add it to our database.  If
  ***REMOVED*** the X config file does exist, there are two cases: 1) we created it from
  ***REMOVED*** scratch during a previous Tools configuration, or 2) we are about to or
  ***REMOVED*** have already backed up the existing X config file.  For case 1, we don't
  ***REMOVED*** want to backup the file since we created it; for case 2, we need to backup
  ***REMOVED*** the file for restoring (if the backup already exists, backup_file_to_restore
  ***REMOVED*** will do the right thing).
  if ($createNewXConf == 1) {
    $addXconfToDb = 1;
  }
  elsif ($changeXConf == 1) {
    ***REMOVED*** Only backup the file if we didn't previously add it to the database
    if (not db_file_in($xconfig_file)) {
      backup_file_to_restore($xconfig_file, 'XCONFIG_FILE');
    }
  }

  my $tmp_dir = make_tmp_dir($cTmpDirPrefix);
  my $XF86tmp = $tmp_dir . '/XF86Config.' . $$;
  my $xLogFile = $tmp_dir . '/XF86ConfigLog.' . $$;

  if (-e $XF86tmp) {
    unlink $XF86tmp or
      die "Failed to cleanup old $XF86tmp file : $!\n";
  }
  if (-e $xLogFile) {
    unlink $xLogFile or
      die "Failed to cleanup old $xLogFile file : $!\n";
  }
  if (-e "$xLogFile.old" ) {
    unlink "$xLogFile.old" or
      die "Failed to cleanup old $xLogFile.old file : $!\n";
  }

  ***REMOVED*** Change the test file if we're using the original xorg.conf
  my $xconfigTestFile = $XF86tmp;
  if ($major == 7 && $minor >= 4 && file_name_exist($xconfig_file)) {
    $xconfigTestFile = $xconfig_file;
  }

  if ($changeXConf == 1) {
    if ($createNewXConf == 0) {
      ***REMOVED*** Before installation, if there is no backup one, $xconfig_file will
      ***REMOVED*** be renamed to $xconfig_backup. So first $xconfig_file should be
      ***REMOVED*** checked if existed.
      if (-e $xconfig_file) {
	fix_X_conf($XF86tmp, $xconfig_file,
		   $xversion, $enableXImps2, $xversionAll, $disableHotPlug);
      } else {
	fix_X_conf($XF86tmp, $xconfig_backup,
		   $xversion, $enableXImps2, $xversionAll, $disableHotPlug);
      }
    } else {
	***REMOVED*** If failed with existing $xconfig_file, try to generate a new x config
	***REMOVED*** file with template one. The template file is also modified with fix_X_conf
	***REMOVED*** to set right mouse protocol, driver, display, etc.
	fix_X_conf($XF86tmp, db_get_answer('LIBDIR') . '/configurator/XFree86-'
		   . ($xversion >= 4 ? '4' : $xversion) . '/XF86Config'
		   . ($xversion >= 4 ? '-4': ''),
		   $xversion, $enableXImps2, $xversionAll, $disableHotPlug);
    }
  }

  my $isUbuntuHardy = system(shell_string($gHelper{'grep'}) . ' ' .
                             "-q 'DISTRIB_CODENAME=hardy' /etc/lsb-release " .
                             ">/dev/null 2>&1");

  ***REMOVED*** try_X_conf has problem with old X window, please refer to bug 78985
  ***REMOVED*** Ubuntu 8.04 has a very corner case issue where if you change the resolution
  ***REMOVED*** of Xorg via this script after a fresh install of tools, the try_X_conf method
  ***REMOVED*** will cause gdm to restart.  So we have to sneak past this bug by checking if the
  ***REMOVED*** distry in question is Hardy and whether or not the .not_configured file exists.
  if (vmware_product() eq 'tools-for-linux' &&
      ($major > 4 || ($major == 4 && $minor >= 2)) &&
      not ($isUbuntuHardy == 0 && -e $gConfFlag) &&
      !try_X_conf($xconfigTestFile, $xLogFile)) {
    if (get_answer("\n\n" . 'The updated X config file does not work well.'
                   . ' See '. $xLogFile . ' for details. Do you want to create'
                   . ' a new one from template? Warning: if you choose to'
                   . ' create a new one, all old settings will be gone! (yes/no)',
                   'yesno', 'yes') eq 'no') {
      print wrap ('X configuration failed! The updated X config file does '
		  . 'not work well. File saved as ' . $XF86tmp . '. See '
		  . $xLogFile . ' for details.' . "\n\n");
      ***REMOVED*** Here temp files are not removed because user may want to check the
      ***REMOVED*** files to see what is wrong.
      return 'no';
    }
    unlink $XF86tmp;
    unlink $xLogFile;
    ***REMOVED*** If test failed with $XF86tmp, try to test a new $XF86tmp from template one.
    fix_X_conf($XF86tmp, db_get_answer('LIBDIR') . '/configurator/XFree86-'
               . ($xversion >= 4 ? '4' : $xversion) . '/XF86Config'
               . ($xversion >= 4 ? '-4': ''),
               $xversion, $enableXImps2, $xversionAll, $disableHotPlug);
    if (!try_X_conf($XF86tmp, $xLogFile)) {
      ***REMOVED*** Here temp files are not removed because user may want to check the
      ***REMOVED*** files to see what is wrong.
      return 'no';
    }
  }
  if ($changeXConf == 1) {
    if (system(shell_string($gHelper{'cp'}) . ' -p ' . $XF86tmp . ' ' .
	       $xconfig_file)) {
      print wrap ('Unable to copy the updated X config file to '
		  . $xconfig_file . "\n\n");
      ***REMOVED*** Here temp files are not removed because user may manually copy files
      ***REMOVED*** to right place.
      return 'no';
    }
    if ($addXconfToDb == 1) {
      db_add_file($xconfig_file, 0x0);
    }
  }
  unlink $XF86tmp;
  unlink $xLogFile;
  remove_tmp_dir($tmp_dir);
  return 'yes';
}


***REMOVED*** Set to CUPS in the guest to use thinprint
sub configure_thinprint {
  my $lpadmin;
  my $cupsenable;
  my $cupsaccept;
  my $configText;
  my $printerName = 'VMware_Virtual_Printer';
  my $printerURI = 'tpvmlp://VMware';
  my $cupsDir = '/usr/' . (is64BitUserLand() ? 'lib64' : 'lib')  .
                '/cups/backend';
  my $cupsConfDir = '/etc/cups';
  my $cupsPrinters = "$cupsConfDir/printers.conf";
  my $cupsConf = "$cupsConfDir/cupsd.conf";
  my @backends =  ("$cupsDir/tpvmlp", "$cupsDir/tpvmgp");
  my $addDummyPrinter = 'false';

  ***REMOVED*** To continue, CUPS must be where we expect it on the guest.
  if (!file_name_exist($cupsDir) || !file_name_exist($cupsConf)) {
    return 0;
  }

  if (!file_name_exist($cupsPrinters)) {
    system("touch $cupsPrinters");
    system("chmod --reference=$cupsConf $cupsPrinters");
    system("chown --reference=$cupsConf $cupsPrinters");
  }

  if (!file_name_exist($cupsPrinters)) {
    return 0;
  }

  $configText = "<Printer ${printerName}>\n" .
                 "   Info ${printerName}\n" .
                 "   DeviceURI ${printerURI}\n" .
                 "   State Idle\n" .
                 "   Accepting Yes\n" .
                 "</Printer>\n";

  install_symlink(db_get_answer('LIBDIR') . '/configurator/thinprint.ppd',
                  $cupsConfDir . "/ppd/" . $printerName . ".ppd");

  install_symlink(db_get_answer('LIBDIR') . '/bin/vmware-tpvmlp',
                  "/usr/bin/" ."tpvmlp");

  install_symlink(db_get_answer('LIBDIR') . '/bin/vmware-tpvmlpd',
                  "/usr/bin/" ."tpvmlpd");

  foreach(@backends) {
     install_hardlink(db_get_answer('LIBDIR') . '/bin/vmware-tpvmlp', $_);
     system("chgrp --reference=/dev/ttyS0 $_"); ***REMOVED*** match serial port

     ***REMOVED*** Ubuntu needs SETGID only, all others need SETUID
     my $isUbuntu = system(shell_string($gHelper{'grep'}) . ' ' .
                           "-q 'DISTRIB_ID=Ubuntu' /etc/lsb-release " .
                           ">/dev/null 2>&1");
     if ($isUbuntu == 0) {
        ***REMOVED*** add SETGID for Ubuntu
        safe_chmod(02755, $_);
     } else {
        ***REMOVED*** add SETUID for all others
        safe_chmod(04755, $_);
     }

     restorecon($_);
  }

  if (is_selinux_enabled() &&
      file_name_exist("/etc/redhat-release")) {
    ***REMOVED*** first make sure all the commands are present
    if (internal_which("checkmodule") eq '' ||
        internal_which("semodule_package") eq '' ||
        internal_which("semodule") eq '') {
       print wrap("One or more selinux tools missing: ".
                  "can't configure cups backend.\n\n", 0);
    } else {
      ***REMOVED*** make a temp dir
      my $tmpDir = make_tmp_dir($cTmpDirPrefix);

      ***REMOVED*** the files we will use
      my $tmpFile = "$tmpDir/tpvmlpcupsd-$$.te";
      my $modFile = "$tmpDir/tpvmlpcupsd-$$.mod";
      my $ppFile = "$tmpDir/tpvmlpcupsd-$$.pp";

      ***REMOVED*** create tmp file
      if (open (TEFILE, ">", $tmpFile)) {
        print TEFILE <<EOF;
module tpvmlpcupsd 1.0;

require {
   type var_lock_t;
   type cupsd_t;
   class dir { getattr write read remove_name add_name search };
   class file { getattr write read create unlink lock };
}

allow cupsd_t var_lock_t:dir { getattr write read remove_name add_name search };
allow cupsd_t var_lock_t:file { getattr write read create unlink lock };
EOF
        close TEFILE;

        ***REMOVED*** do the magic
        my $s = system("checkmodule -m -M -o $modFile $tmpFile >/dev/null 2>&1");
        $s or $s = system("semodule_package -o $ppFile -m $modFile >/dev/null 2>&1");
        $s or $s = system("semodule -i $ppFile >/dev/null 2>&1");
        if ($s) {
          print wrap("Configuration of cups backend for selinux failed.\n\n");
        }
      }

      ***REMOVED*** remove temp dir and it's contents
      remove_tmp_dir($tmpDir);
    }
  } ***REMOVED*** end of the selinux stuff

  install_symlink($gRegistryDir . '/tpvmlp.conf', '/etc/tpvmlp.conf');

  if ($addDummyPrinter eq 'true') {
     block_remove($cupsPrinters, $cupsPrinters . '.bak',
                  $cMarkerBegin, $cMarkerEnd);
     block_append($cupsPrinters . '.bak' , $cMarkerBegin, $configText, $cMarkerEnd);
     rename($cupsPrinters . '.bak', $cupsPrinters);
  }
  db_add_answer('THINPRINT_CONFED', 'yes');
}


***REMOVED***
***REMOVED*** configure_autostart_xdg --
***REMOVED***
***REMOVED***    Tests for the existence of well-known paths used to support the XDG
***REMOVED***    autostart mechanism.  For each path encountered, a vmware-user.desktop
***REMOVED***    symlink is installed which will cause XDG autostart aware session managers
***REMOVED***    to launch vmware-user as part of the user's session.
***REMOVED***
***REMOVED*** Results:
***REMOVED***    Returns the following triple:
***REMOVED***       ((int)  number of symlinks installed,
***REMOVED***        (bool) 1 if a GNOME-specific directory was encountered,
***REMOVED***        (bool) 1 if a KDE-specific directory was encountered)
***REMOVED***

sub configure_autostart_xdg {
   ***REMOVED*** /path/to/vmware-user.desktop.
   my $dotDesktop = "$gRegistryDir/vmware-user.desktop";
   my $numSymlinks = 0;

   my $foundGnome = 0;
   my $foundKde = 0;

   my %autodirs = (
      "/etc/xdg/autostart" => undef,
      "/usr/share/autostart" => undef,
      "/usr/share/gnome/autostart" => undef,
      ***REMOVED*** FreeBSD, compiled from source, and maybe Gentoo?
      "/usr/local/share/autostart" => undef,
      "/usr/local/share/gnome/autostart" => undef,
      "/usr/local/kde4/share/autostart" => undef,
      ***REMOVED*** SuSE-style.
      "/opt/gnome/share/autostart" => undef,
      "/opt/kde/share/autostart" => undef,
      "/opt/kde3/share/autostart" => undef,
      "/opt/kde4/share/autostart" => undef,
   );

   ***REMOVED*** If KDE is available, use kde{,4}-config to search for its install path,
   ***REMOVED*** and add that to the list of autostart directories.
   ***REMOVED***
   ***REMOVED*** Since PATH is overridden in main(), test for other common locations
   ***REMOVED*** of kde-config (using the augmented argument to internal_which).
   ***REMOVED***
   ***REMOVED*** NB: FreeBSD packages KDE 4 under /usr/local/kde4, and /usr/local/kde4/bin
   ***REMOVED*** typically isn't automatically added to users' search paths, so (for now)
   ***REMOVED*** we'll need to search there directly.
   my @kdeConfigs = ("kde-config", "kde4-config");
   foreach (@kdeConfigs) {
      my $kdeConfig = internal_which($_, 1, ["/usr/local/kde4/bin"]);
      if ($kdeConfig ne '' && -x $kdeConfig) {
        ***REMOVED***
        ***REMOVED*** Okay, we have a valid kde-config.  Query it for its installation
        ***REMOVED*** prefix, then if an autostart path exists, add it to autodirs.
        ***REMOVED***
        my $kdePrefix = direct_command(shell_string($kdeConfig) . " --prefix");
        chomp($kdePrefix);
        my $kdeAutostart = "$kdePrefix/share/autostart";
        if (-d $kdeAutostart) {
           $autodirs{$kdeAutostart} = undef;
           $foundKde = 1;
        }
      }
   };

   foreach (keys(%autodirs)) {
      if (-d $_) {
         install_symlink($dotDesktop, "$_/vmware-user.desktop");
         ***REMOVED*** At time of publishing, all versions of gnome-session supporting
         ***REMOVED*** XDG autostart do so via a GNOME-specific autostart directory.
         $foundGnome = 1 if $_ =~ /gnome/;
         $foundKde = 1 if $_ =~ /kde/;
         ++$numSymlinks;
      }
   }

   return ($numSymlinks, $foundGnome, $foundKde);
}


***REMOVED***
***REMOVED*** configure_autostart_legacy_xdm --
***REMOVED***
***REMOVED***    Jump through hoops to launch vmware-user as part of xdm's Xsession script.
***REMOVED***
***REMOVED*** Results:
***REMOVED***    If applicable, xdm will now launch vmware-user before executing its usual
***REMOVED***    Xsession script.
***REMOVED***
***REMOVED***    Returns the number of xdm-config files modified.
***REMOVED***

sub configure_autostart_legacy_xdm {
   my $x11Base = internal_dirname(xserver_bin());
   db_add_answer('X11DIR', $x11Base);

   my $chompedMarkerBegin = $cMarkerBegin;
   chomp($chompedMarkerBegin);

   my $modCount = 0;

   ***REMOVED*** X.Org's XDM
   ***REMOVED***  - Determine X11BASE.
   ***REMOVED***  - Touch xdm-config to source our Xresources.
   my $xResources = "$gRegistryDir/vmware-user.Xresources";
   my $xSessionXDM = "$gRegistryDir/xsession-xdm.sh";
   my @xdmcfgs = ("$x11Base/lib/X11/xdm/xdm-config", "/etc/X11/xdm/xdm-config");
   foreach my $xdmcfg (@xdmcfgs) {
      if (file_name_exist($xdmcfg)) {
         if (block_match($xdmcfg, "!$chompedMarkerBegin")) {
            block_restore($xdmcfg, $cMarkerBegin, $cMarkerEnd);
         }
         block_append($xdmcfg, "!$cMarkerBegin", "***REMOVED***include \"$xResources\"\n",
                      "!$cMarkerEnd");
         ++$modCount;
      }
   }

   return $modCount;
}


***REMOVED***
***REMOVED*** configure_autostart_legacy_gdm --
***REMOVED***
***REMOVED***    Attempt to launch vmware-user via gdm.
***REMOVED***
***REMOVED*** Results:
***REMOVED***    If applicable, we place a script in /etc/X11/xinit/xinitrc.d, causing gdm
***REMOVED***    to launch vmware-user before its usual Xsession script.
***REMOVED***
***REMOVED***    Returns 1 if the symlink was installed, and 0 otherwise.
***REMOVED***

sub configure_autostart_legacy_gdm {
   ***REMOVED*** GNOME's GDM (legacy)
   ***REMOVED***  - Symlink xsession-gdm to /etc/X11/xinit/xinitrc.d/vmware-user.sh.
   ***REMOVED***    (This is a hardcoded path in gdm sources.)
   my $xSessionGDM = "$gRegistryDir/xsession-gdm.sh";
   my $xinitrcd = "/etc/X11/xinit/xinitrc.d";
   if (-d $xinitrcd) {
      install_symlink($xSessionGDM, "$xinitrcd/vmware-xsession-gdm.sh");
      return 1;
   }

   return 0;
}


***REMOVED***
***REMOVED*** configure_autostart_legacy_suse --
***REMOVED***
***REMOVED***    Hook into /etc/X11/xinit/xinitrc.common to launch vmware-user.
***REMOVED***
***REMOVED***     - All packaged display managers point users to a consolidated
***REMOVED***       /etc/X11/xdm/Xsession script.  (Even in the GDM case, SUSE's scheme
***REMOVED***       overrides what we'd use above.)
***REMOVED***     - This Xsession script sources /etc/X11/xinit/xinitrc.common for common
***REMOVED***       autostart tasks.  Seems like a perfect fit for us.
***REMOVED***
***REMOVED*** Results:
***REMOVED***    If applicable, we'll insert a few lines into xinitrc.common, and all
***REMOVED***    display managers on SuSE 10 will launch vmware-user during X11 session
***REMOVED***    startup.
***REMOVED***
***REMOVED***    Returns 1 if xinitrc.common was modified, and 0 otherwise.
***REMOVED***

sub configure_autostart_legacy_suse {
   my $startCommand = shift;    ***REMOVED*** Bourne-shell compatible string used to launch
                                ***REMOVED*** vmware-user.

   my $xinitrcCommon = '/etc/X11/xinit/xinitrc.common';

   my $chompedMarkerBegin = $cMarkerBegin;
   chomp($chompedMarkerBegin);


   if (file_name_exist($xinitrcCommon)) {
      if (block_match($xinitrcCommon, $chompedMarkerBegin)) {
         block_restore($xinitrcCommon, $cMarkerBegin, $cMarkerEnd);
      }
      block_append($xinitrcCommon, $cMarkerBegin, $startCommand . "\n",
                   $cMarkerEnd);
      return 1;
   }

   return 0;
}


***REMOVED***
***REMOVED*** configure_autostart_legacy_xsessiond --
***REMOVED***
***REMOVED***    Hook into Xsession.d/*.sh to launch vmware-user.
***REMOVED***
***REMOVED*** Results:
***REMOVED***    If applicable, we'll create a vmware-user launch script in the system's
***REMOVED***    Xsession.d directory, and vmware-user will launch during X11 session
***REMOVED***    startup.
***REMOVED***
***REMOVED***    Returns 1 if we dropped in a script, and 0 otherwise.
***REMOVED***

sub configure_autostart_legacy_xsessiond($$) {
   my $startCommand = shift;    ***REMOVED*** Bourne-shell compatible string used to launch
                                ***REMOVED*** vmware-user.
   my $platform = shift;        ***REMOVED*** Must be either "Debian" or "Solaris"
                                ***REMOVED*** (case-insensitive).

   my $chompedMarkerBegin = $cMarkerBegin;
   chomp($chompedMarkerBegin);

   my $xSessionD;
   my $xSessionDst;
   my $prettyOSName;

   for ($platform) {
      /debian/i && do {
         $xSessionD = '/etc/X11/Xsession.d';
         $xSessionDst = "$xSessionD/99-vmware_vmware-user";
         $prettyOSName = "Debian and Ubuntu";
         last;
      };
      /solaris/i && do {
         $xSessionD = '/usr/dt/config/Xsession.d';
         $xSessionDst = "$xSessionD/9999.autostart-vmware-user.sh";
         $prettyOSName = "Solaris";
         last;
      };
      die sprintf("%s: platform '%s' unknown.\n",
                  "configure_autostart_legacy_xsessiond", $platform);
   }

   my $tmpBlock = <<__EOF;
***REMOVED***
***REMOVED*** This script is intended only as a last resort in order to launch the VMware
***REMOVED*** User Agent (vmware-user) in legacy $prettyOSName VMs whose shipped X11
***REMOVED*** session managers may not support XDG/KDE-style autostart via .desktop files.
***REMOVED***
__EOF

   if (-d $xSessionD) {
      if (block_match($xSessionDst, $chompedMarkerBegin)) {
         block_restore($xSessionDst, $cMarkerBegin, $cMarkerEnd);
      }
      block_append($xSessionDst, $cMarkerBegin,
                   $tmpBlock . "\n" . $startCommand . "\n",
                   $cMarkerEnd);

      safe_chmod(0755, $xSessionDst);
      db_add_file($xSessionDst, 0);
      return 1;
   }

   return 0;
}


***REMOVED***
***REMOVED*** configure_autostart_legacy --
***REMOVED***
***REMOVED***    Use unconventional hooks to launch vmware-user at X session startup.
***REMOVED***    This is intended only for guests which do not support XDG-style
***REMOVED***    autostart.
***REMOVED***
***REMOVED***    This routine will make use of hooks provided by the following:
***REMOVED***      - OpenSuSE 10's xinitrc.common
***REMOVED***      - Debian, Ubuntu via Xsession.d
***REMOVED***      - xdm (all known versions)
***REMOVED***      - gdm (2.2.3 and above)
***REMOVED***
***REMOVED***    The vendor specific methods are preferred, so if either of those succeeds,
***REMOVED***    we'll avoid calling into the xdm & gdm routines.
***REMOVED***
***REMOVED*** Results:
***REMOVED***    If applicable, we may insert vmware-user autostart hooks.
***REMOVED***

sub configure_autostart_legacy {
   ***REMOVED***
   ***REMOVED*** This is the vmware-user launch command for pre-XDG autostart guests.  The
   ***REMOVED*** delay is intended to prefer XDG-style launch for guests where we may
   ***REMOVED*** accidentally use both pre- and post-XDG autostart hooks.
   ***REMOVED***
   my ($sleepingAgentDelay) = 15;       ***REMOVED*** Give session managers a 15s head start.
   my ($sleepingAgentCommand) =
      sprintf("{ sleep %d && %s/%s &>/dev/null ; } &",
              $sleepingAgentDelay, db_get_answer('BINDIR'), 'vmware-user');

   if ((configure_autostart_legacy_suse($sleepingAgentCommand) == 0) &&
       (configure_autostart_legacy_xsessiond($sleepingAgentCommand, "debian") == 0) &&
       (configure_autostart_legacy_xsessiond($sleepingAgentCommand, "solaris") == 0)) {
      configure_autostart_legacy_xdm();
      configure_autostart_legacy_gdm();
   }
}


***REMOVED***
***REMOVED*** configure_autostart --
***REMOVED***
***REMOVED***    Configures the system to launch vmware-user as part of users' graphical
***REMOVED***    sessions.
***REMOVED***
***REMOVED***    This routine is heuristically inclined.  We'll install XDG style .desktop
***REMOVED***    files if any paths exist, but we'll use legacy autostart hooks only if
***REMOVED***    we have reason to believe that the XDG solution didn't fully apply to
***REMOVED***    this guest.
***REMOVED***
***REMOVED***    E.g., GNOME was a little late to the .desktop autostart party.  So a
***REMOVED***    machine with both slightly older GNOME and KDE installed may have
***REMOVED***    an autostart directory present under $datadir/autostart, but it may
***REMOVED***    not be used by GNOME.  If this is the case (indicated by $foundGnomeStart
***REMOVED***    being false), then we opt to continue and use some of the legacy
***REMOVED***    install hooks.
***REMOVED***

sub configure_autostart {
   my @sessionsDirs;
   my $hasGnome = 0;
   my $hasKde = 0;

   my $numSymlinks;
   my $foundGnomeStart;
   my $foundKdeStart;

   my $existingDirs = 0;

   ***REMOVED***
   ***REMOVED*** We forgot to fully clean up after ourselves when uninstalling Tools.  As a
   ***REMOVED*** result, users who upgrade Tools may find vmware-user launched via a
   ***REMOVED*** "legacy" autostart mechanism outside the context of their desktop (GNOME,
   ***REMOVED*** KDE, Xfce, etc.) session.  (This breaks features like GHI.)  The unfortunate
   ***REMOVED*** workaround is to simply take that step here.
   ***REMOVED***
   ***REMOVED*** NB: This affects only users who installed Tools with beta versions of
   ***REMOVED*** Workstation and Fusion*, so we can likely pull this block out (while still
   ***REMOVED*** leaving the corresponding call in the uninstaller) in the next release.
   ***REMOVED***
   ***REMOVED*** * This refers to any version of Tools that included the decoupled
   ***REMOVED***   vmware-{user,guestd}.
   ***REMOVED***
   unconfigure_autostart_legacy($cMarkerBegin, $cMarkerEnd);

   @sessionsDirs = ('/usr/share/xsessions',
                    '/usr/local/share/xsessions',
                    '/usr/X11R6/share/xsessions');

   foreach (@sessionsDirs) {
      next unless -d $_;
      my @tmpArray;

      @tmpArray = glob("$_/gnome.desktop");
      $hasGnome = 1 if $***REMOVED***tmpArray != -1;

      @tmpArray = glob("$_/kde*.desktop");
      $hasKde = 1 if $***REMOVED***tmpArray != -1;

      ++$existingDirs;
   }

   if ($existingDirs == 0) {
      $hasGnome =
         defined internal_which('gnome', 1) ||
         defined internal_which('gnome-session', 1);
      $hasKde =
         defined internal_which('startkde', 1) ||
         defined internal_which('ksmserver', 1);
   }

   ($numSymlinks, $foundGnomeStart, $foundKdeStart) = configure_autostart_xdg();

   ***REMOVED*** Fall back to legacy autostart if
   ***REMOVED***    a.  no XDG symlinks were installed, or
   ***REMOVED***    b.  user employs older GNOME but we were unable to find a GNOME-
   ***REMOVED***        supported XDG path, or
   ***REMOVED***    c.  s/GNOME/KDE/g  (less likely)
   if (($numSymlinks == 0) ||
       ($hasGnome && !$foundGnomeStart) ||
       ($hasKde && !$foundKdeStart)) {
      configure_autostart_legacy();
   }
}


***REMOVED*** Get a network name from the user
sub get_network_name_answer {
  my $vHubNr = shift;
  my $default = shift;
  get_persistent_answer('Please specify a name for this network.',
                        'VNET_' . $vHubNr . '_NAME',
                        'netname', $default);
}

***REMOVED*** Configuration of bridged networking
sub configure_bridged_net {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $answer;

  if ($vHubNr < $gMinVmnet || $vHubNr > $gMaxVmnet) {
    print wrap('Number of virtual networks exceeded.  Not creating virtual '
               . 'network.' . "\n\n", 0);
    return;
  }

  ***REMOVED*** If this wasn't a bridged network before, wipe out the old configuration
  ***REMOVED*** info as it may confuse us later.
  if (!is_bridged_network($vHubNr)) {
    remove_net($vHubNr, $vHostIf);
  }

  print wrap('Configuring a bridged network for vmnet' . $vHubNr . '.'
             . "\n\n", 0);

  if (vmware_product() eq 'wgs') {
     get_network_name_answer($vHubNr, 'Bridged');
  }

  if (count_all_networks() == 0 && $***REMOVED***gAllEthIf == -1) {
    ***REMOVED*** No interface.  We provide a valid default so that everything works.
    make_bridged_net($vHubNr, $vHostIf, "eth0");
    return;
  }

  if ($***REMOVED***gAvailEthIf == 0) {
    ***REMOVED*** Only one interface.  Use it.  This gives no choice even when the editor
    ***REMOVED*** is being used.
    make_bridged_net($vHubNr, $vHostIf,  $gAvailEthIf[0]);
    return;
  }

  if ($***REMOVED***gAvailEthIf == -1) {
    ***REMOVED*** We have other interfaces, but they have all been allocated.
    if (get_answer('All your ethernet interfaces are already bridged.  Are '
                   . 'you sure you want to configure a bridged ethernet '
                   . 'interface for vmnet' . $vHubNr . '? (yes/no)',
                   'yesno', 'no') eq 'no') {
      print wrap('Not changing network settings for vmnet' . $vHubNr . '.'
                 . "\n\n", 0);
      return;
    }
    $answer = get_persistent_answer('Your computer has the following ethernet '
                                    . 'devices: ' . join(', ', @gAllEthIf)
                                    . '. Which one do you want to bridge to '
                                    . 'vmnet' . $vHubNr . '?',
                                    'VNET_' . $vHubNr . '_INTERFACE',
                                    'anyethif', 'eth0');
    make_bridged_net($vHubNr, $vHostIf, $answer);
    return;
  }

  my $queryString = 'Your computer has multiple ethernet network interfaces '
                    . 'available: ' . join(', ', @gAvailEthIf) . '. Which one '
                    . 'do you want to bridge to vmnet' . $vHubNr . '?';
  $answer = get_persistent_answer($queryString,
                                  'VNET_' . $vHubNr . '_INTERFACE',
                                  'availethif', 'eth0');
  make_bridged_net($vHubNr, $vHostIf, $answer);
}

***REMOVED*** Creates a bridged network.
sub make_bridged_net {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $ethIf = shift;

  ***REMOVED*** Need to make sure the NAME key is present so that netmap.conf is created properly.
  my $net_name = db_get_answer_if_exists('VNET_' . $vHubNr . '_NAME');
  if (not defined($net_name)) {
    db_add_answer('VNET_' . $vHubNr . '_NAME', 'Bridged-' . $vHubNr);
  }

  db_add_answer('VNET_' . $vHubNr . '_INTERFACE', $ethIf);
  db_remove_answer('VNET_' . $vHubNr . '_DHCP');
  configure_dev('/dev/' . $vHostIf, 119, $vHubNr, 1);

  ***REMOVED*** Reload the list of available ethernet adapters
  load_ethif_info();
}

***REMOVED*** Probe for an unused private subnet
***REMOVED*** Return value is (status, subnet, netmask).
***REMOVED***  status is 1 on success (subnet and netmask are set),
***REMOVED***  status is 0 on failure.
sub subnet_probe {
  my $vHubNr = shift;
  my $vHostIf = shift;
  ***REMOVED*** Ref to an array of used subnets
  my $usedSubnets = shift;
  my $i;
  my @subnets;
  my $tries;
  my $maxTries = 100;
  my $pings;
  my $maxPings = 10;
  ***REMOVED*** XXX We only consider class C subnets for the moment
  my $netmask = '255.255.255.0';
  my %used_subnets;

  ***REMOVED*** Generate the table of private class C subnets
  @subnets = ();
  for ($i = 0; $i < 255; $i++) {
    $subnets[2 * $i    ] = '192.168.' . $i . '.0';
    $subnets[2 * $i + 1] = '172.16.'  . $i . '.0';
  }

  ***REMOVED*** Generate a list of used subnets and clear out the ones that have already
  ***REMOVED*** been used
  foreach $i (@$usedSubnets) {
    $used_subnets{$i} = 1;
  }
  for ($i = 0; $i < $***REMOVED***subnets + 1; $i++) {
    if ($used_subnets{$subnets[$i]}) {
      $subnets[$i] = '';
    }
  }

  print wrap('Probing for an unused private subnet (this can take some '
             . 'time)...' . "\n\n", 0);
  $tries = 0;
  $pings = 0;
  srand(time);
  ***REMOVED*** Beware, 'last' doesn't seem to work in 'do'-'while' loops
  for (;;) {
    my $r;
    my $subnet;
    my $status;

    $tries++;

    $r = int(rand($***REMOVED***subnets + 1));
    if ($subnets[$r] eq '') {
      ***REMOVED*** Already tried
      if ($tries == $maxTries) {
        print STDERR wrap('We were unable to locate an unused Class C subnet '
                          . 'in the range of private network numbers.  For '
                          . 'each subnet that we tried we received a response '
                          . 'to our ICMP ping packets from a ' . $machine
                          . ' at the network address intended for assignment '
                          . 'to this machine.  Because no private subnet '
                          . 'appears to be unused you will need to explicitly '
                          . 'specify a network number by hand.' . "\n\n", 0);
        return (0, undef, undef);
      }
      next;
    }
    $subnet = $subnets[$r];
    $subnets[$r] = '';

    ***REMOVED*** Do a broadcast ping for <subnet>.255 .
    $status = system(shell_string(db_get_answer('BINDIR') . '/vmware-ping')
                     . ' -q ' . ' -b '
                     . shell_string(int_to_quaddot(quaddot_to_int($subnet)
                                                   + 255))) >> 8;

    if ($status == 1) {
      ***REMOVED*** Some OSes are configured to ignore broadcast ping,
      ***REMOVED*** so we ping <subnet>.1 .
      $status = system(shell_string(db_get_answer('BINDIR') . '/vmware-ping')
                       . ' -q '
                       . shell_string(int_to_quaddot(quaddot_to_int($subnet)
                                                   + 1))) >> 8;
      if ($status == 1) {
        print wrap('The subnet ' . $subnet . '/' . $netmask . ' appears to be '
                   . 'unused.' . "\n\n", 0);
        return (1, $subnet, $netmask);
      }
    }

    if ($status == 3) {
      print STDERR wrap('We were unable to locate an unused Class C subnet in '
                        . 'the range of private network numbers.  You will '
                        . 'need to explicitly specify a network number by '
                        . 'hand.' . "\n\n", 0);
      return (0, undef, undef);
    }

    if ($status == 2) {
      print STDERR wrap('Either your ' . $machine . ' is not connected to an '
                        . 'IP network, or its network configuration does not '
                        . 'specify a default IP route.  Consequently, the '
                        . 'subnet ' . $subnet . '/' . $netmask . ' appears to '
                        . 'be unused.' . "\n\n", 0);
      return (1, $subnet, $netmask);
    }

    $pings++;
    if (($pings == $maxPings) || ($tries == $maxTries)) {
      print STDERR wrap('We were unable to locate an unused Class C subnet in '
                        . 'the range of private network numbers.  For each '
                        . 'subnet that we tried we received a response to our '
                        . 'ICMP ping packets from a ' . $machine . ' at the '
                        . 'network address intended for assignment to this '
                        . 'machine.  Because no private subnet appears to be '
                        . 'unused you will need to explicitly specify a '
                        . 'network number by hand.' . "\n\n", 0);
      return (0, undef, undef);
    }
  }
}

***REMOVED*** Converts an quad-dotted IPv4 address into a integer
sub quaddot_to_int {
  my $quaddot = shift;
  my @quaddot_a;
  my $int;
  my $i;

  @quaddot_a = split(/\./, $quaddot);
  $int = 0;
  for ($i = 0; $i < 4; $i++) {
    $int <<= 8;
    $int |= $quaddot_a[$i];
  }

  return $int;
}

***REMOVED*** Converts an integer into a quad-dotted IPv4 address
sub int_to_quaddot {
  my $int = shift;
  my @quaddot_a;
  my $i;

  for ($i = 3; $i >= 0; $i--) {
    $quaddot_a[$i] = $int & 0xFF;
    $int >>= 8;
  }

  return join('.', @quaddot_a);
}

***REMOVED*** Compute the subnet address associated to a couple IP/netmask
sub compute_subnet {
  my $ip = shift;
  my $netmask = shift;

  return int_to_quaddot(quaddot_to_int($ip) & quaddot_to_int($netmask));
}

***REMOVED*** Compute the broadcast address associated to a couple IP/netmask
sub compute_broadcast {
  my $ip = shift;
  my $netmask = shift;

  return   int_to_quaddot(quaddot_to_int($ip)
         | (0xFFFFFFFF - quaddot_to_int($netmask)));
}

***REMOVED*** Makes the patch hash that is used to replace the options in the dhcpd config
***REMOVED*** file.
***REMOVED*** These DHCP options are needed for the hostonly network.
sub make_dhcpd_patch {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my %patch;

  undef %patch;
  $patch{'%vmnet%'} = $vHostIf;
  $patch{'%hostaddr%'} = db_get_answer('VNET_' . $vHubNr
                                       . '_HOSTONLY_HOSTADDR');
  $patch{'%netmask%'} = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK');
  $patch{'%network%'} = db_get_answer_if_exists('VNET_' . $vHubNr . '_HOSTONLY_SUBNET');
  if (not defined($patch{'%network%'})) {
     $patch{'%network%'} = compute_subnet($patch{'%hostaddr%'}, $patch{'%netmask%'});
  }
  $patch{'%broadcast%'} = compute_broadcast($patch{'%hostaddr%'},
                                            $patch{'%netmask%'});
  ***REMOVED*** Median address in this subnet
  $patch{'%range_low%'} = int_to_quaddot(
    (quaddot_to_int($patch{'%network%'})
     + quaddot_to_int($patch{'%broadcast%'}) + 1) / 2);
  ***REMOVED*** Last normal address in this subnet
  $patch{'%range_high%'} = int_to_quaddot(
    quaddot_to_int($patch{'%broadcast%'}) - 1);
  $patch{'%router_option%'} = "";
  return %patch;
}

***REMOVED*** Write VMware's DHCPd configuration files
sub write_dhcpd_config {
  my $vHubNr = shift;
  my $vHostIf = shift;
  ***REMOVED*** Function that makes the patch needed for the DHCP config file
  my $make_patch_func = shift;
  my $dhcpd_dir;
  my %patch;

  %patch = &$make_patch_func($vHubNr, $vHostIf);

  ***REMOVED*** Create the dhcpd config directory (one per virtual interface)
  $dhcpd_dir = $gRegistryDir . '/' . $vHostIf . '/dhcpd';
  create_dir($dhcpd_dir, $cFlagDirectoryMark);

  install_file(db_get_answer('LIBDIR') . '/configurator/vmnet-dhcpd.conf',
               $dhcpd_dir . '/dhcpd.conf', \%patch,
               $cFlagTimestamp | $cFlagConfig);

  ***REMOVED*** Create empty files that will be created by the daemon
  ***REMOVED*** They will be modified by the daemon, don't timestamp them
  undef %patch;
  install_file('/dev/null', $dhcpd_dir . '/dhcpd.leases', \%patch, 0);
  safe_chmod(0644, $dhcpd_dir . '/dhcpd.leases');
  undef %patch;
  install_file('/dev/null', $dhcpd_dir . '/dhcpd.leases~', \%patch, 0);
  safe_chmod(0644, $dhcpd_dir . '/dhcpd.leases~');
}

***REMOVED*** Check the normal dhcp configuration and give advises
sub dhcpd_consultant {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $conf;
  my $network;
  my $netmask;

  if (-r '/etc/dhcpd.conf') {
    $conf = '/etc/dhcpd.conf';
  } else {
    return;
  }

  $netmask = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK');
  $network = compute_subnet(db_get_answer('VNET_' . $vHubNr
                                          . '_HOSTONLY_HOSTADDR'), $netmask);

  ***REMOVED*** The host has a normal dhcpd setup
  if (direct_command(
    shell_string($gHelper{'grep'}) . ' '
    . shell_string('^[ ' . "\t" . ']*subnet[ ' . "\t" . ']*' . $network) . ' '
    . shell_string($conf)) eq '') {
    query('This system appears to have a DHCP server configured for normal '
          . 'use.  Beware that you should teach it how not to interfere with '
          . vmware_product_name() . '\'s DHCP server.  There are two ways to '
          . 'do this:' . "\n\n" . '1) Modify the file ' . $conf . ' to add '
          . 'something like:' . "\n\n" . 'subnet ' . $network . ' netmask '
          . $netmask . ' {' . "\n" . '    ***REMOVED*** Note: No range is given, '
          . 'vmnet-dhcpd will deal with this subnet.' . "\n" . '}' . "\n\n"
          . '2) Start your DHCP server with an explicit list of network '
          . 'interfaces to deal with (leaving out ' . $vHostIf . '). e.g.:'
          . "\n\n" . 'dhcpd eth0' . "\n\n" . 'Consult the dhcpd(8) and '
          . 'dhcpd.conf(5) manual pages for details.' . "\n\n"
          . 'Hit enter to continue.', '', 0);
  }
}

***REMOVED*** Configuration of hostonly networking
sub configure_hostonly_net {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $run_dhcpd = shift;
  my $hostaddr;
  my $subnet;
  my $netmask;
  my $status;

  if ($vHubNr < $gMinVmnet || $vHubNr > $gMaxVmnet) {
    print wrap('Number of virtual networks exceeded.  Not creating virtual '
               . 'network.' . "\n\n", 0);
    return;
  }

  ***REMOVED*** If this wasn't a hostonly network before, wipe out the old configuration
  ***REMOVED*** info as it may confuse us later.
  if (!is_hostonly_network($vHubNr)) {
    remove_net($vHubNr, $vHostIf);
  }

  print wrap('Configuring a host-only network for vmnet' . $vHubNr . '.'
             . "\n\n", 0);

  if (vmware_product() eq 'wgs') {
     get_network_name_answer($vHubNr, 'HostOnly');
  }

  my $keep_settings;

  $keep_settings = 'no';
  $hostaddr = $gDBAnswer{'VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR'};
  $netmask = $gDBAnswer{'VNET_' . $vHubNr . '_HOSTONLY_NETMASK'};

  if (defined($hostaddr) && defined($netmask)) {
    $subnet = db_get_answer_if_exists('VNET_' . $vHubNr . '_HOSTONLY_SUBNET');
    if (not defined($subnet)) {
       $subnet = compute_subnet($hostaddr, $netmask);
    }
    $keep_settings = get_answer('The host-only network is currently '
                                . 'configured to use the private subnet '
                                . $subnet . '/' . $netmask . '.  Do you want '
                                . 'to keep these settings?', 'yesno', 'yes');
  }

  if ($keep_settings eq 'no') {
    ***REMOVED*** Get the new settings
    for (;;) {
      my $answer;

      $answer = get_answer('Do you want this program to probe for an unused '
                           . 'private subnet? (yes/no/help)',
                           'yesnohelp', 'yes');

      if ($answer eq 'yes') {
        my @usedSubnets = get_used_subnets();
        ($status, $subnet, $netmask) = subnet_probe($vHubNr, $vHostIf,
                                                    \@usedSubnets);
        if ($status) {
          last;
        }
        ***REMOVED*** Fallback
        $answer = 'no';
      }

      if ($answer eq 'no') {
	do {
	  ***REMOVED*** An empty default answer is dangerous as running
	  ***REMOVED*** with --default can cause an infinite loop, however
	  ***REMOVED*** --default will never make it here, so we're safe.
	  $hostaddr = get_answer('What will be the IP address of '
				 . 'your ' . $machine . ' on the '
				 . 'private network?',
				 'ip', '');
	  $netmask = get_answer('What will be the netmask of your '
				. 'private network?',
				'ip', '');
        } until (is_good_network($hostaddr, $netmask) eq 'yes');
	$subnet = compute_subnet($hostaddr, $netmask);
	last;
      }

      print wrap('Virtual machines configured to use host-only networking are '
                 . 'placed on a virtual network that is confined to this '
                 . $machine . '.  Virtual machines on this network can '
                 . 'communicate with each other and the ' . $os . ', but no '
                 . 'one else.' . "\n\n" . 'To setup this host-only networking '
                 . 'you need to select a network number that is normally '
                 . 'unreachable from the ' . $machine . '.  We can '
                 . 'automatically select this number for you, or you can '
                 . 'specify a network number that you want.' . "\n\n" . 'The '
                 . 'automatic selection process works by testing a series of '
                 . 'Class C subnet numbers to see if they are reachable from '
                 . 'the ' . $machine . '.  The first one that is unreachable '
                 . 'is used.  The subnet numbers are chosen from the private '
                 . 'network numbers specified by the Internet Engineering '
                 . 'Task Force (IETF) in RFC 1918 (http://www.isi.edu/in-notes'
                 . '/rfc1918.txt).' . "\n\n" . 'Remember that the host-only '
                 . 'network that virtual machines reside on will not be '
                 . 'accessible outside the host machine.  This means that it '
                 . 'is OK to use the same number on different systems so long '
                 . 'as you do not enable communication between these networks.'
                 . "\n\n", 0);
    }
  }

  make_hostonly_net($vHubNr, $vHostIf, $subnet, $netmask, $run_dhcpd);

  if ($run_dhcpd) {
    dhcpd_consultant($vHubNr, $vHostIf);
  }
}

***REMOVED*** Creates a hostonly network
sub make_hostonly_net {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $subnet = shift;
  my $netmask = shift;
  my $run_dhcpd = shift;

  my $hostaddr = int_to_quaddot(quaddot_to_int($subnet) + 1);

  configure_dev('/dev/' . $vHostIf, 119, $vHubNr, 1);

  db_add_answer('VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR', $hostaddr);
  db_add_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK', $netmask);
  db_add_answer('VNET_' . $vHubNr . '_HOSTONLY_SUBNET', $subnet);
  db_add_answer('VNET_' . $vHubNr . '_DHCP', 'yes');

  if ($run_dhcpd) {
    write_dhcpd_config($vHubNr, $vHostIf, \&make_dhcpd_patch);
  } else {
    ***REMOVED*** XXX NOT IMPLEMENTED
  }

  ***REMOVED*** Unmake Samba just in case they have it from a previous product version
  if (defined($gDBAnswer{'NETWORKING'}) && get_samba_net() != -1) {
    unmake_samba_net($vHubNr, $vHostIf);
  }
}

***REMOVED*** Get the list of subnets used by all the hostonly networks
sub get_hostonly_subnets {
  my $vHubNr;
  my @subnets = ();
  for ($vHubNr = $gMinVmnet; $vHubNr <= $gMaxVmnet; $vHubNr++) {
    if (is_hostonly_network($vHubNr)) {
      my $hostaddr = db_get_answer('VNET_' . $vHubNr  . '_HOSTONLY_HOSTADDR');
      my $netmask = db_get_answer('VNET_' . $vHubNr  . '_HOSTONLY_NETMASK');
      push(@subnets, compute_subnet($hostaddr, $netmask));
    }
  }
  return @subnets;
}

***REMOVED*** Unconfigures Samba from the hostonly network
sub unmake_samba_net {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $smb_dir = $gRegistryDir . '/' . $vHostIf . '/smb';
  if (is_samba_running($vHubNr)) {
    db_remove_answer('VNET_' . $vHubNr . '_SAMBA');
    db_remove_answer('VNET_' . $vHubNr . '_SAMBA_MACHINESID');
    db_remove_answer('VNET_' . $vHubNr . '_SAMBA_SMBPASSWD');
    uninstall_prefix($smb_dir);
  }
  db_add_answer('VNET_' . $vHubNr . '_SAMBA', 'no');
}

***REMOVED*** Gets the virtual network number where Samba is located.
sub get_samba_net {
  my $vHubNr;

  for ($vHubNr = $gMinVmnet; $vHubNr <= $gMaxVmnet; $vHubNr++) {
    if (is_samba_running($vHubNr)) {
      return $vHubNr;
    }
  }

  return -1;
}

***REMOVED*** Check to see if the Samba question was ever asked and answered.
***REMOVED*** Returns 1 if it has. 0 otherwise.
sub was_samba_answered {
  my $vHubNr;

  for ($vHubNr = $gMinVmnet; $vHubNr <= $gMaxVmnet; $vHubNr++) {
    if (defined($gDBAnswer{'VNET_' . $vHubNr . '_SAMBA'})) {
      return 1;
    }
  }
  return 0;
}

***REMOVED*** Configuration of NAT networking
sub configure_nat_net {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $hostaddr;
  my $subnet;
  my $netmask;
  my $status;

  if ($vHubNr < $gMinVmnet || $vHubNr > $gMaxVmnet) {
    print wrap('Number of virtual networks exceeded.  Not creating virtual '
               . 'network.' . "\n\n", 0);
    return;
  }

  ***REMOVED*** If this wasn't a NAT network before, wipe out the old configuration info
  ***REMOVED*** as it may confuse us later.
  if (!is_nat_network($vHubNr)) {
    remove_net($vHubNr, $vHostIf);
  }

  print wrap('Configuring a NAT network for vmnet' . "$vHubNr." . "\n\n", 0);

  if (vmware_product() eq 'wgs') {
     get_network_name_answer($vHubNr, 'NAT');
  }

  my $keep_settings;

  $keep_settings = 'no';
  $hostaddr = $gDBAnswer{'VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR'};
  $netmask = $gDBAnswer{'VNET_' . $vHubNr . '_HOSTONLY_NETMASK'};

  if (defined($hostaddr) && defined($netmask)) {
    $subnet = $gDBAnswer{'VNET_' . $vHubNr . '_HOSTONLY_SUBNET'};
    if (not defined($subnet)) {
       $subnet = compute_subnet($hostaddr, $netmask);
    }
    $keep_settings = get_answer('The NAT network is currently configured to '
                                . 'use the private subnet ' . $subnet . '/'
                                . $netmask . '.  Do you want to keep these '
                                . 'settings?', 'yesno', 'yes');
  }

  if ($keep_settings eq 'no') {
    ***REMOVED*** Get the new settings
    for (;;) {
      my $answer;

      $answer = get_answer('Do you want this program to probe for an unused '
                           . 'private subnet? (yes/no/help)',
                           'yesnohelp', 'yes');

      if ($answer eq 'yes') {
        my @usedSubnets = get_used_subnets();
        ($status, $subnet, $netmask) = subnet_probe($vHubNr, $vHostIf,
                                                    \@usedSubnets);
        if ($status) {
          last;
        }
        ***REMOVED*** Fallback
        $answer = 'no';
      }

      if ($answer eq 'no') {
	do {
	  ***REMOVED*** An empty default answer is dangerous as running
	  ***REMOVED*** with --default can cause an infinite loop, however
	  ***REMOVED*** --default will never make it here, so we're safe.
	  $hostaddr = get_answer('What will be the IP address of '
				 . 'your ' . $machine . ' on the '
				 . 'private network?',
				 'ip', '');
	  $netmask = get_answer('What will be the netmask of your '
				. 'private network?',
				'ip', '');
        } until (is_good_network($hostaddr, $netmask) eq 'yes');
	$subnet = compute_subnet($hostaddr, $netmask);
	last;
      }

      print wrap('Virtual machines configured to use NAT networking are '
                 . 'placed on a virtual network that is confined to this '
                 . $machine . '.  Virtual machines on this network can '
                 . 'communicate with the network through the NAT process, '
                 . 'with each other, and with the ' . $os . '.' . "\n\n"
                 . 'To setup NAT networking you need to select a network '
                 . 'number that is normally unreachable from the ' . $machine
                 . '.  We can automatically select this number for you, or '
                 . 'you can specify a network number that you want.' . "\n\n"
                 . 'The automatic selection process works by testing a series '
                 . 'of Class C subnet numbers to see if they are reachable '
                 . 'from the ' . $machine . '.  The first one that is '
                 . 'unreachable is used.  The subnet numbers are chosen from '
                 . 'the private network numbers specified by the Internet '
                 . 'Engineering Task Force (IETF) in RFC 1918 (http://www.isi'
                 . '.edu/in-notes/rfc1918.txt).' . "\n\n" . 'Virtual machines '
                 . 'residing on the NAT network will appear as the host when '
                 . 'accessing the network.  These virtual machines on the NAT '
                 . 'network will not be accessible from outside the host '
                 . 'machine.  This means that it is OK to use the same number '
                 . 'on different systems so long as you do not enable IP '
                 . 'forwarding on the ' . $machine . '.' . "\n\n", 0);
    }
  }

  make_nat_net($vHubNr, $vHostIf, $subnet, $netmask);
  dhcpd_consultant($vHubNr, $vHostIf);
}

***REMOVED*** Creates a NAT network
sub make_nat_net {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $subnet = shift;
  my $netmask = shift;

  my $hostaddr = int_to_quaddot(quaddot_to_int($subnet) + 1);
  my $nataddr = int_to_quaddot(quaddot_to_int($subnet) + 2);

  configure_dev('/dev/' . $vHostIf, 119, $vHubNr, 1);

  db_add_answer('VNET_' . $vHubNr . '_NAT', 'yes');
  db_add_answer('VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR', $hostaddr);
  db_add_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK', $netmask);
  db_add_answer('VNET_' . $vHubNr . '_HOSTONLY_SUBNET', $subnet);
  db_add_answer('VNET_' . $vHubNr . '_DHCP', 'yes');

  write_dhcpd_config($vHubNr, $vHostIf, \&make_nat_patch);
  write_nat_config($vHubNr, $vHostIf);
}

***REMOVED*** Write NAT configuration files
sub write_nat_config {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $nat_dir;
  my %patch;

  ***REMOVED*** Create the nat config directory (one per virtual interface)
  $nat_dir = $gRegistryDir . '/' . $vHostIf . '/nat';
  create_dir($nat_dir, $cFlagDirectoryMark);

  undef %patch;

  my $hostaddr = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR');
  my $netmask = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK');
  my $network = db_get_answer_if_exists('VNET_' . $vHubNr . '_HOSTONLY_SUBNET');
  if (not defined($network)) {
     $network = compute_subnet($hostaddr, $netmask);
  }
  my $broadcast = compute_broadcast($hostaddr, $netmask);
  my $nataddr = int_to_quaddot(quaddot_to_int($network) + 2);

  $patch{'%nataddr%'} = $nataddr;
  $patch{'%netmask%'} = $netmask;
  $patch{'%sample%'} = int_to_quaddot(
    (quaddot_to_int($network) + quaddot_to_int($broadcast) + 1) / 2);
  $patch{'%vmnet%'} = "/dev/" . $vHostIf;
  install_file(db_get_answer('LIBDIR') . '/configurator/vmnet-nat.conf',
               $nat_dir . '/nat.conf', \%patch,
               $cFlagTimestamp | $cFlagConfig);
}

***REMOVED*** Makes the patch hash that is used to replace the options in the dhcpd config
***REMOVED*** file.
***REMOVED*** These DHCP options are needed for the NAT network.
sub make_nat_patch {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my %patch;

  my $hostaddr = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR');
  my $netmask = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK');
  my $subnet = db_get_answer_if_exists('VNET_' . $vHubNr . '_HOSTONLY_SUBNET');
  if (not defined($subnet)) {
     $subnet = compute_subnet($hostaddr, $netmask);
  }
  my $nataddr = int_to_quaddot(quaddot_to_int($subnet) + 2);

  undef %patch;
  $patch{'%vmnet%'} = $vHostIf;
  $patch{'%hostaddr%'} = $nataddr;
  $patch{'%netmask%'} = $netmask;
  $patch{'%network%'} = compute_subnet($nataddr, $netmask);
  $patch{'%broadcast%'} = compute_broadcast($nataddr, $netmask);
  ***REMOVED*** Median address in this subnet
  $patch{'%range_low%'} = int_to_quaddot(
    (quaddot_to_int($patch{'%network%'})
     + quaddot_to_int($patch{'%broadcast%'}) + 1) / 2);
  ***REMOVED*** Last normal address in this subnet
  $patch{'%range_high%'} = int_to_quaddot(quaddot_to_int($patch{'%broadcast%'})
                                          - 1);
  $patch{'%router_option%'} = "option routers $nataddr;";
  return %patch;
}

***REMOVED*** Get the list of subnets used by all the nat networks
sub get_nat_subnets {
  my $vHubNr;
  my @subnets = ();
  for ($vHubNr = $gMinVmnet; $vHubNr <= $gMaxVmnet; $vHubNr++) {
    if (is_nat_network($vHubNr)) {
      my $subnet = db_get_answer_if_exists('VNET_' . $vHubNr . '_HOSTONLY_SUBNET');
      if (not defined($subnet)) {
         my $hostaddr = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR');
         my $netmask = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK');
         $subnet = compute_subnet($hostaddr, $netmask);
      }
      push(@subnets, $subnet);
    }
  }
  return @subnets;
}

***REMOVED*** Get the list of subnets that are already used by virtual networks
sub get_used_subnets {
  return (&get_hostonly_subnets(), &get_nat_subnets());
}

***REMOVED*** Return the specific VMware product
sub vmware_product {
  return 'tools-for-linux';
}

***REMOVED*** This is a function in case a future product name contains language-specific
***REMOVED*** escape characters.
sub vmware_product_name {
  return 'VMware Tools';
}

***REMOVED*** Returns the name of the main binary for this install.
sub vmware_binary {
  return 'vmware-toolbox';
}

sub vmware_tools_app_name {
  return db_get_answer('BINDIR') . '/vmware-toolbox';
}

sub vmware_tools_cmd_app_name {
  return db_get_answer('BINDIR') . '/vmware-toolbox-cmd';
}

***REMOVED*** Security configuration:  Add certificates for the remote console.
sub configure_security() {
  my $version = 'GSX';

  createSSLCertificates(db_get_answer('LIBDIR') . '/bin/openssl',
                        $version,
                        $gRegistryDir . '/ssl',
                        'rui',
                        'VMware Management Interface');
}

***REMOVED*** Find binaries necessary for the server products (esx/gsx)
sub configure_server {
  my $program;

  ***REMOVED*** Create the /var/log/vmware directory for event logs
  create_dir($gLogDir, $cFlagDirectoryMark);

  ***REMOVED*** Kill any running vmware-hostd process.
  system(shell_string($gHelper{'killall'}) . ' -TERM vmware-hostd '
         . '>/dev/null 2>&1');

  configure_authd();
  configure_wgs_pam_d();
  fix_vmlist_permissions();
}

***REMOVED*** Try to find a free port for authd use starting from default passed in
***REMOVED*** If none are available, return default passed in
sub get_port_for_authd {
  my $base_port = shift;
  my $port = $base_port;
  my $max_range = 65536;
  while (check_answer_inetport($port, "default") ne $port) {
    $port = ($port + 1) % $max_range;
    if ($base_port == $port) {
      last;
    }
  }
  return $port;
}

***REMOVED*** Find a suitable port for authd
sub configure_authd {
  my $success     = 0;
  my $port;

  ***REMOVED*** Initialize the port cache.  Contains the set of ports
  ***REMOVED*** known to be active on the system:  listed in /proc/net/tcp.
  get_proc_tcp_entries();

  if (defined(db_get_answer_if_exists("AUTHDPORT"))) {
    $port = db_get_answer_if_exists("AUTHDPORT");
  } else {
    ***REMOVED*** We'll try to find a good default port that is free
    $port = get_port_for_authd($gDefaultAuthdPort);
    if ($port != $gDefaultAuthdPort) {
      print wrap('The default port : '. $gDefaultAuthdPort. ' is not free.'
                 . ' We have selected a suitable alternative port for '
                 . vmware_product_name()
                 . ' use. You may override this value now.' . "\n", 0);
      print wrap(' Remember to use this port when installing'
                 . ' remote clients on other machines.' . "\n", 0);
    }
  }

  $port = get_persistent_answer('Please specify a port for remote'
                                . ' connections to use',
                                'AUTHDPORT',
                                'inetport',
                                $port);

  if ($gDefaultAuthdPort != $port) {
    print wrap('WARNING: ' . vmware_product_name() . ' has been configured to '
               . 'run on a port different from the default port. '
               . 'Please make sure to use this port when installing remote'
               . ' clients on other machines.' . "\n\n", 0);
  }

  db_add_answer('VMAUTHD_USE_LAUNCHER', 'yes');
}

***REMOVED*** Setup the hostd configuration files
sub configure_hostd {
   my %patch;

   ***REMOVED*** Hostd config file
   %patch = ();
   $patch{'***REMOVED******REMOVED***{WORKINGDIR}***REMOVED******REMOVED***'} = $gLogDir . '/';
   $patch{'***REMOVED******REMOVED***{LOGDIR}***REMOVED******REMOVED***'} = $gLogDir . '/';
   $patch{'***REMOVED******REMOVED***{CFGDIR}***REMOVED******REMOVED***'} = $gRegistryDir . '/';
   $patch{'***REMOVED******REMOVED***{LIBDIR}***REMOVED******REMOVED***'} = db_get_answer('LIBDIR') . '/';
   $patch{'***REMOVED******REMOVED***{LIBDIR_INSTALLED}***REMOVED******REMOVED***'} = db_get_answer('LIBDIR') . '/';
   $patch{'***REMOVED******REMOVED***{BUILD_CFGDIR}***REMOVED******REMOVED***'} = $gRegistryDir . '/hostd/';
   $patch{'***REMOVED******REMOVED***{PLUGINDIR}***REMOVED******REMOVED***'} = db_get_answer('LIBDIR') . '/hostd/';
   $patch{'***REMOVED******REMOVED***{USE_DYNAMIC_PLUGIN_LOADING}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{SHLIB_PREFIX}***REMOVED******REMOVED***'} = 'lib';
   $patch{'***REMOVED******REMOVED***{SHLIB_SUFFIX}***REMOVED******REMOVED***'} = '.so';
   $patch{'***REMOVED******REMOVED***{ENABLE_AUTH}***REMOVED******REMOVED***'} = 'true';
   $patch{'***REMOVED******REMOVED***{USE_PARTITIONSVC}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{USE_NFCSVC}***REMOVED******REMOVED***'} = 'true';
   $patch{'***REMOVED******REMOVED***{USE_BLKLISTSVC}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{USE_CIMSVC}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{USE_SNMPSVC}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{USE_HTTPNFCSVC}***REMOVED******REMOVED***'} = 'true';
   $patch{'***REMOVED******REMOVED***{USE_OVFMGRSVC}***REMOVED******REMOVED***'} = 'true';
   $patch{'***REMOVED******REMOVED***{USE_DIRECTORYSVC}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{USE_DYNSVC}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{MOCKUP}***REMOVED******REMOVED***'} = 'mockup-linux.vha';
   $patch{'***REMOVED******REMOVED***{HOSTDMODE}***REMOVED******REMOVED***'} = 'server';
   $patch{'***REMOVED******REMOVED***{USE_VDISKSVC}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{USE_HOSTSVC_MOCKUP}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{USE_STATSSVC_MOCKUP}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{PIPE_PREFIX}***REMOVED******REMOVED***'} = '/var/run/vmware/';
   $patch{'***REMOVED******REMOVED***{LOGLEVEL}***REMOVED******REMOVED***'} = 'verbose';
   $patch{'***REMOVED******REMOVED***{USE_SECURESOAP}***REMOVED******REMOVED***'} = 'false';
   $patch{'***REMOVED******REMOVED***{USE_DYNAMO}***REMOVED******REMOVED***'} = 'false';


   ***REMOVED*** XXX Using mockups for now. Change these once they've been implemented.
   $patch{'***REMOVED******REMOVED***{USE_LICENSESVC_MOCKUP}***REMOVED******REMOVED***'} = 'true';

   install_template_file($gRegistryDir . '/hostd/config-template.xml', \%patch, 1);

   ***REMOVED***Hostd proxy file:
   my $httpAnswer;
   my $httpsAnswer;
   ($httpAnswer, $httpsAnswer) = query_user_for_proxy_ports();
   if (!defined($httpAnswer)) {
      my $msg = "Unable to find a set of ports needed by the proxy file.\n";
      print wrap($msg, 0);
      return 0;
   }
   $patch{'***REMOVED******REMOVED***{HTTP_PORT}***REMOVED******REMOVED***'} = $httpAnswer;
   $patch{'***REMOVED******REMOVED***{HTTPS_PORT}***REMOVED******REMOVED***'} = $httpsAnswer;
   install_template_file($gRegistryDir . '/hostd/proxy-template.xml', \%patch, 0);

   ***REMOVED*** Update the port value for the WebAccess.properties file.
   my $file;
   my $jslib;
   my $property_file;
   my $app_dir = "modules/com.vmware.webaccess.app_1.0.0";
   my $ui_dir = db_get_answer('LIBDIR') . '/webAccess/tomcat/@@TOMCAT_DIST@@/webapps/ui';
   foreach $file (internal_ls($ui_dir)) {
      if ($file =~ /jslib-1./) {
         $jslib = $file;
         ***REMOVED*** Update any jslib directory.  The action will only happen for files
         ***REMOVED*** not already updated (patched) and leave previously configured files
         ***REMOVED*** alone.
         my $path = $ui_dir . "/" .  $jslib . "/" . $app_dir;
         my $template_file  = $path . "/WebAccess-template.properties";
         if (!-f $template_file) {
            next;
         } ***REMOVED*** Regenerate the property file from the template.
         install_template_file($template_file, \%patch, 0);
         $property_file  = $path . "/WebAccess.properties";
      }
   }

   ***REMOVED*** the jslib directory name contains the build number of the wbc built into
   ***REMOVED*** the server package.  And it is not necessarily the same as the build
   ***REMOVED*** number of this server package.
   if (!defined($jslib)) {
      my $msg =  "There is no jslib component directory in " . $ui_dir . "."
                 . "  The component directory should have the"
                 . " form:  jslib-1.xxxxx.\n";
      print(wrap($msg), 0);
      return 0;
   }

   if (!defined($property_file) || ! -f $property_file) {
      error("There is no " . $property_file . "!  This file is necessary for "
          . "the operation of the webAccess service.\n");
   }

   %patch = ();
   my $admin = 'root';
   my $currentAdmin = '';
   my $auth_file = $gRegistryDir . '/hostd/authorization.xml';
   if (file_name_exist($auth_file)) {
      open(ADMIN, $auth_file) or error "Could not open $auth_file.\n";
      while (<ADMIN>) {
         ***REMOVED*** $currentAdmin only changes if a user is listed.  Not for an empty user name.
         if (/ACEDataUser>(\w+)</) {
            $currentAdmin = $1;
            ***REMOVED*** Set and later check to see if the user set $admin to something else.
            $admin = $currentAdmin;
            last;
         }
      }
      close(ADMIN);
   }

   my $msg = "  The current administrative user for " . vmware_product_name() . "  "
           . "is '" . $currentAdmin . "'.  Would you like to specify a different "
           . "administrator?";
   if (get_answer($msg, 'yesno', 'no') eq 'yes') {
      $msg = "  Please specify the user whom you wish to be the " . vmware_product_name()
           . " administrator\n";
      $admin = get_answer($msg, 'usergrp', $currentAdmin);
   }
   print wrap("  Using " . $admin . " as the " . vmware_product_name()
            . " administrator.\n\n", 0);

   %patch = ('ACEDataUser>\w*<' => "ACEDataUser>$admin<");
   if (file_name_exist($auth_file) && $admin ne $currentAdmin) {
      ***REMOVED*** This value lives in a config file that we would normally not touch directly
      ***REMOVED*** instead makeing the mod via a template file.  But in this case the user has
      ***REMOVED*** made an explicit change, that must be placed in the config file directly.
      my $tmp_dir = make_tmp_dir('vmware-auth');
      my $tmp_file = $tmp_dir . '/tmp_auth';
      internal_sed($auth_file, $tmp_file, 0, \%patch);
      system(shell_string($gHelper{'mv'}) . ' ' . $tmp_file . ' ' . $auth_file);
      remove_tmp_dir($tmp_dir);
   }

   ***REMOVED*** authorization.xml is updated by the daemon after the file is installed..
   install_template_file($gRegistryDir . '/hostd/authorization-template.xml', \%patch, 1);

   ***REMOVED*** VM inventory file modifiable during use.
   install_template_file($gRegistryDir . '/hostd/vmInventory-template.xml', \%patch, 1);

   ***REMOVED*** Client information file modifiable during use.
   $patch{'@@AUTHD_PORT@@'} = db_get_answer('AUTHDPORT');
   $patch{'@@HTTPS_PORT@@'} = $httpsAnswer;

   my $docroot = db_get_answer('LIBDIR') . "/hostd/docroot";
   install_template_file($docroot . '/client/clients-template.xml', \%patch, 1);

   return 1;
}

sub install_template_file {
   my $template_file = shift;
   my $patchRef  = shift;
   my $preserve = shift;
   my $flags = $cFlagTimestamp | $cFlagConfig;
   my $dest_path = $template_file;

   $dest_path =~ s/-template//;
   my $dest_file = internal_basename($dest_path);
   my $dest_dir = internal_dirname($dest_path);

   if (file_name_exist($dest_path) && ($preserve & 1)) {
      my $msg = "You have a pre-existing " . $dest_file . ".  The new version will "
                . "be created as " . $dest_dir . "/NEW_" . $dest_file . ".  Please check "
                . "the new file for any new values that you may need to migrate to "
                . "your current " . $dest_file . ".\n\n";

      print wrap($msg, 0);
      $dest_path = $dest_dir . "/NEW_" . $dest_file;
   }

   install_file($template_file, $dest_path, \%$patchRef, $flags);
}

sub query_user_for_proxy_ports {
  my $httpProxy;
  my $httpsProxy;

  ***REMOVED*** If this is not the first time config has run, then use the port
  ***REMOVED*** values already chosen.  Count the ports as found if and only if
  ***REMOVED*** they're both specified and available or at least user approved.
  ***REMOVED*** If this is the first time, then there won't be any proxy port
  ***REMOVED*** values to get.
  if (defined(db_get_answer_if_exists('HTTP_PROXY_PORT')) &&
      defined(db_get_answer_if_exists('HTTPS_PROXY_PORT'))) {
    $httpProxy = db_get_answer('HTTP_PROXY_PORT');
    $httpsProxy = db_get_answer('HTTPS_PROXY_PORT');
    my $answer = get_persistent_answer("Do you want to use the current proxy port "
                                       . "values?", 'USE_CURRENT_PORTS', 'yesno', 'yes');
    if ($answer eq 'yes') {
      return ($httpProxy, $httpsProxy);
    }
  }

  ***REMOVED*** Update the port cache.  It has happened that services active when entries
  ***REMOVED*** were first retrieved are now no longer active.
  get_proc_tcp_entries();

  ***REMOVED*** Before we ask the user if he wants the default proxy ports, make sure
  ***REMOVED*** they are available.  Even if one of the pair is in use, treat the whole
  ***REMOVED*** pair as in use and go to the next set of proxy ports.
  while ($***REMOVED***gDefaultHttpProxy != -1) {
     $httpProxy = shift(@gDefaultHttpProxy);
     $httpsProxy = shift(@gDefaultHttpSProxy);
    if (!check_if_port_active($httpProxy) &&
        !check_if_port_active($httpsProxy)) {
      last;
    }
  }

  my $httpPort  = get_persistent_answer('Please specify a port for ' .
                                        'standard http connections to use',
                                        'HTTP_PROXY_PORT', 'inetport',
                                        $httpProxy);

  my $httpsPort = get_persistent_answer('Please specify a port for ' .
                                        'secure http (https) connections to use',
                                        'HTTPS_PROXY_PORT', 'inetport',
                                        $httpsProxy);
  return ($httpPort, $httpsPort);
}

sub configure_webAccess {
  my $libdir = db_get_answer("LIBDIR");
  my $webAccess_root = "$libdir/webAccess";
  my $tomcat = $webAccess_root . '/tomcat/@@TOMCAT_DIST@@';
  my $work_dir = $tomcat . '/work';
  my $prop_src_root = $tomcat . '/webapps/ui/WEB-INF/classes';
  my $prop_dst_root = "/etc/vmware/webAccess";
  my $webAccessLogDir = $gLogDir . '/webAccess';

  ***REMOVED*** make links to the config files
  create_dir($prop_dst_root, $cFlagDirectoryMark);
  install_symlink($prop_src_root . "/log4j.properties",
                                  $prop_dst_root . "/log4j.properties");
  install_symlink($prop_src_root . "/proxy.properties",
                                  $prop_dst_root . "/proxy.properties");
  install_symlink($prop_src_root . "/login.properties",
                                  $prop_dst_root . "/login.properties");

  ***REMOVED*** tomcat-users.xml needs to be unconditionally removed.  Since the tomcat
  ***REMOVED*** service touches the installed version of tomcat-users.xml, the file needs
  ***REMOVED*** to be removed from the db, along with its timestamp, and re-added without
  ***REMOVED*** a timestamp.
  my $webAccessRoot = db_get_answer('LIBDIR') . "/webAccess";
  db_remove_ts($tomcat . '/conf/tomcat-users.xml');

  if (-e $work_dir) {
    remove_tmp_dir($work_dir);
  }


  create_dir($webAccessLogDir . '/work', 0x0);
  install_symlink($webAccessLogDir, $tomcat . '/logs');
  install_symlink($webAccessLogDir . '/work', $work_dir);
}

***REMOVED***  Move the /etc/vmware/pam.d information to its real home in /etc/pam.d
sub configure_wgs_pam_d {
  my $dir = '/etc/pam.d';
  my $o_file = $gRegistryDir . '/pam.d/vmware-authd';

  if (system(shell_string($gHelper{'cp'}) . ' -p ' . $o_file . ' ' . $dir)) {
    error('Unable to copy the VMware vmware-authd PAM file to ' . $dir
          . "\n\n");
  }
}

***REMOVED*** both configuration.
sub show_net_config {
  my $bridge_flag = shift;
  my $hostonly_flag = shift;
  my $nat_flag = shift;

  ***REMOVED*** Don't show anything
  if (!$hostonly_flag && !$bridge_flag && !$nat_flag) {
    return;
  }

  ***REMOVED*** Print a message describing what we are showing
  my $nettype = 'virtual';
  if (!$bridge_flag && !$nat_flag && $hostonly_flag) {
    $nettype = 'host-only';
  } elsif (!$hostonly_flag && !$nat_flag && $bridge_flag) {
    $nettype = 'bridged';
  } elsif (!$bridge_flag && !$hostonly_flag && $nat_flag) {
    $nettype = 'NAT';
  }
  print wrap('The following ' . $nettype . ' networks have been defined:'
             . "\n\n", 0);

  ***REMOVED*** Number of networks configured
  my $count = 0;

  local(*WFD);
  if (not open(WFD, '| ' . $gHelper{'more'})) {
    error("Could not print networking configuration.\n");
  }

  my $i;
  for ($i = $gMinVmnet; $i <= $gMaxVmnet; $i++) {
    if ($bridge_flag && is_bridged_network($i)) {
    my $bridge = $gDBAnswer{'VNET_' . $i . '_INTERFACE'};
      print WFD wrap(". vmnet" . $i . ' is bridged to ' . $bridge . "\n", 0);
      $count++;
    } elsif ($hostonly_flag && is_hostonly_network($i)) {
      my $hostonly_addr = $gDBAnswer{'VNET_' . $i . '_HOSTONLY_HOSTADDR'};
      my $hostonly_mask = $gDBAnswer{'VNET_' . $i . '_HOSTONLY_NETMASK'};
      my $hostonly_subnet = $gDBAnswer{'VNET_' . $i . '_HOSTONLY_SUBNET'};
      if (not defined($hostonly_subnet)) {
         $hostonly_subnet = compute_subnet($hostonly_addr, $hostonly_mask);
      }
      my $sambaInfo = '';
      if (is_samba_running($i)) {
        $sambaInfo = '  This network had a Samba server running to allow '
                     . 'virtual machines to share the ' . $os . '\'s '
                     . 'filesystem. This is now obsolete. Please use the '
                     . 'VMware shared folders feature.';
      }

      print WFD wrap(". vmnet" . $i . ' is a host-only network on private '
                     . 'subnet ' . $hostonly_subnet . '.'
                     . $sambaInfo . "\n", 0);
      $count++;
    } elsif ($nat_flag && is_nat_network($i)) {
      my $hostonly_addr = $gDBAnswer{'VNET_' . $i . '_HOSTONLY_HOSTADDR'};
      my $hostonly_mask = $gDBAnswer{'VNET_' . $i . '_HOSTONLY_NETMASK'};
      my $hostonly_subnet = $gDBAnswer{'VNET_' . $i . '_HOSTONLY_SUBNET'};
      if (not defined($hostonly_subnet)) {
         $hostonly_subnet = compute_subnet($hostonly_addr, $hostonly_mask);
      }
      print WFD wrap(". vmnet" . $i . ' is a NAT network on private subnet '
                     . $hostonly_subnet . '.'
                     . "\n", 0);
      $count++;
    }
  }

  if ($count == 0) {
    print WFD wrap(". No virtual networks configured.\n", 0);
  }

  print WFD wrap("\n", 0);

  close(WFD);
}

***REMOVED*** Unconfigures the now obsolete Samba networking
sub unconfigure_samba {
  print wrap('Removing obsolete VMware Samba config info. To access the ' .
             'host filesystem please use the VMware shared folders.' .
             "\n\n", 0);
  unmake_samba_net($gDefHostOnly, 'vmnet' . $gDefHostOnly);
  return;
}

***REMOVED*** Go through the /etc/vmware/vm-list file and set permissions correctly
***REMOVED***  also, upgrade vmkernel device names on ESX Server
sub fix_vmlist_permissions {
  my $file = '/etc/vmware/vm-list';
  my $cf;

  if (not -e $file) {
    return;
  }

  if (get_answer('Do you want this program to set up permissions for your '
                 . 'registered virtual machines?  This will be done by '
                 . 'setting new permissions on all files found in the "'
                 . $file . '" file.', 'yesno', 'no') eq 'no') {
    return;
  }

  if (not open(F, "$file")) {
    print wrap('Aborting attempt to change permissions on config files found '
               . 'in "' . $file . '": Cannot read the file.' . "\n\n", 0);
    return;
  }
  while (<F>) {
    s/"//g;
    ***REMOVED*** This comment fixes emacs's broken syntax highlighting"
    ($cf) = m/^config (.*)$/;
    if (!defined($cf) || (not -e $cf) || (not -f $cf)) {
      next;
    }
    if (chmod(0754, $cf) != 1) {
      print wrap('Cannot change permissions on file "' . $cf . '".' . "\n\n",
                 0);
    }
  }
  close(F);
}

***REMOVED*** Check the system requirements to install this product
sub check_wgs_memory {
  my $availableRAMInMB;
  my $minRAMinMB = 256;

  $availableRAMInMB = memory_get_total_ram();
  if (not defined($availableRAMInMB)) {
    if (get_persistent_answer('Unable to determine the total amount of memory '
                              . 'on this system.  You need at least '
                              . $minRAMinMB . ' MB.  Do you really want to '
                              . 'continue?',
                              'PASS_RAM_CHECK', 'yesno', 'no') eq 'no') {
      exit(0);
    }
  } elsif ($availableRAMInMB < $minRAMinMB) {
    if (get_persistent_answer('There are only ' . $availableRAMInMB . ' MB '
                              . 'of memory on this system.  You need at least '
                              . $minRAMinMB . ' MB.  Do you really want to '
                              . 'continue?',
                              'PASS_RAM_CHECK', 'yesno', 'no') eq 'no') {
      exit(0);
    }
  }
}


***REMOVED*** Retrieve the amount of RAM (in MB)
***REMOVED*** Return undef if unable to determine
sub memory_get_total_ram {
  my $line;
  my $availableRAMInMB = undef;

  if (not open(MEMINFO, '</proc/meminfo')) {
    error('Unable to read the "/proc/meminfo" file.' . "\n\n");
  }
  while (defined($line = <MEMINFO>)) {
    chomp($line);

    if ($line =~ /^Mem:\s*(\d+)/) {
      $availableRAMInMB = $1 / (1024 * 1024);
      last;
    }
    if ($line =~ /^MemTotal:\s*(\d+)\s*kB/) {
      $availableRAMInMB = $1 / 1024;
      last;
    }
  }
  if (defined($availableRAMInMB)) {
    ***REMOVED***
    ***REMOVED*** Round up total memory to the nearest multiple of 8 or 32 MB, since the
    ***REMOVED*** "total" amount of memory reported by Linux is the total physical memory
    ***REMOVED*** minus the amount used by the kernel
    ***REMOVED***

    if ($availableRAMInMB < 128) {
      $availableRAMInMB = CEILDIV($availableRAMInMB, 8) * 8;
    } else {
      $availableRAMInMB = CEILDIV($availableRAMInMB, 32) * 32;
    }
  }
  close(MEMINFO);

  return $availableRAMInMB;
}

sub CEILDIV {
  my $left = shift;
  my $right = shift;

  return int(($left + $right - 1) / $right);
}

sub check_fuse_available {
  my $libModPath = join('/','/lib/modules', getKernRel());
  my $available = 'no';

  ***REMOVED*** See if FUSE has already been registered
  if (open(PROCFILESYSTEMS, "/proc/filesystems")) {
    if (grep(/fuse$/, <PROCFILESYSTEMS>)) {
      $available = 'yes';
    }
    close(PROCFILESYSTEMS);
  }

  ***REMOVED*** The module might not be loaded yet
  if ($available ne 'yes' &&
      open(MODULESDEP, "$libModPath/modules.dep")) {
    if (grep(/^(.*\/fuse\.k?o):.*$/, <MODULESDEP>)) {
      $available = 'yes';
    }
    close(MODULESDEP);
  }

  return $available;
}

sub configure_vmblock {
  ***REMOVED*** By default we don't want vmblock installed in guests runnning on ESX virtual enviroments
  ***REMOVED*** since its useless there.  However we want vmblock to be installed by default on VMs
  ***REMOVED*** running in WS/Fusion virtul environments.  Hence ask users and set the default answer based
  ***REMOVED*** on whether or not we are running in an ESX environment vs a WS/Fusion environment.
  my $defAns = is_esx_virt_env() ? 'no' : 'yes';
  my $vmblockQ = 'The vmblock enables dragging or copying files between host and guest ' .
	      'in a Fusion or Workstation virtual environment.  ' .
	      'Do you wish to enable this feature?';

  if (get_persistent_answer($vmblockQ, 'ENABLE_VMBLOCK', 'yesno', $defAns) eq 'no') {
     disable_module('vmblock');
     return;
  }

  my $result;
  my $canBuild = 'no';
  my $explain;

  if (vmware_product() eq 'tools-for-solaris') {
     $result = configure_module_solaris('vmblock');
  } elsif (vmware_product() eq 'tools-for-freebsd') {
     $result = configure_module_bsd('vmblock');
  } else {
     ***REMOVED*** Use the Fuse version of vmblock exclusively for kernel versions >= 2.6.32.
     ***REMOVED*** I picked this version because its the RHEL 6 release and when we started
     ***REMOVED*** upstreaming our various other kernel modules.
     if ($gSystem{'version_integer'} >= kernel_version_integer(2, 6, 32)) {
        if (check_fuse_available() eq 'yes') {
           db_add_answer('VMBLOCK_CONFED', 'yes');
        } else {
           disable_module('vmblock');
           print wrap("NOTICE:  " .
		      "It appears your system does not have the required fuse " .
                      "packages installed.  The VMware blocking filesystem " .
		      "requires the fuse packages and its libraries to " .
		      "function properly.  Please install the fuse or " .
		      "fuse-utils package using your systems package " .
		      "management utility and re-run this script in " .
		      "order to enable the VMware blocking filesystem. " .
		      "\n\n", 0);
        }
        return;
     }

    ***REMOVED*** Check if FUSE is available
    if ($gSystem{'version_integer'} >= kernel_version_integer(2, 6, 27) &&
        check_fuse_available() eq 'yes') {

      db_add_answer('VMBLOCK_CONFED', 'yes');
      return;
    }

    $result = mod_pre_install_check('vmblock');
    if ($result eq 'yes') {
      if ($gSystem{'version_integer'} < kernel_version_integer(2, 4, 0)) {
        print wrap("The vmblock module is not supported on kernels "
                   . "older than 2.4.0\n\n", 0);
        $result = 'no';
      } else {
        $result = configure_module('vmblock');
        $canBuild = 'yes';
      }

      if ($result eq 'no') {
        my $src;
        my $dest;
        if (vmware_product() =~ /^tools-for-/) {
          $src = "host";
          $dest = "guest";
        } else {
          $src = "guest";
          $dest = "host";
        }
        $explain = 'The vmblock module enables dragging or copying files from '
          . 'within a ' . $src . ' and dropping or pasting them onto '
            . 'your ' . $dest . ' (' . $src . ' to ' . $dest
              . ' drag and drop and file copy/paste).  The rest of the '
                . 'software provided by ' . vmware_product_name()
                  . ' is designed to work independently of this feature (including '
                    . $dest . ' to ' . $src . ' drag and drop and file copy/paste).'
                      . "\n\n";
        if ($canBuild eq 'yes') {
          $explain .=  'If you would like the ' . $src . ' to ' . $dest . ' drag '
            . 'and drop and file copy/paste features, '
              . $cModulesBuildEnv . "\n";
        }

        query($explain, ' Press Enter key to continue ', 0);
      }
    }
  }

  module_post_configure('vmblock', $result);
}

sub build_vmnet {
  if (db_get_answer('NETWORKING') ne 'no') {
    if (configure_module('vmnet') eq 'no') {
      module_error();
    }
  }
}

***REMOVED*** Configuration related to networking
sub configure_net {
  my $i;

  ***REMOVED*** Fix for bug 15842.  Always regenerate the network settings because an
  ***REMOVED*** upgrade leaves us in an inconsistent state.  The database will have
  ***REMOVED*** the network settings, but the necessary configuration files such as
  ***REMOVED*** dhcpd.conf will not exist until we run make_all_net().
  make_all_net();

  if (defined($gDBAnswer{'NETWORKING'}) && count_all_networks() > 0) {
    print wrap('You have already setup networking.' . "\n\n", 0);
    if (get_persistent_answer('Would you like to skip networking setup and '
                              . 'keep your old settings as they are? (yes/no)',
                              'NETWORKING_SKIP_SETUP', 'yesno', 'yes')
                              eq 'yes') {
      return;
    }
  }

  for (;;) {
    my $answer;
    my $helpString;
    my $prompt = 'Do you want networking for your virtual machines? '
               . '(yes/no/help)';
    $helpString = 'Networking will allow your virtual machines to use a '
                  . 'virtual network. There are primarily two types of '
                  . 'networking available: bridged and host-only.  A '
                  . 'bridged network is a virtual network that is '
                  . 'connected to an existing ethernet device.  With a '
                  . 'bridged network, your virtual machines will be able '
                  . 'to communicate with other machines on the network to '
                  . 'which the ethernet card is attached.  A host-only '
                  . 'network is a private network between your virtual '
                  . 'machines and ' . $os . '.  Virtual machines connected '
                  . 'to a host-only network may only communicate directly '
                  . 'with other virtual machines or the ' . $os
                  . '.  A virtual machine may be '
                  . 'configured with more than one bridged or host-only '
                  . 'network.' . "\n\n" . 'If you want your virtual '
                  . 'machines to be connected to a network, say "yes" '
                  . 'here.' . "\n\n";

    $answer = get_persistent_answer($prompt, 'NETWORKING', 'yesnohelp',
                                    'yes');
    if (($answer eq 'no') || ($answer eq 'yes')) {
      last;
    }

    print wrap($helpString, 0);
  }

  if (db_get_answer('NETWORKING') eq 'no') {
    ***REMOVED*** Turning off networking turns off hostonly.
    remove_all_networks(1, 1, 1);
    return;
  }

  for ($i = 0; $i < $gNumVmnet; $i++) {
    configure_dev('/dev/vmnet' . $i, 119, $i, 1);
  }

  ***REMOVED*** If there is a previous network configuration, prompt the user to
  ***REMOVED*** see if the user would like to modify the existing configuration.
  ***REMOVED*** If the user chooses to modify the settings, give the choice of
  ***REMOVED*** either the wizard or the editor.
  ***REMOVED***
  ***REMOVED*** If there is no previous network configuration, use the wizard.
  if (count_all_networks() > 0) {
    for (;;) {
      my $answer;
      $answer = get_persistent_answer('Would you prefer to modify your '
                                      . 'existing networking configuration '
                                      . 'using the wizard or the editor? '
                                      . '(wizard/editor/help)',
                                      'NETWORKING_EDITOR', 'editorwizardhelp',
                                      'wizard');
      if (($answer eq 'editor') || ($answer eq 'wizard')) {
        last;
      }

      print wrap('The wizard will present a series of questions that will '
                 . 'help you quickly add new virtual networks.  However, you '
                 . 'cannot remove networks or edit existing networks with the '
                 . 'wizard.  To remove or edit existing networks, you should '
                 . 'use the editor.' . "\n\n", 0);
    }

    ***REMOVED*** It doesn't make sense to launch the editor if we're not doing
    ***REMOVED*** an interactive installation.
    if (db_get_answer('NETWORKING_EDITOR') eq 'editor' &&
	$gOption{'default'} != 1) {
      configure_net_editor();
      return;
    }
  }
  configure_net_wizard();
}

***REMOVED*** Network configuration wizard
sub configure_net_wizard() {
  my $answer;

  ***REMOVED*** Bridged Networking
  if (db_get_answer('NETWORKING') eq 'yes' && count_bridged_networks() == 0) {
    ***REMOVED*** Make a default one unless it exists already
    configure_bridged_net($gDefBridged, 'vmnet' . $gDefBridged);
  }

  show_net_config(1, 0, 0);
  while ($***REMOVED***gAvailEthIf > -1) {
    if (get_answer('Do you wish to configure another bridged network? '
                   . '(yes/no)', 'yesno', 'no') eq 'no') {
      last;
    }
    my $free = get_free_network();
    configure_bridged_net($free, 'vmnet' . $free);
    show_net_config(1, 0, 0);
  }
  if ($***REMOVED***gAvailEthIf == -1) {
    print wrap ('All your ethernet interfaces are already bridged.'
		. "\n\n", 0);
  }

  ***REMOVED*** NAT networking
  $answer = get_answer('Do you want to be able to use NAT networking '
                       . 'in your virtual machines? (yes/no)', 'yesno', 'yes');

  if ($answer eq 'yes' && count_nat_networks() == 0) {
    configure_nat_net($gDefNat, 'vmnet' . $gDefNat);
  } elsif ($answer  eq 'no') {
    remove_all_networks(0, 0, 1);
  }

  if ($answer eq 'yes') {
    while (1) {
      show_net_config(0, 0, 1);
      if (get_answer('Do you wish to configure another NAT network? '
                     . '(yes/no)', 'yesno', 'no') eq 'no') {
        last;
      }
      my $free = get_free_network();
      configure_nat_net($free, 'vmnet' . $free);
    }
  }

  ***REMOVED*** Host only networking
  $answer = get_answer('Do you want to be able to use host-only networking '
                       . 'in your virtual machines?', 'yesno', $answer);

  if ($answer eq 'yes' && count_hostonly_networks() == 0) {
    configure_hostonly_net($gDefHostOnly, 'vmnet' . $gDefHostOnly, 1);
  } elsif ($answer  eq 'no') {
    remove_all_networks(0, 1, 0);
  }

  if ($answer eq 'yes') {
    while (1) {
      show_net_config(0, 1, 0);
      if (get_answer('Do you wish to configure another host-only network? '
                     . '(yes/no)', 'yesno', 'no') eq 'no') {
        last;
      }
      my $free = get_free_network();
      configure_hostonly_net($free, 'vmnet' . $free, 1);
    }
  }
  if (vmware_product() eq 'wgs') {
     write_netmap_conf();
  }
}

***REMOVED*** Network configuration editor
sub configure_net_editor() {
  my $answer = 'yes';
  my $first_time = 1;
  while ($answer ne 'no') {
    show_net_config(1, 1, 1);

    if (!$first_time) {
      $answer =
        get_persistent_answer('Do you wish to make additional changes to the '
                              . 'current virtual networks settings? (yes/no)',
                              'NETWORK_EDITOR_CHANGE', 'yesno', 'no');
    } else {
      $answer =
        get_persistent_answer('Do you wish to make any changes to the current '
                              . 'virtual networks settings? (yes/no)',
                              'NETWORK_EDITOR_CHANGE', 'yesno', 'no');
      $first_time = 0;
    }
    if ($answer eq 'no') {
      last;
    }

    ***REMOVED*** An empty default answer. We don't run the editor in --default, so
    ***REMOVED*** this is safe.
    my $vHubNr = get_answer('Which virtual network do you wish to configure? '
                            . '(' . $gMinVmnet . '-' . $gMaxVmnet . ')',
                            'vmnet', '');

    if ($vHubNr == $gDefBridged) {
      if (get_answer('The network vmnet' . $vHubNr . ' has been reserved for '
                     . 'a bridged network.  You may change it, but it is '
                     . 'highly recommended that you use it as a bridged '
                     . 'network.  Are you sure you want to modify it? '
                     . '(yes/no)', 'yesno', 'no') eq 'no') {
        next;
      }
    }

    if ($vHubNr == $gDefHostOnly) {
      if (get_answer('The network vmnet' . $vHubNr . ' has been reserved for '
                     . 'a host-only network.  You may change it, but it is '
                     . 'highly recommended that you use it as a host-only '
                     . 'network.  Are you sure you want to modify it? '
                     . '(yes/no)', 'yesno', 'no') eq 'no') {
        next;
      }
    }

    if ($vHubNr == $gDefNat) {
      if (get_answer('The network vmnet' . $vHubNr . ' has been reserved for '
                     . 'a NAT network.  You may change it, but it is highly '
                     . 'recommended that you use it as a NAT network.  Are '
                     . 'you sure you want to modify it? (yes/no)',
                     'yesno', 'no') eq 'no') {
        next;
      }
    }

    my $nettype = 'none';
    if (is_bridged_network($vHubNr)) {
      $nettype = 'bridged';
    } elsif (is_hostonly_network($vHubNr)) {
      $nettype = 'hostonly';
    } elsif (is_nat_network($vHubNr)) {
      $nettype = 'nat';
    }
    $answer = get_answer('What type of virtual network do you wish to set '
                         . 'vmnet' . $vHubNr . '? (bridged,hostonly,nat,none)',
                         'nettype', $nettype);

    if ($answer eq 'bridged') {
      ***REMOVED*** Special case: if we are changing a bridge network to another
      ***REMOVED*** bridge network, we need to make the interface that it used to
      ***REMOVED*** be defined as the correct one again.
      if (is_bridged_network($vHubNr)) {
        add_ethif_info(db_get_answer('VNET_' . $vHubNr . '_INTERFACE'));
      }
      configure_bridged_net($vHubNr, 'vmnet' . $vHubNr);
      ***REMOVED*** Reload available ethernet info in case user does make a change
      load_ethif_info();
    } elsif ($answer eq 'hostonly') {
      configure_hostonly_net($vHubNr, 'vmnet' . $vHubNr, 1);
    } elsif ($answer eq 'nat') {
      configure_nat_net($vHubNr, 'vmnet' . $vHubNr);
    } elsif ($answer eq 'none') {
      remove_net($vHubNr, 'vmnet' . $vHubNr);
    }
  }
  if (vmware_product() eq 'wgs') {
     write_netmap_conf();
  }
}

***REMOVED*** Configure networking automatically with no input from the user, keeping the
***REMOVED*** existing settings.
sub make_all_net() {
  my $vHubNr;
  for ($vHubNr = $gMinVmnet; $vHubNr <= $gMaxVmnet; $vHubNr++) {
    if (is_bridged_network($vHubNr)) {
      my $ethIf = db_get_answer('VNET_' . $vHubNr . '_INTERFACE');
      make_bridged_net($vHubNr, 'vmnet' . $vHubNr, $ethIf);
    } elsif (is_hostonly_network($vHubNr)) {
      my $hostaddr = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR');
      my $netmask = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK');
      my $subnet = db_get_answer_if_exists('VNET_' . $vHubNr . '_HOSTONLY_SUBNET');
      if (not defined($subnet)) {
         $subnet = compute_subnet($hostaddr, $netmask);
      }
      make_hostonly_net($vHubNr, 'vmnet' . $vHubNr, $subnet, $netmask, 1);
    } elsif (is_nat_network($vHubNr)) {
      my $hostaddr = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR');
      my $netmask = db_get_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK');
      my $subnet = db_get_answer_if_exists('VNET_' . $vHubNr . '_HOSTONLY_SUBNET');
      if (not defined($subnet)) {
         $subnet = compute_subnet($hostaddr, $netmask);
      }
      make_nat_net($vHubNr, 'vmnet' . $vHubNr, $subnet, $netmask);
    }
  }
  if (vmware_product() eq 'wgs') {
     write_netmap_conf();
  }
}

***REMOVED*** Counts the number of bridged networks
sub count_bridged_networks {
  return count_networks(1, 0, 0, 0);
}

***REMOVED*** Counts the number of hostonly networks
sub count_hostonly_networks {
  return count_networks(0, 1, 0, 0);
}

***REMOVED*** Counts the number of hostonly networks running samba
sub count_samba_networks {
  return count_networks(0, 1, 0, 1);
}

***REMOVED*** Counts the number of hostonly networks running NAT
sub count_nat_networks {
  return count_networks(0, 0, 1, 0);
}

***REMOVED*** Counts the number of configured virtual networks
sub count_all_networks {
  return count_networks(1, 1, 1, 0);
}

***REMOVED*** Counts the number of virtual networks that have been setup.
***REMOVED*** bridged: Set to indicate a desire to count the number of bridged networks
***REMOVED*** hostonly: Set to indicate a desire to count the number of hostonly networks
***REMOVED*** nat: Set to indicate a desire to count the number of nat networks
***REMOVED*** samba: Set to indicate a desire to count the number of hostonly networks
***REMOVED***        running Samba.
sub count_networks {
  my $bridged = shift;
  my $hostonly = shift;
  my $nat = shift;
  my $samba = shift;

  my $i;
  my $count = 0;
  for ($i = $gMinVmnet; $i <= $gMaxVmnet; $i++) {
    if (is_bridged_network($i) && $bridged) {
      $count++;
    } elsif (is_hostonly_network($i) && $hostonly) {
      if ($samba && is_samba_running($i)) {
        $count++;
      } elsif (!$samba) {
        $count++;
      }
    } elsif (is_nat_network($i) && $nat) {
      $count++;
    }
  }

  return $count;
}

***REMOVED*** Indicates if a virtual network has been defined on this virtual net
sub is_network {
  my $vHubNr = shift;

  return    is_bridged_network($vHubNr)
         || is_hostonly_network($vHubNr)
         || is_nat_network($vHubNr);
}

***REMOVED*** Indicates if a bridged virtual network is defined for a particular vnet
sub is_bridged_network {
  my $vHubNr = shift;
  my $bridged_ethIf = $gDBAnswer{'VNET_' . $vHubNr . '_INTERFACE'};

  return defined($bridged_ethIf);
}

***REMOVED*** Indicates if a hostonly virtual network is defined for a particular vnet
sub is_hostonly_network {
  my $vHubNr = shift;
  my $hostonly_hostaddr = $gDBAnswer{'VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR'};
  my $hostonly_netmask = $gDBAnswer{'VNET_' . $vHubNr . '_HOSTONLY_NETMASK'};
  my $nat_network = $gDBAnswer{'VNET_' . $vHubNr . '_NAT'};

  return    defined($hostonly_hostaddr)
         && defined($hostonly_netmask)
         && not (defined($nat_network) && $nat_network eq 'yes');
}

***REMOVED*** Indicates if a NAT virtual network is defined for a particular vnet
sub is_nat_network {
  my $vHubNr = shift;
  my $nat_hostaddr = $gDBAnswer{'VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR'};
  my $nat_netmask = $gDBAnswer{'VNET_' . $vHubNr . '_HOSTONLY_NETMASK'};
  my $nat_network = $gDBAnswer{'VNET_' . $vHubNr . '_NAT'};

  return    defined($nat_hostaddr)
         && defined($nat_netmask)
         && defined($nat_network) && $nat_network eq 'yes';
}

***REMOVED*** Indicates if the given network collides with an existing network
***REMOVED*** (and if the user is amenable to this)
sub is_good_network {
  my $new_hostaddr = shift;
  my $new_netmask = shift;
  my $new_subnet = compute_subnet($new_hostaddr, $new_netmask);
  my $new_broadcast = compute_broadcast($new_hostaddr, $new_netmask);
  my $vHubNr;

  ***REMOVED*** Get all networks
  ***REMOVED*** We can't use get_used_subnets because we want the broadcast address
  ***REMOVED*** for each subnet as well.
  my @networks = ();
  for ($vHubNr = $gMinVmnet; $vHubNr <= $gMaxVmnet; $vHubNr++) {
    my $hostaddr =
      db_get_answer_if_exists('VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR');
    my $netmask =
      db_get_answer_if_exists('VNET_' . $vHubNr . '_HOSTONLY_NETMASK');
    if (not $hostaddr or not $netmask) {
      next;
    }
    my $subnet = compute_subnet($hostaddr, $netmask);
    my $broadcast = compute_broadcast($hostaddr, $netmask);

    ***REMOVED*** Check for collisions
    ***REMOVED*** Each network is defined by a range from subnet (low-end) to
    ***REMOVED*** broadcast (high-end). Collisions occur when the two ranges overlap.
    if (quaddot_to_int($new_subnet) <= quaddot_to_int($broadcast) &&
        quaddot_to_int($new_broadcast) >= quaddot_to_int($subnet)) {
      push(@networks, 'vmnet' . $vHubNr);
    }
  }

  if (scalar(@networks) != 0) {
    return get_answer(sprintf('The new private network has collided with '
			      . 'existing private %s %s. Are you sure you '
			      . 'wish to add it?', scalar(@networks) == 1 ?
			      'network' : 'networks', join(', ', @networks)),
		      'yesno', 'no');
  }
  return 'yes';
}

***REMOVED*** Indicates if samba is running on a virtual network
sub is_samba_running {
  my $vHubNr = shift;
  my $hostonly = is_hostonly_network($vHubNr);
  my $samba = $gDBAnswer{'VNET_' . $vHubNr . '_SAMBA'};

  return    $hostonly
         && defined($samba) && $samba eq 'yes';
}

***REMOVED*** Gets a free virtual network number.  Gets the lowest number available.
***REMOVED*** Returns -1 on failure.
sub get_free_network {
  my $i;
  for ($i = $gMinVmnet; $i <= $gMaxVmnet; $i++) {
    if (grep($i == $_, @gReservedVmnet)) {
      next;
    }
    if (!is_network($i)) {
      return $i;
    }
  }

  return -1;
}

***REMOVED*** Removes a bridged network
sub remove_bridged_network {
  my $vHubNr = shift;
  my $vHostIf = shift;

  if ($vHubNr < $gMinVmnet || $vHubNr > $gMaxVmnet) {
    return;
  }

  print wrap('Removing a bridged network for vmnet' . $vHubNr . '.' . "\n\n",
             0);
  db_remove_answer('VNET_' . $vHubNr . '_INTERFACE');
  if (vmware_product() eq 'wgs') {
     db_remove_answer('VNET_' . $vHubNr . '_NAME');
  }
  if ($vHubNr >= $gNumVmnet) {
    uninstall_file('/dev/' . $vHostIf);
  }

  ***REMOVED*** Reload the list of available ethernet adapters
  load_ethif_info();
}

***REMOVED*** Removes a hostonly network
sub remove_hostonly_network {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $vmnet_dir = $gRegistryDir . '/' . $vHostIf;

  if ($vHubNr < $gMinVmnet || $vHubNr > $gMaxVmnet) {
    return;
  }

  print wrap('Removing a host-only network for vmnet' . $vHubNr . '.' .
             "\n\n", 0);
  ***REMOVED*** Remove the samba settings
  unmake_samba_net($vHubNr, $vHostIf);

  db_remove_answer('VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR');
  db_remove_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK');
  db_remove_answer('VNET_' . $vHubNr . '_HOSTONLY_SUBNET');
  db_remove_answer('VNET_' . $vHubNr . '_DHCP');
  if (vmware_product() eq 'wgs') {
     db_remove_answer('VNET_' . $vHubNr . '_NAME');
  }
  uninstall_prefix($vmnet_dir);

  if ($vHubNr >= $gNumVmnet) {
    uninstall_file('/dev/' . $vHostIf);
  }
}

***REMOVED*** Removes a NAT network
sub remove_nat_network {
  my $vHubNr = shift;
  my $vHostIf = shift;
  my $vmnet_dir = $gRegistryDir . '/' . $vHostIf;

  if ($vHubNr < $gMinVmnet || $vHubNr > $gMaxVmnet) {
    return;
  }

  print wrap('Removing a NAT network for vmnet' . $vHubNr . '.' . "\n\n", 0);

  db_remove_answer('VNET_' . $vHubNr . '_NAT');
  db_remove_answer('VNET_' . $vHubNr . '_HOSTONLY_HOSTADDR');
  db_remove_answer('VNET_' . $vHubNr . '_HOSTONLY_NETMASK');
  db_remove_answer('VNET_' . $vHubNr . '_HOSTONLY_SUBNET');
  db_remove_answer('VNET_' . $vHubNr . '_DHCP');
  if (vmware_product() eq 'wgs') {
     db_remove_answer('VNET_' . $vHubNr . '_NAME');
  }
  uninstall_prefix($vmnet_dir);

  if ($vHubNr >= $gNumVmnet) {
    uninstall_file('/dev/' . $vHostIf);
  }
}

***REMOVED*** Removes a network
sub remove_net {
  my $vHubNr = shift;
  my $vHostIf = shift;
  if (is_bridged_network($vHubNr)) {
    remove_bridged_network($vHubNr, $vHostIf);
  } elsif (is_hostonly_network($vHubNr)) {
    remove_hostonly_network($vHubNr, $vHostIf);
  } elsif (is_nat_network($vHubNr)) {
    remove_nat_network($vHubNr, $vHostIf);
  }
}

***REMOVED*** Removes all networks on the system subject to the following
***REMOVED*** types
sub remove_all_networks {
  my $bridged = shift;
  my $hostonly = shift;
  my $nat = shift;
  my $i;

  for ($i = $gMinVmnet; $i <= $gMaxVmnet; $i++) {
    if (is_network($i)) {
      if ($bridged && is_bridged_network($i)) {
        remove_bridged_network($i, 'vmnet' . $i);
      }
      if ($hostonly && is_hostonly_network($i)) {
        remove_hostonly_network($i, 'vmnet' . $i);
      }
      if ($nat && is_nat_network($i)) {
        remove_nat_network($i, 'vmnet' . $i);
      }
    }
  }
}

***REMOVED*** Loads ethernet interface info into global variable
sub load_all_ethif_info() {
  ***REMOVED*** Get the list of available ethernet interfaces
  ***REMOVED*** The -a is important because it lists all interfaces (not only those
  ***REMOVED*** which are up).  The vmnet driver knows how to deal with down interfaces.
  open(IFCONFIG, 'LC_ALL=C ' . shell_string($gHelper{'ifconfig'}) . ' -a |');
  @gAllEthIf = ();
  while (<IFCONFIG>) {
    if (/^(\S+)\s+Link encap:Ethernet/) {
      my @fields;

      @fields = split(/[ ]+/);
      push(@gAllEthIf, $fields[0]);
    }
  }
  close(IFCONFIG);
}

***REMOVED*** Determines the available ethernet interfaces
sub load_ethif_info() {
  ***REMOVED*** Get the list of available ethernet interfaces by checking the all
  ***REMOVED*** list and removing the ones that have already been allocated.
  @gAvailEthIf = ();

  my @usedEthIf = grep(/^VNET_\d+_INTERFACE$/, keys(%gDBAnswer));
  @usedEthIf = map($gDBAnswer{$_}, @usedEthIf);

  my $eth;
  foreach $eth (@gAllEthIf) {
    if (!grep($_ eq $eth, @usedEthIf)) {
      push(@gAvailEthIf, $eth);
    }
  }
}

***REMOVED*** Adds an ethernet interface to the working list of ethernet interfaces
sub add_ethif_info {
  my $eth = shift;
  push(@gAvailEthIf, $eth);
}

***REMOVED*** Write out the netmap.conf file
sub write_netmap_conf {
  if (not open(CONF, '>' . $cNetmapConf)) {
     print STDERR wrap("Unable to update the network configuration file.\n", 0);
     return;
  }

  print CONF "***REMOVED*** This file is automatically generated.\n";
  print CONF "***REMOVED*** Hand-editing this file is not recommended.\n";
  print CONF "\n";

  my %nameMap = ();
  my $i = 0;
  my $vHubNr;
  for ($vHubNr = $gMinVmnet; $vHubNr <= $gMaxVmnet; $vHubNr++) {
     my $dbKey = 'VNET_' . $vHubNr . '_NAME';
     my $name = db_get_answer_if_exists($dbKey);
     if (defined($name)) {
        my $device = 'vmnet' . $vHubNr;

        ***REMOVED*** Check for duplicate names
        if (defined($nameMap{$name})) {
           my $id = 1;
           my $newName;
           do {
              $id++;
              $newName = $name . ' (' . $id . ')';
           } while (defined($nameMap{$newName}));
           print STDERR wrap('Network name "' . $name . '" for ' . $device .
                             ' is already in use by ' . $nameMap{$name} .
                             ' -- renaming to "' . $newName . '"' . "\n", 0);
           db_add_answer($dbKey, $newName);
           $name = $newName;
        }
        $nameMap{$name} = $device;
        print CONF 'network' . $i . '.name = "' . $name . '"' . "\n";
        print CONF 'network' . $i . '.device = "' . $device . '"' . "\n";
        $i++;
     }
  }

  close(CONF);
}

***REMOVED*** Create the links for VMware's services on a Solaris system
sub link_services_solaris {
   my $service = shift;
   my $S_level = shift;
   my $K_level = shift;
   my @S_runlevels = ('2');
   my @K_runlevels = ('0', '1', 'S');
   my $runlevel;

   foreach $runlevel (@S_runlevels) {
     install_symlink(db_get_answer('INITSCRIPTSDIR') . '/' . $service,
                     db_get_answer('INITDIR') . '/rc' . $runlevel
                     . '.d/S' . $S_level . $service);
   }

   foreach $runlevel (@K_runlevels) {
     install_symlink(db_get_answer('INITSCRIPTSDIR') . '/' . $service,
                     db_get_answer('INITDIR') . '/rc' . $runlevel
                     . '.d/K' . $K_level . $service);
   }
}

***REMOVED*** Write the VMware host-wide configuration file
sub write_vmware_config {
  my $name;
  my $backupName;
  my $promoconfig;

  $name = $gRegistryDir . '/config';
  $backupName = $gStateDir . '/config';

  my $config = new VMware::Config;
  ***REMOVED*** First read in old config backed up from last uninstallation.
  if (file_name_exist($name)) {
    if (!$config->readin($name)) {
      error('Unable to read configuration file "' . $name . '".' . "\n\n");
    }
    db_remove_file($name);
  }

  my $bindir = db_get_answer('BINDIR');
  my $libdir = db_get_answer('LIBDIR');
  my $sbindir = db_get_answer('SBINDIR');

  $config->set('bindir', $bindir);

  ***REMOVED*** Here we set some defaults for guest.commands.*
  ***REMOVED*** The ->get with default is how we are sure to only change if it isn't
  ***REMOVED*** already set
  $config->set('guest.commands.enabledOnHost',
               $config->get('guest.commands.enabledOnHost','TRUE'));
  $config->set('guest.commands.allowAnonGuestCommandsOnHost',
               $config->get('guest.commands.allowAnonGuestCommandsOnHost',
                            'FALSE'));
  $config->set('guest.commands.allowAnonRootGuestCommandsOnHost',
               $config->get('guest.commands.allowAnonRootGuestCommandsOnHost',
                            'FALSE'));
  $config->set('guest.commands.anonGuestUserNameOnHost',
               $config->get('guest.commands.anonGuestUserNameOnHost',''));
  $config->set('guest.commands.anonGuestPasswordOnHost',
               $config->get('guest.commands.anonGuestPasswordOnHost',''));

  $config->set('vmware.fullpath', $bindir . '/vmware');
  $config->set('dhcpd.fullpath', $bindir . '/vmnet-dhcpd');
  $config->set('loop.fullpath', $bindir . '/vmware-loop');
  $config->set('control.fullpath', $bindir . '/vmware-cmd');
  $config->set('authd.fullpath', $sbindir . '/vmware-authd');
  $config->set('libdir', $libdir);
  $config->set('product.name', vmware_product_name());
  ***REMOVED*** Vix needs to know what version of workstation or server
  ***REMOVED*** it is installed with, even for dev builds.  So add it
  ***REMOVED*** here as an extra variable and vmware_version() wil return
  ***REMOVED*** its usual values.  Also, this allows other makefiles to
  ***REMOVED*** remain untouched.
  if ((vmware_product() eq 'ws') || (vmware_product() eq 'wgs')) {
    $config->set('product.version', '@@VERSIONNUMBER_FOR_VIX@@');
  } else {
    $config->set('product.version', '8.6.14');
  }
  $config->set('product.buildNumber', '1976090');

  if ((vmware_product() eq 'wgs') || (vmware_product() eq 'server')) {
      $config->set('authd.client.port', db_get_answer('AUTHDPORT'));
  }
  if (vmware_product() eq 'wgs') {
    ***REMOVED*** XXX This part of the wizard needs some refinement:
    ***REMOVED***     -- Let users specify the datastore name
    ***REMOVED***     -- Provide a means of preserving existing datastores
    ***REMOVED***     -- Come up with a better default name than "standard"
    my $answer;
    $answer = get_persistent_answer('In which directory do you want to keep your '
				    . 'virtual machine files?', 'VMDIR', 'dirpath',
				    '/var/lib/vmware/Virtual Machines');
    create_dir($answer, $cFlagDirectoryMark);
    $config->set('vmdir', $answer);
    safe_chmod(01777, $answer);
    write_datastore_config('standard', $answer);
  }
  my $vHubNr;
  for ($vHubNr = $gMinVmnet; $vHubNr <= $gMaxVmnet; $vHubNr++) {
    if (is_hostonly_network($vHubNr)) {
      my $hostaddr = db_get_answer('VNET_' . $vHubNr  . '_HOSTONLY_HOSTADDR');
      my $netmask = db_get_answer('VNET_' . $vHubNr  . '_HOSTONLY_NETMASK');
      ***REMOVED*** Used by the Linux wizard to determine if a hostonly network is
      ***REMOVED*** configured.
      $config->set('vmnet' . $vHubNr . '.HostOnlyAddress', $hostaddr);
      $config->set('vmnet' . $vHubNr . '.HostOnlyNetMask', $netmask);
    } else {
      $config->remove('vmnet' . $vHubNr . '.HostOnlyAddress');
      $config->remove('vmnet' . $vHubNr . '.HostOnlyNetMask');
    }
  }
  ***REMOVED*** Used by the Linux wizard to determine if Samba is configured on the
  ***REMOVED*** hostonly network.
  $config->remove('smbpasswd.fullpath');

  if ((vmware_product() eq 'wgs') || (vmware_product() eq 'server')) {
    $config->set('authd.proxy.vim', 'vmware-hostd:hostd-vmdb');
    $config->set('authd.proxy.nfc', 'vmware-hostd:ha-nfc');
    $config->set('authd.soapServer', 'TRUE');
  }

  $config->remove('serverd.fullpath');
  $config->remove('serverd.init.fullpath');

  if (!$config->writeout($name)) {
    error('Unable to write configuration file "' . $name . '".' . "\n\n");
  }
  db_add_file($name, $cFlagTimestamp | $cFlagConfig);
  safe_chmod(0644, $name);

  ***REMOVED*** Append the promotional configuration if it exists
  $promoconfig = $libdir . '/configurator/PROMOCONFIG';
  if (-e $promoconfig) {
    my %patch;

    undef %patch;
    internal_sed($promoconfig, $name, 1, \%patch);
  }

  if (!-d $gStateDir) {
    create_dir($gStateDir, 0x1);
  }
  system(shell_string($gHelper{'cp'}) . " " . $name . " " . $backupName);
}

***REMOVED*** Write the VMware datastore configuration file
sub write_datastore_config {
  my %patch = ();
  $patch{'***REMOVED******REMOVED***{DS_NAME}***REMOVED******REMOVED***'} = shift;
  $patch{'***REMOVED******REMOVED***{DS_PATH}***REMOVED******REMOVED***'} = shift;

  my $start_file = $gRegistryDir . '/hostd/datastores-template.xml';
  install_template_file($start_file, \%patch, 1);
}

***REMOVED*** This is used for a VMware dictionary-compatible configuration file.
***REMOVED*** Newer tools use glib-style ini files which appLoader doesn't grok
***REMOVED*** through the dictionary functions.
sub write_new_tools_config() {
  my $name = $gRegistryDir . '/config';
  my $config = new VMware::Config;

  ***REMOVED*** First read in old config backed up from last uninstallation.
  if (file_name_exist($name)) {
      $config->readin($name);
  }

  $config->set('libdir', db_get_answer('LIBDIR'));

  if (!$config->writeout($name)) {
    error('Unable to write configuration file "' . $name . '".' . "\n\n");
  }

  db_add_file($name, $cFlagTimestamp);
  safe_chmod(0644, $name);
}

***REMOVED*** Write the VMware tools configuration file
sub write_tools_config {
  my $name;
  my $backupName;

  $name = $gRegistryDir . '/tools.conf';
  $backupName = $gStateDir . '/tools.conf';

  my $config = new VMware::Config;
  ***REMOVED*** First read in old config backed up from last uninstallation.
  if (file_name_exist($backupName)) {
    if (!$config->readin($backupName)) {
      error('Unable to read configuration file "' . $backupName . '".' . "\n\n");
    }
    db_remove_file($backupName);
  }

  $config->set('helpdir', db_get_answer('LIBDIR') . "/hlp");
  $config->set('libdir', db_get_answer('LIBDIR'));
  my $mountPoint = db_get_answer_if_exists('HGFS_MOUNT_POINT');
  if ($mountPoint) {
      $config->set('mount-point', $mountPoint);
  }

  if (!$config->writeout($name)) {
    error('Unable to write configuration file "' . $name . '".' . "\n\n");
  }
  db_add_file($name, $cFlagTimestamp);
  safe_chmod(0644, $name);

  write_new_tools_config();
}

***REMOVED*** Display the PROMOCODE information
sub show_PROMOCODE {
  my $promocode;

  $promocode = db_get_answer('DOCDIR') . '/PROMOCODE';
  if (-e $promocode) {
    ***REMOVED*** $gHelper{'more'} is already a shell string
    system($gHelper{'more'} . ' ' . shell_string($promocode));
    print "\n";
  }
}

***REMOVED*** If needed, allow the sysadmin to unlock a site wide license. This must be
***REMOVED*** called _after_ VMware's config file has been written
sub check_license {
  my $want_sn;
  my $sn;

  if (system(shell_string(vmware_vmx_app_name())
             . ' --can-run')) {
    $want_sn = 'yes';
  } else {
    for (;;) {
      $want_sn = get_answer('Do you want to enter a serial number now? '
                            . '(yes/no/help)', 'yesnohelp', 'no');
      if (not ($want_sn eq 'help')) {
        last;
      }

      print wrap('Answer "yes" if you have received a new serial number. '
                 . 'Otherwise answer "no", and ' . vmware_product_name()
                 . ' will continue to run just fine.' . "\n\n", 0);
    }
  }

  if ($want_sn eq 'yes') {
    $sn = '';
    while ($sn eq '') {
      $sn = get_answer("Please enter your 20-character serial number.\n\n"
		       . "Type XXXXX-XXXXX-XXXXX-XXXXX or 'Enter' to cancel: ",
		       'serialnum', '');
      if ($sn eq ' ') {
	print wrap ('You cannot power on any virtual machines until you enter a '
		    . 'valid serial number. To enter the serial number, run this '
		    . 'configuration program again. '
		    . "\n\n", 0);
      } elsif (system(shell_string(vmware_vmx_app_name()) . ' --new-sn ' . $sn) != 0) {
	print wrap('The serial number ' . $sn . ' is invalid.' . "\n\n", 0);
        $sn = '';
      }
    }
  }
}


***REMOVED***
***REMOVED*** Determines the status of the given module in question.  The returned status
***REMOVED*** is one of the following...
***REMOVED***
***REMOVED*** not_installed       - module is not installed.
***REMOVED*** installed_by_vmware - the module is not upstreamed and vmware has installed this module.
***REMOVED*** clobbered_by_vmware - the module is upstreamed but clobbered by vmware one.
***REMOVED*** installed_by_other  - someone else has installed this module.
***REMOVED*** not_configured      - We installed it, but its not marked as configured
***REMOVED*** compiled_in         - Module has been compiled into the running kernel.
***REMOVED***
sub get_module_status {
  my $mod = shift;

  ***REMOVED*** If it's in this list, we didn't put it there.
  if (defined $gNonVmwareModules{"$mod"}) {
     return 'installed_by_other';
  }

  ***REMOVED*** So its not in the list.  If its configured, then we installed it.  Otherwise
  ***REMOVED*** it isn't installed (it may be, but since it's not configured we will not
  ***REMOVED*** count it as being installed).
  my $modConfKey = uc("$mod") . '_CONFED';
  if (defined $gVmwareInstalledModules{"$mod"}) {
     if (defined db_get_answer_if_exists($modConfKey) and
         db_get_answer($modConfKey) eq 'yes') {
        if ($gVmwareInstalledModules{"$mod"} =~ m,updates/vmware,) {
           return 'clobbered_by_vmware';
        } else {
           return 'installed_by_vmware';
        }
     } else {
        return 'not_configured';
     }
  }

  ***REMOVED*** Finally check if the module exists in /sys/modules.  If its there but no
  ***REMOVED*** module has been detected on the system and the module can't be found in
  ***REMOVED*** the output of lsmod, then we assume the module has been compiled in.
  if (defined $gVmwareRunningModules{"$mod"}) {
     my $lsmodOut = `lsmod`;
     if (not ($lsmodOut =~ m/$gVmwareRunningModules{"$mod"}/)) {
         return 'compiled_in';
     }
  }

  return 'not_installed';
}


***REMOVED***
***REMOVED*** Returns the file name of the module on the system.
***REMOVED***
***REMOVED*** Since upstreaming, our module names are not gauranteed to stay the same.
***REMOVED*** This function takes a module name and translates it to the name of the
***REMOVED*** module as modprobe would see it.
***REMOVED***
sub get_module_name {
  my $mod = shift;
  my $modName = "$mod";
  my $modStatus = get_module_status($mod);

  if ($modStatus eq 'installed_by_other') {
    if ($gNonVmwareModules{"$mod"} =~ m,.*/([\w\.\-]+)\.k?o,) {
      $modName = $1;
    }
  } elsif ($modStatus eq 'installed_by_vmware' or $modStatus eq 'clobbered_by_vmware') {
    if ($gVmwareInstalledModules{"$mod"} =~ m,.*/([\w\.\-]+)\.k?o,) {
      $modName = $1;
    }
  }

  return $modName;
}


***REMOVED***
***REMOVED*** Sets the install destination for a module based on whether or not
***REMOVED*** the module is already installed on the system.
***REMOVED***
***REMOVED*** If the module is not already on the system, put it in misc.
***REMOVED*** Otherwise it needs to go in the updates folder so depmod chooses
***REMOVED*** it over any other modules in the system.
***REMOVED***
sub get_module_install_dest {
  my $mod = shift;
  my $modStatus = get_module_status($mod);
  my $dest = "misc";

  if ($modStatus eq 'installed_by_other' or $modStatus eq 'clobbered_by_vmware') {
    $dest = "updates/vmware"
  } elsif ($modStatus eq 'installed_by_vmware' and
           defined $gVmwareInstalledModules{"$mod"}) {
    ***REMOVED*** We need to check where we installed the module.
    if ($gVmwareInstalledModules{"$mod"} =~
        m,/lib/modules/$gSystem{'uts_release'}/(.+)/[\w\.\-]+\.k?o,) {
      $dest = $1;
    }
  }

  return $dest;
}


***REMOVED***
***REMOVED*** Checks to see if we should install the given module.
***REMOVED***
***REMOVED*** Returns yes if we should install the module, no otherwise.
***REMOVED***
sub mod_pre_install_check {
  my $mod = shift;
  my $modStatus = get_module_status($mod);
  my $clobberKMod = $gOption{'clobberKernelModules'}{"$mod"};

  if ($modStatus eq 'compiled_in') {
     ***REMOVED*** Then we better not even try to install the module
     print wrap("The module $mod has been compiled into the kernel " .
                "and cannot be managed by VMware tools.\n", 0);
     return 'no';
  }

  if ($modStatus eq 'installed_by_other') {
    if (defined $clobberKMod and $clobberKMod eq 'yes') {
      print wrap("The module $mod has already been installed on this " .
		 "system by another package but has been marked for " .
		 "clobbering and will be overridden.\n\n", 0);
      return 'yes';
    } else {
      print wrap("The module $mod has already been installed on this " .
		 "system by another installer or package " .
		 "and will not be modified by this installer.  " .
		 "Use the flag --clobber-kernel-modules=$mod " .
		 "to override.\n\n", 0);
      return 'no';
    }
  }

  ***REMOVED*** If we get here, then the module is either not installed or was
  ***REMOVED*** installed by us.  Hence we should install the module.
  return 'yes';
}


***REMOVED***
***REMOVED*** Reinstalls the module after passing some basic sanity checks.
***REMOVED***
sub reinstall_module {
  my $mod = shift;
  my $modConfKey = uc("$mod") . '_CONFED';
  my $result = db_get_answer_if_exists($modConfKey);

  if (defined $result and $result eq 'yes') {
    ***REMOVED*** Then the module was installed by us and can be reinstalled by us.
    configure_module($mod);
    module_ramdisk_check($mod);
  } else {
    print wrap("Skipping $mod since it was not installed " .
               "and configured by VMware.\n\n\n", 0);
  }

  return;
}


***REMOVED***
***REMOVED*** Checks if the given module needs to be added to the ramdisk and
***REMOVED*** adds it if it does.
***REMOVED***
sub module_ramdisk_check {
  my $mod = shift;
  my $answer = $cRamdiskKernelModules{"$mod"};
  my $modStatus = get_module_status("$mod");

  if (defined $answer and "$answer" eq 'yes' and
      "$modStatus" ne 'not_installed' and
      "$modStatus" ne 'compiled_in') {
    push (@gRamdiskModules, "$mod");
  }
}


***REMOVED*** Display a usage error message for the configuration program and exit
sub config_usage {
  my $long_name = vmware_longname();
  my $prog_name = internal_basename($0);
  my $usage = <<EOF;
$long_name configurator.
Usage: $prog_name [OPTION]...

Options
  -d, --default               Automatically answer questions with the
                              proposed answer.

  -c, --compile               Force the compilation of kernel modules.

  -p, --prebuilt              Force the use of pre-built kernel modules.

      --preserve              Always preserve user-modified configuration
                              files.

      --overwrite             Always overwrite user-modified configuration
                              files.

  -m, --modules-only          Only rebuild/install kernel modules and skip
                              all other configuration steps (including
                              system configuration for the kernel modules).

                              NOTE:  This flag will only work after the system
                                     has been configured to work with the VMware
                                     kernel modules at least once.

  -k, --kernel-version <version>
                              Build/install modules for the specified kernel
			      version.  Implies --compile and --modules-only.

      --clobber-kernel-modules=<module1,module2,...>
	                      Overrides any VMware related modules installed
                              by other installers or provided by your distro
                              and installs the modules provided by this
                              installer.  This is a comma seperated list
                              of modules.

      --clobber-xorg-modules  Skips the Xorg module version comparison tests
                              and installs the VMware shipped Xorg modules.


Command line arguments:  The acceptable characters are:
   The letters A, B, C, ...
   The letters a, b, c, ...
   The numbers 0, 1, 2, ...
   and the special characters '_', '-', ',' and '='.

EOF

  print STDERR $usage;
  exit 1;
}

***REMOVED*** Return GSX or ESX for server products, Workstation for ws
sub installed_vmware_version {
  my $vmware_version;
  my $vmware_version_string;

  if (not defined($gHelper{"vmware"})) {
    $gHelper{"vmware"} = DoesBinaryExist_Prompt("vmware");
    if ($gHelper{"vmware"} eq '') {
      error('Unable to continue.' . "\n\n");
    }
  }

  $vmware_version_string = direct_command(shell_string($gHelper{"vmware"})
                                          . ' -v 2>&1 < /dev/null');
  if ($vmware_version_string =~ /.*VMware\s*(\S+)\s*Server.*/) {
    $vmware_version = $1;
  } else {
    $vmware_version = "Workstation";
  }
  return $vmware_version;
}

***REMOVED*** switch_to_guest
***REMOVED*** Sets links on configuration files we changed during configuration.
***REMOVED*** If switch_to_host was never called, do nothing.
sub switch_to_guest {
  my %filesBackedUp;
  my $file;

  if (!defined(db_get_answer_if_exists($cSwitchedToHost))) {
    return;
  }

  %filesBackedUp = db_get_files_to_restore();

  foreach $file (keys %filesBackedUp) {
    if (-l $file) {
      if (check_link($file, $file . db_get_answer($cSwitchedToHost)) eq 'yes') {
        return;
      }
      unlink $file;
      symlink $file . db_get_answer($cSwitchedToHost), $file;
    }
  }
}

***REMOVED*** switch_to_host
***REMOVED*** Saves configuration files we changed during configuration.
***REMOVED*** Sets links on configuration files we backed up during configuration.
sub switch_to_host {
  my $configuredExtension = '.AfterVMwareToolsInstall';
  my %filesBackedUp;
  my $file;

  if (!defined(db_get_answer_if_exists($cSwitchedToHost))) {
    db_add_answer($cSwitchedToHost, $configuredExtension);
  }

  %filesBackedUp = db_get_files_to_restore();

  foreach $file (keys %filesBackedUp) {
    if (-l $file) {
      if (check_link($file, $filesBackedUp{$file}) eq 'yes') {
        return;
      }
      unlink $file;
    } else {
      my %patch;
      undef %patch;
      install_file($file, $file . $configuredExtension, \%patch,
                   $cFlagTimestamp);
      unlink $file;
      ***REMOVED*** The link might change, do not keep the timestamp.
      db_add_file($file, 0);
    }
    symlink $filesBackedUp{$file}, $file;
  }
}

***REMOVED*** update LIBDIR/libconf/etc/fonts/fonts.conf with system font dirs.  Take
***REMOVED*** just after its first <dir> entry.  This does not yet handle commented out
***REMOVED*** <dir> elements and assumes that <dir> elements are grouped together in
***REMOVED*** the same heading.
***REMOVED***
***REMOVED*** XXX Document return value(s).
***REMOVED***
sub configure_fonts_dot_conf {
   my $tmp_dir = make_tmp_dir("vmware-fonts");

   my $sys_font_path = "/etc/fonts/fonts.conf";
   if (! -f $sys_font_path) {
      ***REMOVED*** This means fontconfig was not installed/configured. In this case,
      ***REMOVED*** ensure that we look for the font directory/directories ourselves
      ***REMOVED*** and add their location to a temporary replacement for fonts.conf.
      $sys_font_path = $tmp_dir . '/system_fonts.conf';
      open(SYSFONT, ">" . $sys_font_path)
         || error "Error opening " . $sys_font_path . "\n";
      my $fonts_found = 0;
      foreach my $location (@gSuspectedFontLocations) {
         if (-d $location) {
            $fonts_found = 1;
            print SYSFONT "<dir>", $location, "</dir>\n";
         }
      }
      close(SYSFONT);
      if ($fonts_found == 0) {
         ***REMOVED*** We were unable to find any fonts.  Just quit.
         return;
      }
   }

   my ($font_line, $sys_line);
   my $font_path = db_get_answer('LIBDIR') . "/libconf/etc/fonts/fonts.conf";
   my $tmp_file = $tmp_dir . '/fonts.conf';

   open(MYFONT, "<" . $font_path)
      || error "Error opening " . $font_path . "\n";
   open(SYSFONT, "<" . $sys_font_path)
      || error "Error opening " . $sys_font_path . "\n";
   open(OUTFONT, ">" . $tmp_file)
      || error "Error opening " . $tmp_file . "\n";

   ***REMOVED*** Read from our fonts.conf until reach a <dir> line.  Skip the dir.
   ***REMOVED*** We'll dump our '<dir>' lines and use the system's.
   while ($font_line = <MYFONT>) {
      if ($font_line =~ /Font\s+directory\s+list/) {
         print OUTFONT $font_line;
         ***REMOVED*** for readability, add a line to separate the above line from the
	 ***REMOVED*** following <dir> lines.
         print OUTFONT "\n";
         last;
      }
      if ($font_line =~ /<dir>/) {
         ***REMOVED*** Use the first '<dir>' as a marker for inserting the new '<dir>'
         ***REMOVED*** lines.
         last;
      }
      print OUTFONT $font_line;
   }

   ***REMOVED*** Write out only <dir> lines.
   while ($sys_line = <SYSFONT>) {
      if ($sys_line !~ /<dir>/) {
         next;
      }
      print OUTFONT $sys_line;
   }

   ***REMOVED*** Finally finish up copying our fonts.conf into the tmp file.
   while ($font_line = <MYFONT>) {
      if ($font_line =~ /<dir>/) {
         next;
      }
      print OUTFONT $font_line;
   }

   close(SYSFONT);
   close(MYFONT);
   close(OUTFONT);

   system(shell_string($gHelper{'cp'}) . " " . $tmp_file . " " . $font_path);
   remove_tmp_dir($tmp_dir);
}

***REMOVED*** Tools configurator
sub configure_tools {
  my $vmwareToolsScript = vmware_product() eq 'tools-for-freebsd' ?
                          '/vmware-tools.sh' : '/vmware-tools';

  if ($gSystem{'invm'} eq 'no') {
    error('This configuration program is to be executed in a '
               . 'virtual machine.' . "\n\n");
  }

  ***REMOVED***
  ***REMOVED*** Stop VMware's services
  ***REMOVED*** Also hand-remove vmxnet/vmxnet3 since it is no longer done in services.sh
  ***REMOVED*** However, do not fail on failing to rmmod as there are plenty of
  ***REMOVED*** totally reasonable cases where this might happen.
  ***REMOVED***
  print "\n";
  ***REMOVED*** NOTE: See bug 349327.  We no longer want to interrupt networking during
  ***REMOVED*** tools configuration.
  ***REMOVED***if (!$gOption{'skip-stop-start'}) {
  ***REMOVED***    kmod_unload('vmxnet', 0);
  ***REMOVED***    if (vmware_product() eq 'tools-for-solaris') {
  ***REMOVED***      kmod_unload('vmxnet3s', 0);
  ***REMOVED***    } else {
  ***REMOVED***      kmod_unload('vmxnet3', 0);
  ***REMOVED***    }
  ***REMOVED***}
  if (!$gOption{'skip-stop-start'}) {
    my $stopCode = 0;
    print wrap('Making sure services for ' . vmware_product_name()
                . ' are stopped.' . "\n\n", 0);

    if (db_get_answer_if_exists('UPSTARTJOB')) {
      my $str = vmware_service_issue_command($cServiceCommandDirect, 'status');

      if ($? == 0 and not $str =~ /stop\/waiting/) {
        vmware_service_issue_command($cServiceCommandSystem, 'stop');
        $stopCode = $?;
      }
    } else {
      vmware_service_issue_command($cServiceCommandSystem, 'stop');
      $stopCode = $?;
    }

    if ($stopCode != 0) {
      error('Unable to stop services for ' . vmware_product_name() . "\n\n");
    }
  }
  print "\n\n";

  if (!$gOption{'modules_only'}) {
    if (vmware_product() eq 'tools-for-linux' and not
        db_get_answer_if_exists('UPSTARTJOB')) {
      ***REMOVED*** We want to be before networking (because we load network modules).
      ***REMOVED*** Being before syslog would be nice, but syslog sometimes starts
      ***REMOVED*** after networking, hence this is not possible.
      ***REMOVED*** Note: Ensure that these numbers are in sync with the LSB/chkconfig
      ***REMOVED***       entries at the top of bora/install/tar/pkg_mgr.pl
      if (distribution_info() eq "debian") {
	link_services('vmware-tools', '38', '36');
      } else {
	link_services('vmware-tools', '03', '99');
      }
    } elsif (vmware_product() eq 'tools-for-solaris') {
      link_services_solaris('vmware-tools', '05', '65');
    }

    if (vmware_product() eq 'tools-for-freebsd') {
      configure_module_bsd('vmxnet');
      configure_module_bsd('vmxnet3');
    } elsif (vmware_product() eq 'tools-for-solaris') {
      configure_module_solaris('vmxnet');
      configure_module_solaris('vmxnet3s');
    }

   ***REMOVED*** configure the Linux-only drivers
   ***REMOVED*** Ensure that vmci gets configured before vsock and vmhgfs
   ***REMOVED*** as they both depend on vmci
   if ( vmware_product() eq 'tools-for-linux') {
      configure_vmsync();
      configure_vmci();
      configure_vsock();
      configure_vmxnet3();
      configure_pvscsi();
   }

    configure_vmmemctl();
    configure_vmhgfs();
    write_module_config();
    configure_vmblock();

    if (vmware_product() eq 'tools-for-linux') {
      configure_ld_dot_so();
      configure_thinprint();
      if (pulseNeedsTimerBasedAudioDisabled()) {
	 pulseDisableTimerBasedAudio();
	 print "\nDisabling timer-based audio scheduling in pulseaudio.\n\n";
      }
    }

    configure_X();
    configure_autostart();

    ***REMOVED*** Configure autostart for vmware-user
    if (vmware_product() eq 'tools-for-freebsd') {
      configure_pango();
      configure_gdk_pixbuf();
    }

    if ( vmware_product() eq 'tools-for-linux') {
       configure_udev_scsi();
    }
  } else {
    ***REMOVED*** Only re-installs modules.
    ***REMOVED*** Right now, this is linux-only, not sure it even makes sense for other OS.

    reinstall_module('vmmemctl');
    reinstall_module('vmhgfs');
    reinstall_module('vmxnet');
    reinstall_module('vmxnet3');
    reinstall_module('vmblock');
    reinstall_module('vmci');
    reinstall_module('vsock');
    reinstall_module('pvscsi');

    ***REMOVED*** configure the experimental drivers
    reinstall_module('vmsync');

    ***REMOVED*** configure the experimental vmwgfx drivers
    reinstall_module('vmwgfx');

  }

  ***REMOVED*** Build dependency data for the new modules so that modprobe can find them.
  ***REMOVED*** Even though the Tools services script uses insmod and thus doesn't care for
  ***REMOVED*** module dependencies, it makes more sense for the dependencies to be rebuilt
  ***REMOVED*** prior to any module use.
  ***REMOVED***
  ***REMOVED*** Note: You have to do this before rebuilding the ramdisk.  Otherwise some
  ***REMOVED***       distros (SLES) will complain.
  if (vmware_product() eq 'tools-for-linux' and
      system(join(' ', $gHelper{'depmod'}, getKernRel())) != 0 ) {
     print wrap("Warning: depmod exited with a non-zero status.\n", 0);
  }

  ***REMOVED*** Rebuild the RamDisk here so new modules are included during the install
  ***REMOVED*** process and the module-only process.
  if ( vmware_product() eq 'tools-for-linux') {
    configure_kernel_initrd();
  }

  ***REMOVED*** Write the config file, but not the tools.conf file. That file
  ***REMOVED*** is for the tools people only and we shouldn't be messing with it.
  write_new_tools_config();

  uninstall_file($gConfFlag);

  ***REMOVED*** We don't ship libconf for Solaris, so we don't need to change the
  ***REMOVED*** fonts.conf being used.
  if (vmware_product() ne 'tools-for-solaris') {
    configure_fonts_dot_conf();
  }

  ***REMOVED***
  ***REMOVED*** Then start VMware's services.
  if (!$gOption{'skip-stop-start'}) {
    vmware_service_issue_command($cServiceCommandSystem, 'start');
    if ($? != 0) {
      error('Unable to start services for ' . vmware_product_name() . "\n\n");
    }
  }

  print wrap('The configuration of ' . vmware_longname() . ' for this running '
             . 'kernel completed successfully.' . "\n\n", 0);
  ***REMOVED*** Remind Solaris users currently using the Xsun server to switch to Xorg
  if (vmware_product() eq 'tools-for-solaris' &&
      solaris_10_or_greater() eq 'yes' &&
      direct_command(shell_string($gHelper{'svcprop'}) . ' -p options/server '
                     . 'application/x11/x11-server') =~ /Xsun/) {
    print wrap('You must restart your X session under the Xorg X server before '
               . 'any mouse or graphics changes take effect.  Remember to run '
               . 'kdmconfig(1M) as root to switch from the Xsun server to the '
               . 'Xorg server.' . "\n\n", 0);
  } else {
    print wrap('You must restart your X session before any mouse or graphics changes '
               . 'take effect.' . "\n\n", 0);
  }
  print wrap('You can now run ' . vmware_product_name() . ' by invoking "'
	     . vmware_tools_cmd_app_name() . '" from the command line or by '
	     . 'invoking "' . vmware_tools_app_name() . '" from the command line '
	     . "during an X server session.\n\n",0);

  my $bindir = db_get_answer('BINDIR');
  if (vmware_product() eq 'tools-for-linux') {
    print wrap('To enable advanced X features (e.g., guest resolution fit, '
               . 'drag and drop, and file and text copy/paste), you will need '
               . 'to do one (or more) of the following:' . "\n"
               . '1. Manually start ' . $bindir . '/vmware-user' . "\n"
               . '2. Log out and log back into your desktop session; and,' . "\n"
               . '3. Restart your X session.' . "\n\n", 0);
  }

  if (vmware_product() eq 'tools-for-linux') {
    if (defined(db_get_answer_if_exists('VMXNET_CONFED')) &&
       (db_get_answer('VMXNET_CONFED') eq 'yes')) {
      if (defined(isKernelBlacklisted())) {
        ***REMOVED*** Because there are problems rmmod'ing the pcnet32 module on some older
        ***REMOVED*** kernels the safest way to pick up the vmxnet module is to ***REMOVED***.
        ***REMOVED*** DO NOT RMMOD pcnet32!  Even by hand! You will terminally confuse the
        ***REMOVED*** kernel which will panic or hang very unpredictably.
        print wrap('To make use of the vmxnet driver you will need to '
                   . '***REMOVED***.' . "\n",0);
      } else {
        my ($vmxnet_dev, $pcnet32_dev, $es1371_dev) = get_devices_list();
        if ($vmxnet_dev or $pcnet32_dev) {
          my $network_path = find_first_exist("/etc/init.d/network",
                                              "/etc/init.d/networking");
          print wrap('To use the vmxnet driver, restart networking using the '
                     . 'following commands: ' . "\n"
                     . "$network_path stop" . "\n", 0);
          if ($pcnet32_dev) {
            print wrap('rmmod pcnet32' . "\n", 0);
          }
          print wrap('rmmod vmxnet' . "\n"
                     . 'modprobe vmxnet' . "\n"
                     . "$network_path start" . "\n\n", 0);
        }
      }
    }
  }
  if (vmware_product() eq 'tools-for-freebsd' and
      defined db_get_answer_if_exists('VMXNET_CONFED') and
      db_get_answer('VMXNET_CONFED') eq 'yes') {
    print wrap('Please remember to configure your network by adding:' . "\n"
               . 'ifconfig_vxn0="dhcp"' . "\n"
               . 'to the /etc/rc.conf file and start the network with:'
               . "\n"
               . '/etc/netstart'
               . "\n"
               . 'to use the vmxnet interface using DHCP.' . "\n\n", 0);
  }
  if (vmware_product() eq 'tools-for-solaris' and
      solaris_10_or_greater() eq 'no' and
      defined db_get_answer_if_exists('VMXNET_CONFED') and
      db_get_answer('VMXNET_CONFED') eq 'yes') {
    print wrap('The installed vmxnet driver will be used for all vlance and '
               . 'vmxnet network devices on this system.  Existing vlance '
               . 'devices will transition from the pcn driver to the vmxnet '
               . 'driver on the next reconfiguration ***REMOVED***.  You will need '
               . 'to verify your network settings accordingly.'
               . "\n\n"
               . 'If you have configured a pcn interface, the corresponding '
               . 'files are now renamed to use the vmxnet device name to '
               . 'ensure the interface will be brought up properly upon ***REMOVED***.'
               . '  For example, the following commands were performed:'
               . "\n", 0);
    print     (  '  ***REMOVED*** mv /etc/hostname.pcn0 /etc/hostname.vmxnet0' . "\n"
               . '  ***REMOVED*** mv /etc/hostname6.pcn0 /etc/hostname6.vmxnet0' . "\n"
               . '  ***REMOVED*** mv /etc/dhcp.pcn0 /etc/dhcp.vmxnet0'
               . "\n");
    print wrap(  'and will cause the Solaris Service Management Facility to '
               . 'bring up the first vmxnetX interface using the configuration '
               . 'of your current pcnX interface.'
               . "\n\n", 0);
  }
  print wrap('Enjoy,' . "\n\n" . '    --the VMware team' . "\n\n", 0);
}

***REMOVED***  Supporting the Gtk2 version of toolbox, we need to make sure pango.modules
***REMOVED***  is configured from our own pango modules, especially on FreeBSD 6.2 and higher.
sub configure_pango {
   my $is64BitUserland = is64BitUserLand();
   my $libdir = db_get_answer('LIBDIR');
   my $liblibbsd = ($is64BitUserland ? '/lib64' : '/lib32') . getFreeBSDLibSuffix();
   my $liblibdir = $libdir . $liblibbsd;
   my $liblibconf = $liblibdir . "/libconf";
   my $pango_module_file = $liblibdir . "/libconf/etc/pango/pango.modules";
   my $pangorc = $liblibdir . '/libconf/etc/pango/pangorc';
   my ($pango_path, $pango_version);
   my %patch;
   my $tmpdir = make_tmp_dir('vmware-pango');

   ***REMOVED*** Since we are only supporting FreeBSD >= 6.3, we only need the one pango
   ***REMOVED*** version for now.
   $pango_version = "1.6.0";

   $pango_path = "pango/" . $pango_version . "/modules";

   ***REMOVED*** Point pangorc to the modules and to the pango.modules file.
   undef %patch;
   %patch = ('@@PANGO_MODULE_FILE@@' => $pango_module_file,
             '@@PANGO_MODULES@@' => $liblibdir . "/" . $pango_path);
   internal_sed($gRegistryDir . "/pangorc", $pangorc, 0, \%patch);
   db_add_file($pangorc, 0);

   ***REMOVED*** Update pango.modules so it knows where to find our modules.
   undef %patch;
   %patch = ('@@LIBDIR@@' => $liblibdir);
   install_template_file($pango_module_file . "-template", \%patch, 1);
   remove_tmp_dir($tmpdir);
}

***REMOVED***
***REMOVED*** Patches and adds a config file for the linker so that certain libs
***REMOVED*** that we specify will appear in the system library path
***REMOVED***
sub configure_ld_dot_so {
    my $source = "/etc/vmware-tools/vmware-tools-libraries.conf";
    my $destDir = "/etc/ld.so.conf.d/vmware-tools-libraries.conf";
    my $destFile = "/etc/ld.so.conf";
    my $blockStr = '';
    my $libdir = db_get_answer('LIBDIR');
    my $patchKey = '@@LIBDIR@@';
    my %patch = ('@@LIBDIR@@' => $libdir);

    ***REMOVED*** Try and just lay down the file.  If that is not an option, then
    ***REMOVED*** edit the ld.so.conf file if possible.  Otherwise do nothing.

    if (internal_which('ldconfig') ne '') {
      if (-d internal_dirname($destDir)) {
	install_file($source, $destDir, \%patch, 1);
	db_add_answer('LD_DOT_SO_DOT_CONF_ADDED_FILE', 'yes');
      } elsif (-f $destFile) {
	open(FD, $source);
	foreach my $line (<FD>) {
	  chomp $line;
	  $line =~ s/$patchKey/$libdir/;
	  $blockStr .= $line . "\n";
	}
	close(FD);
	block_append($destFile,
		     $cMarkerBegin,
		     $blockStr,
		     $cMarkerEnd);
	db_add_answer('LD_DOT_SO_DOT_CONF_MODIFIED', $destFile);
      }
      system('ldconfig &> /dev/null');
    }

    ***REMOVED*** Always set the manifest entries for vmGuestLib to be true
    ***REMOVED*** even if we don't install the libs in the system library path.
    ***REMOVED*** If we don't, tools might be marked out of date.
    set_manifest_component('vmguestlib', 'TRUE');
    set_manifest_component('vmguestlibjava', 'TRUE');
}


sub configure_gdk_pixbuf {
   my $is64BitUserland = is64BitUserLand();
   my $libdir = db_get_answer('LIBDIR');
   my $liblibbsd = ($is64BitUserland ? '/lib64' : '/lib32') . getFreeBSDLibSuffix();
   my $liblibdir = $libdir . $liblibbsd;
   my $loader_file = $liblibdir . "/libconf/etc/gtk-2.0/gdk-pixbuf.loaders";
   my %patch;

   ***REMOVED*** We no longer support FreeBSD < 6.3 hence we do not need to worry about
   ***REMOVED*** the check here anymore.
   ***REMOVED*** Point the GDK_MODULE_FILE to the loaders
   undef %patch;
   %patch = ('@@LIBDIR@@' => $liblibdir);
   install_template_file($loader_file . "-template", \%patch, 0);
}

sub update_file {
   my $plain_file = shift;
   my $tmpfile = shift;
   my $flags = shift;
   my $patch_thru = shift;
   my @statbuf;

   @statbuf = stat($plain_file);

   db_remove_file($plain_file);
   internal_sed($plain_file, $tmpfile, 0, $patch_thru);
   install_file($tmpfile, $plain_file, $patch_thru, $flags);
   safe_chmod(($statbuf[2] & 07777) | 0555, $plain_file);
}

***REMOVED*** switch_tools_config
***REMOVED*** Called by the services.sh startup script.
***REMOVED*** This allows a switch of configuration depending if the system is
***REMOVED*** booted in a VM or natively.
sub switch_tools_config {
  if ($gSystem{'invm'} eq 'yes') {
    switch_to_guest();
  } else {
    switch_to_host();
  }
  db_save();
}

sub get_httpd_status() {
   my $command = "/etc/init.d/httpd.vmware status";
   local *FD;

   if (file_name_exist("/etc/init.d/httpd.vmware")) {
      if (!open(FD, "$command |")) {
         return 3;
      }
      while(<FD>) {
         if ( /\s*.*stopped.*/ ) {
            return 3;
         } else {
            return 0;
         }
      }
   }
   return 3;
}

sub configure_eclipse_plugin {
   my $eclipseDestDir;
   my $eclipseSrcDir = db_get_answer("LIBDIR") . '/eclipse-ivd';

   ***REMOVED*** Some builds won't have the eclipse plugin packaged (e.g player). Only install it
   ***REMOVED*** if we have it.
   if (! -d $eclipseSrcDir) {
     return;
   }

   if (get_persistent_answer("Do you want to install the Eclipse Integrated Virtual " .
			     "Debugger? You must have the Eclipse IDE installed.",
			     "ECLIPSEINSTALL", "yesno", "no") eq 'no') {
     return;
   }

   $eclipseDestDir = get_persistent_answer('Which directory contains your eclipse plugins?',
					   'ECLIPSEDIR', 'dirpath_existing', "");

   if ($eclipseDestDir eq "") {
     ***REMOVED*** don't install if the user (or --default) chose a bogus dir.
     return;
   }

   install_symlink($eclipseSrcDir . '/com.vmware.bfg_1.0.0',
		   $eclipseDestDir . '/com.vmware.bfg_1.0.0');
}

***REMOVED*** Returns the console name of the product for use in a .desktop file
sub getDesktopConsoleName {
   if (vmware_product() eq "wgs" || vmware_product() eq "vserver") {
      return vmware_product_name() . " Console";
   } else {
      return vmware_product_name();
   }
}

***REMOVED*** Returns the name of the .desktop file to produce
sub getDesktopFileName {
   if (vmware_product() eq "ws") {
      return "vmware-workstation.desktop";
   } elsif (vmware_product() eq "wgs") {
      return "vmware-gsx.desktop";
   }

   return undef;
}

***REMOVED*** Returns the name of the icon file to produce
sub getIconFileName {
   if (vmware_product() eq "ws") {
      return "vmware-workstation.png";
   } elsif (vmware_product() eq "wgs") {
      return "vmware-gsx.png";
   }

   return undef;
}

***REMOVED*** Creates a .desktop file
sub createDesktopFile {
   my $use_desktop_utils = shift;
   my $mime_support = shift;
   my $desktopFilename = shift;
   my $productName = shift;
   my $iconShortFile = shift;
   my $execName = shift;
   my $comment = shift;
   my $mimetypes = shift;
   my $visible = shift;
   my $desktopConf;
   my $tmpdir;
   my $iconFile = db_get_answer("ICONDIR") . "/hicolor/48x48/apps/$iconShortFile";
   my $pixmapFile = db_get_answer("PIXMAPDIR") . "/$iconShortFile";

   my $iconName = $iconShortFile;
   $iconName =~ s/\.[^.]*$//;

   $tmpdir = make_tmp_dir($cTmpDirPrefix);
   $desktopConf = "$tmpdir/$desktopFilename";

   if (!open(DESKTOP, ">$desktopConf")) {
        print STDERR wrap("Couldn't open \"$desktopConf\".\n"
                          . "Unable to create the .desktop menu entry file. "
                          . "You must add it to your menus by hand.\n", 0);
      remove_tmp_dir($tmpdir);
      return;
   }

   print DESKTOP <<EOF;
[Desktop Entry]
Encoding=UTF-8
Name=$productName
Comment=$comment
Exec=$execName
Terminal=false
Type=Application
Icon=$iconName
StartupNotify=true
Categories=System;
X-Desktop-File-Install-Version=0.9
MimeType=$mimetypes
EOF

   if ($visible == 0) {
      print DESKTOP "NoDisplay=true\n";
   }

   close(DESKTOP);

   safe_chmod(0644, $desktopConf);

   install_symlink($iconFile, $pixmapFile);

   my $desktopdir = db_get_answer("DESKTOPDIR");

   ***REMOVED*** Make sure the executable exists.
   if (internal_which("desktop-file-install") eq "") {
      $use_desktop_utils = 0;
   }

   if ($use_desktop_utils == 1) {
      my $params = "";

      if ($mime_support == 1) {
         $params = "--rebuild-mime-info-cache ";
      }

      if (system("desktop-file-install --vendor=vmware " .
                 "--dir=" . shell_string($desktopdir) . " " .
                 $params . shell_string($desktopConf))) {
         print STDERR wrap("Unable to install the .desktop menu entry file. "
                           . "You must add it to your menus by hand.\n", 0);
         remove_tmp_dir($tmpdir);
         return;
      }
      db_add_file("$desktopdir/$desktopFilename", 1);
   } else {
      my %p;
      undef %p;
      install_file($desktopConf, "$desktopdir/$desktopFilename", \%p, 1);
   }

   remove_tmp_dir($tmpdir);
}

***REMOVED*** Determine the directory for the icon and .desktop file, and install them
sub configureDesktopFiles {
   my $use_desktop_utils = 1;
   my $mime_support = 0;
   my $pixmapdir;
   my $desktopdir;
   my $vmwareBinary;

   if ((!isServerProduct() && !isDesktopProduct()) || !$gOption{'create_shortcuts'}) {
      return;
   }

   ***REMOVED*** NOTE: We don't uninstall the desktop file if we used
   ***REMOVED***       desktop-file-install, because there is no desktop-file-uninstall.
   $desktopdir = db_get_answer_if_exists("DESKTOPDIR");
   if (defined($desktopdir)) {
      ***REMOVED*** Uninstall
      uninstall_prefix($desktopdir);
   }

   $pixmapdir = db_get_answer_if_exists("PIXMAPDIR");
   if (defined($pixmapdir)) {
      ***REMOVED*** Uninstall
      uninstall_prefix($pixmapdir);
   }

  $desktopdir = get_persistent_answer(
     "What directory contains your desktop menu entry files? "
     . "These files have a .desktop file extension.",
     "DESKTOPDIR", "dirpath",
     "/usr/share/applications");

   if (internal_which("desktop-file-install") eq "") {
      $use_desktop_utils = 0;
      create_dir($desktopdir, $cFlagDirectoryMark);
   } else {
      my $buf = `desktop-file-install --help 2>&1`;

      if ($buf =~ /--rebuild-mime-info-cache/) {
         $mime_support = 1;
      }
   }

   $pixmapdir = get_persistent_answer("In which directory do you want to "
                                      . "install the application's icon?",
                                      "PIXMAPDIR", "dirpath",
                                      "/usr/share/pixmaps");
   create_dir($pixmapdir, $cFlagDirectoryMark);

   my $vmwareBinPath = db_get_answer('BINDIR');
   if (vmware_binary() ne "vmplayer") {
      my $mimetypes = "application/x-vmware-vm;";

      if (vmware_product() eq "ws") {
         $mimetypes .= "application/x-vmware-team;";

	 if (defined db_get_answer_if_exists('VNETLIB_CONFED')) {
	     createDesktopFile($use_desktop_utils, $mime_support,
			       "vmware-netcfg.desktop", "Virtual Network Editor",
			       "vmware-netcfg.png", "$vmwareBinPath/vmware-netcfg",
			       "Manage networking for your virtual machines",
			       "", 1);
	 }

      }

      $vmwareBinary = $vmwareBinPath . '/' . vmware_binary();
      createDesktopFile($use_desktop_utils, $mime_support,
                        getDesktopFileName(), getDesktopConsoleName(),
                        getIconFileName(), $vmwareBinary,
                        "Run and manage virtual machines",
                        $mimetypes, 1);

      if (isServerProduct()) {
         createDesktopFile($use_desktop_utils, $mime_support,
                           "vmware-console-uri-handler.desktop",
                           getDesktopConsoleName(), getIconFileName(),
                           $vmwareBinary . " -o %f",
                           "Run and manage remote virtual machines",
                           "application/x-vmware-console;", 0);
      }
   }

   if (isDesktopProduct()) {
      $vmwareBinary = $vmwareBinPath . '/vmplayer';
      ***REMOVED*** Player is bundled with all desktop products.
      createDesktopFile($use_desktop_utils, $mime_support,
                        "vmware-player.desktop", "VMware Player",
                        "vmware-player.png",
                        $vmwareBinary, "Run a virtual machine",
                        "application/x-vmware-vm;", 1);
   }
}

***REMOVED*** Creates a mimetype package description file
sub createMimePackageFile {
   my $tmpdir;
   my $mimeConf;
   my $mimePath;
   my $mimePackagePath;
   my $desticondir;
   my %p;

   if (!isServerProduct() && !isDesktopProduct()) {
      return;
   }

   $mimePath = "/usr/share/mime";
   $mimePackagePath = $mimePath . "/packages";

   ***REMOVED*** Uninstall
   uninstall_prefix($mimePackagePath);

   ***REMOVED*** Create the new mimetype package
   create_dir($mimePackagePath, $cFlagDirectoryMark);
   $tmpdir = make_tmp_dir($cTmpDirPrefix);
   $mimeConf = "$tmpdir/vmware.xml";

   if (!open(MIMEPACKAGE, ">$mimeConf")) {
      print STDERR wrap("Couldn't open \"$mimeConf\".\n"
                    . "Unable to create the MIME-Type package file.\n", 0);
      remove_tmp_dir($tmpdir);
      return;
   }

   print MIMEPACKAGE <<EOF;
<?xml version="1.0" encoding="UTF-8"?>

<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
 <mime-type type="application/x-vmware-vm">
  <comment xml:lang="en">VMware virtual machine</comment>
  <magic priority="50">
   <match type="string" value='config.version = "' offset="0:4096"/>
  </magic>
  <glob pattern="*.vmx"/>
 </mime-type>

 <mime-type type="application/x-vmware-vmdisk">
  <comment xml:lang="en">VMware virtual disk</comment>
  <magic priority="50">
   <match type="string" value="***REMOVED*** Disk DescriptorFile" offset="0"/>
   <match type="string" value="KDMV" offset="0"/>
  </magic>
  <glob pattern="*.vmdk"/>
 </mime-type>

 <mime-type type="application/x-vmware-team">
  <comment xml:lang="en">VMware team</comment>
  <magic priority="50">
   <match type="string" value='&lt;Foundry version="1"&gt;' offset="0">
    <match type="string" value="&lt;VMTeam&gt;" offset="23:24"/>
   </match>
  </magic>
  <glob pattern="*.vmtm"/>
 </mime-type>

 <mime-type type="application/x-vmware-snapshot">
  <comment xml:lang="en">VMware virtual machine snapshot</comment>
  <magic priority="50">
   <match type="string" value="\\0xD0\\0xBE\\0xD0\\0xBE" offset="0"/>
  </magic>
  <glob pattern="*.vmsn"/>
 </mime-type>

 <mime-type type="application/x-vmware-vmfoundry">
  <comment xml:lang="en">VMware virtual machine foundry</comment>
  <magic priority="50">
   <match type="string" value='&lt;Foundry version="1"&gt;' offset="0">
    <match type="string" value="&lt;VM&gt;" offset="23:24"/>
   </match>
  </magic>
  <glob pattern="*.vmxf"/>
 </mime-type>

EOF

   print MIMEPACKAGE "</mime-info>\n";

   close MIMEPACKAGE;

   safe_chmod(0644, $mimeConf);

   undef %p;
   install_file($mimeConf, $mimePackagePath . "/vmware.xml", \%p, 1);

   remove_tmp_dir($tmpdir);

   ***REMOVED*** Update the MIME database
   if (internal_which("update-mime-database") ne "") {
      if (system("update-mime-database " . shell_string($mimePath) .
                 " >/dev/null 2>&1")) {
         print STDERR wrap("Unable to update the MIME-Type database.\n", 0);
         return;
      }
   }

   $desticondir = get_persistent_answer(
      "In which directory do you want to install the theme icons?",
      "ICONDIR", "dirpath", "/usr/share/icons");

   undef %p;

   my $srcicondir = db_get_answer('LIBDIR') . '/share/icons/hicolor';

   $desticondir = $desticondir . '/hicolor';

   foreach my $sizedir (internal_ls($srcicondir)) {
      if (! -d $srcicondir . '/' . $sizedir) {
         next;
      }

      foreach my $category (qw(apps mimetypes)) {
         my $catdir = $sizedir . '/' . $category;
         if (! -d $srcicondir . '/' . $catdir) {
            next;
         }

         create_dir($desticondir . '/' . $catdir, $cFlagDirectoryMark);

         foreach my $icon (internal_ls($srcicondir . '/' . $catdir)) {
            my $iconpath = $catdir . '/' . $icon;
            install_symlink($srcicondir . '/' . $iconpath,
                            $desticondir . '/' . $iconpath);
            if ($category eq 'mimetypes') {
               install_symlink($desticondir . '/' . $iconpath,
                               $desticondir . '/' . $catdir . '/gnome-mime-' .
                               $icon);
            }
         }
      }
   }

   ***REMOVED*** Refresh icon cache. Some systems (Ubuntu) don't do it automatically
   system(internal_which('touch') . ' -m ' . shell_string($desticondir) . '>/dev/null 2>&1');
   system(internal_which('touch') . ' -m ' . shell_string($srcicondir) . '>/dev/null 2>&1');
   system(shell_string(internal_which('gtk-update-icon-cache')) . ' >/dev/null 2>&1');
   system(shell_string(internal_which('gtk-update-icon-cache')) . " -t $srcicondir >/dev/null 2>&1");
   db_add_file($srcicondir . "/icon-theme.cache", 0)
}

***REMOVED*** Given a bunch of db vars, organize them into a sequence of val=key pairs so the
***REMOVED*** resulting string can be used in a command line.
sub assemble_command_line {
  my @Args = @_;
  my $string = " ";
  my $flag;

  foreach $flag (@Args) {
    if (db_get_answer_if_exists($flag)) {
      $string .= $flag . '=' . db_get_answer($flag) . ' ';
    } elsif (defined($gOption{$flag})) {
      $string .= '--' . $flag;
      if ($gOption{$flag} =~ /\S/) {
        $string .=  '=' . $gOption{$flag} . ' ';
      }
    }
  }

  return $string;
}

sub install_vix {
  my $tmpDir = make_tmp_dir('vmware-vix-installer');
  my $vixFileRoot = db_get_answer('LIBDIR') . '/vmware-vix/vmware-vix';
  my $vixTarFile = $vixFileRoot . '.tar.gz';
  my $cmd;

  ***REMOVED*** Since we're not on Solaris, whose tar doesn't support '.gz' and
  ***REMOVED*** therefore needs gunzip, we need only look for a file ending in
  ***REMOVED*** '.tar.gz' and not worry about the '.tar' case.
  if (!-f $vixTarFile) {
    return 1;
  }

  my $opts = ' -zxopf  ';
  $opts = ' -C ' . $tmpDir . $opts;
  $cmd = shell_string($gHelper{'tar'}) . $opts . shell_string($vixTarFile);
  if (system($cmd)) {
    remove_tmp_dir($tmpDir);
    print wrap('Untarring ' . $vixTarFile . ' failed.' . ".\n", 0);
    return 1;
  }

  my $vixInstallFile = '/vmware-vix-distrib/vmware-install.pl';
  my $defaultOpts = ($gOption{'default'} == 1) ? ' --default' : '';
  $defaultOpts .= assemble_command_line(qw(EULA_AGREED NESTED UPGRADE prefix));

  ***REMOVED*** Reset the EULA value so the next install asks the question again.
  if (db_get_answer_if_exists('EULA_AGREED')) {
    db_remove_answer('EULA_AGREED');
  }

  if (system(shell_string($tmpDir . $vixInstallFile) . '  ' . $defaultOpts)) {
    remove_tmp_dir($tmpDir);
    return 1;
  }
  remove_tmp_dir($tmpDir);
  return 0;
}

***REMOVED*** Check for kernels that won't tolerate removing pcnet32 from the
***REMOVED*** list of in use modules.  If there is an entry in the blacklist
***REMOVED*** and it is a 'yes', then that kernel is blacklisted.  If not a
***REMOVED*** 'yes', then treat the value is more of the blacklisted version
***REMOVED*** string. See if with the appended value, the blacklist string
***REMOVED*** matches a part of the uts_release value of the system's kernel.
sub isKernelBlacklisted {
  my $result = $cPCnet32KernelBlacklist{$gSystem{'version_utsclean'}};
  if (!defined($result)) {
    return undef;
  }

  if ($result eq 'yes') {
    return $result;
  }

  ***REMOVED*** append extra version bit and see if a regexp finds it in
  ***REMOVED*** the current systems uts_release value.
  my $extendedVersion = $gSystem{'version_utsclean'} . $result;
  if ($gSystem{'uts_release'} =~ "^$extendedVersion") {
    return $extendedVersion;
  }

  return undef;
}

***REMOVED*** Set manifest component info
sub set_manifest_component {
  my $name = shift;
  my $installed_flag = shift;
  my $i;

  for $i (0 .. $***REMOVED***gManifestNames) {
    if ($gManifestNames[$i] eq $name) {
      $gManifestInstFlags[$i] = $installed_flag;
      last;
    }
  }
}

***REMOVED*** Write component version info to the manifest file
sub write_manifest_file {
  my $manifest = $gRegistryDir . '/manifest.txt';
  my $line1;
  my $line2;
  my $i;

  if (!open(MANIFESTFILE, ">$manifest")) {
    return;
  }
  for $i (0 .. $***REMOVED***gManifestNames) {
    $line1 = $gManifestNames[$i] . '.version = "' . $gManifestVersions[$i] . '"';
    print MANIFESTFILE $line1 . "\n";
    if ($gManifestNames[$i] ne 'monolithic') {
      $line2 = $gManifestNames[$i] . '.installed = "' . $gManifestInstFlags[$i] . '"';
      print MANIFESTFILE $line2 . "\n";
    }
  }
  close(MANIFESTFILE);
  db_add_file($manifest, 0x0);
}

***REMOVED*** Initialize version manifest
sub init_version_manifest {
  my $manifest_shipped = $gRegistryDir . '/manifest.txt.shipped';
  my @data_lines;
  my $line;
  my $name;

  if (open(VERSIONDATA, "<$manifest_shipped")) {
    @data_lines = <VERSIONDATA>;
    foreach (@data_lines) {
      chomp($_);
      $line = $_;
      $name = substr($line, 0, index($line, '.'));
      if ($name ne '') {
        push(@gManifestNames, $name);
        $line =~ /(\d+\.\d+\.\d+(\.\d+)?)/;
        push(@gManifestVersions, $1);
        push(@gManifestInstFlags, 'FALSE');
      }
    }
    close(VERSIONDATA);
  }
}

***REMOVED*** Internationalization data file
sub symlink_icudt44l {
   my $libdir = db_get_answer('LIBDIR');
   install_symlink($libdir . '/icu', $gRegistryDir . '/icu');
}

***REMOVED*** The VMware Tools for FreeBSD 6 and beyond are shared.  For FreeBSD 7+ users,
***REMOVED*** the Tools depend on the "misc/compat6x" package.  (This package contains
***REMOVED*** libraries and other support files necessary to run FreeBSD 6 binaries.)
***REMOVED***
***REMOVED*** This routine looks for the libraries, and if they aren't found, informs the
***REMOVED*** user and prompts him to determine whether or not we continue with installation.
sub verify_bsd_libcompat {
   ***REMOVED*** Query ldconfig(1) for necessary FreeBSD 6 libraries.
   my ($ldconfigOutput);
   $ldconfigOutput = `ldconfig -r`;

   unless (($ldconfigOutput =~ /(^|\n)[ \t]*\d+:-lc\.6 => /) &&
           ($ldconfigOutput =~ /(^|\n)[ \t]*\d+:-lm\.4 => /)) {

     my $pkg_name = 'compat6x-' . (is64BitUserLand() ? 'amd64' : 'i386');
     my $version = getFreeBSDVersion();
     print wrap ("The VMware Tools for FreeBSD $version depend on libraries " .
		 "provided by the $pkg_name package. Unfortunately we were " .
		 'unable to locate these libraries on your system.  Please install ' .
		 "the $pkg_name package from the FreeBSD Ports Tree before " .
		 'you attempt to configure VMware Tools.' . "\n\n", 0);

     print wrap ('The easiest way to install this pakage is by using ' .
		 'pkg_add utility.  Refer to the man pages on how to ' .
		 'properly use this utility.' . "\n\n", 0);

     error("Please re-run this program after installing the $pkg_name " .
	   'package.' . "\n");
   }
}


***REMOVED*** Program entry point
sub main {
   my (@setOption, $opt);

   if (not is_root()) {
      error('Please re-run this program as the super user.' . "\n\n");
   }

   ***REMOVED*** Force the path to reduce the risk of using "modified" external helpers
   ***REMOVED*** If the user has a special system setup, he will will prompted for the
   ***REMOVED*** proper location anyway
   $ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin';
   initialize_globals();
   if (not (-e $gInstallerMainDB)) {
      error('Unable to find the database file (' . $gInstallerMainDB . ')'
            . "\n\n");
   }

   db_load();
   db_append();
   initialize_external_helpers();

   ***REMOVED*** If we are configuring the tools, and the installer instructed us to
   ***REMOVED*** send the end RPC, specify a signal handler in case the user Ctrl-C's
   ***REMOVED*** early. The handler will send the RPC before exiting.
   if ((vmware_product() eq 'tools-for-linux' ||
	vmware_product() eq 'tools-for-freebsd' ||
	vmware_product() eq 'tools-for-solaris') &&
       $gOption{'rpc-on-end'} == 1) {
       $SIG{INT} = \&sigint_handler;
       $SIG{QUIT} = \&sigint_handler;
   }

   ***REMOVED*** List of questions answered with command-line arguments
   @setOption = ();
   ***REMOVED*** Command line analysis
   while ($***REMOVED***ARGV != -1) {
      my $arg;

      $arg = shift(@ARGV);
      if ( $arg =~ /[^A-Za-z_0-9-=\/,]/ ) {
        config_usage();
      }

      if (lc($arg) =~ /^(-)?(-)?d(efault)?$/) {
         $gOption{'default'} = 1;
      } elsif (lc($arg) =~ /^--install-vmwgfx$/) {
         $gOption{'install-vmwgfx'} = 1;
      } elsif (lc($arg) =~ /^(-)?(-)?c(ompile)?$/) {
         $gOption{'compile'} = 1;
      } elsif (lc($arg) =~ /^(-)?(-)?p(rebuilt)?$/) {
         $gOption{'prebuilt'} = 1;
      } elsif (lc($arg) =~ /^(-)?(-)?s(witch)?$/) {
         $gOption{'tools-switch'} = 1;
      } elsif (lc($arg) =~ /^--clobber-xorg-modules$/) {
         $gOption{'clobber-xorg-modules'} = 1;
      } elsif (lc($arg) =~ /^(-)?(-)?skip-stop-start$/) {
         $gOption{'skip-stop-start'} = 1;
      } elsif (lc($arg) =~ /^(-)?(-)?make-all-net$/) {
         $gOption{'make-all-net'} = 1;
      } elsif (lc($arg) =~ /^(-)?(-)?r(pc-on-end)?$/) {
	 ***REMOVED*** Note:  rpc-on-end has been defaulting to one for some time now.
	 ***REMOVED***        Hence this is a moot argument.
         $gOption{'rpc-on-end'} = 1;
      } elsif (lc($arg) =~ /^(-)?(-)?(no-create-shortcuts)$/) {
         $gOption{'create_shortcuts'} = 0;
      } elsif (lc($arg) =~ /^--preserve$/) {
         $gOption{'preserve'} = 1;
      } elsif (lc($arg) =~ /^(-)?(-)?prefix=(.+)$/) {
         $gOption{'prefix'} = $3;
      } elsif (lc($arg) =~ /^(-)?(-)?m(odules-only)?$/) {
         if (vmware_product() ne 'tools-for-linux') {
           error("Cannot build modules only for non-linux OS.\n");
         }
         $gOption{'modules_only'} = 1;
      } elsif (lc($arg) =~ /^(-)?(-)?k(ernel-version)?$/) {
         $gOption{'kernel_version'} = shift(@ARGV);
         if (vmware_product() ne 'tools-for-linux') {
            error("Cannot build for non-running kernel on non-linux OS.\n");
         }
         if (!$gOption{'kernel_version'} or $gOption{'kernel_version'} eq '') {
            error("Must specify a paramater for --kernel-version.\n");
         }
         ***REMOVED*** Argument validation is deferred till after system_info() is called.
      } elsif (lc($arg) =~ /^--overwrite$/) {
         $gOption{'overwrite'} = 1;
      } elsif (lc($arg) =~ /^--clobber-kernel-modules=([\w,]+)$/ ) {
	foreach my $mod (split(/,/,"$1")) {
	  $gOption{'clobberKernelModules'}{"$mod"} = 'yes';
	}
      } elsif ($arg =~ /=yes/ || $arg =~ /=no/) {
         push(@setOption, $arg);
      } else {
         config_usage();
      }
   }

   if (vmware_product() eq 'tools-for-linux' ) {
     my $mod;
     my $modDep;
     my $modStatus;

     ***REMOVED*** Process clobberedKernelModule dependencies
     ***REMOVED***
     ***REMOVED*** Note that this doesn't handle dependencies of dependencies,
     ***REMOVED*** but we don't need to worry about that just yet.  In the future
     ***REMOVED*** we will use the XML file from the modules directory to determine
     ***REMOVED*** our module dependencies and will have redone this code by then
     ***REMOVED*** anyways.
     ***REMOVED***
     ***REMOVED*** Note: Mind the Tomfoolery with the first for loop below.  You
     ***REMOVED***       apparently have to use %{ ... } around a hash reference
     ***REMOVED***       to make the keys function happy.
     for $mod (keys %{$gOption{'clobberKernelModules'}}) {
       foreach $modDep ($cKernelModuleDeps{"$mod"}) {
	 if (defined $modDep) {
	   $modStatus = $gOption{'clobberKernelModules'}{"$modDep"};
	   if (not defined $modStatus or $modStatus ne 'yes') {
	     print wrap("The module $mod depends on $modDep.  Because of " .
			"this dependency, $modDep has been added to the " .
			"list of kernel modules to be overwritten by this " .
			"installer.\n\n", 0);
	     $gOption{'clobberKernelModules'}{"$modDep"} = 'yes';
	   }
	 }
       }
     }
   }

   ***REMOVED*** Be sure that this is called before anyone attempts to execute any of the
   ***REMOVED*** compiled binaries on FreeBSD 7.
   if (vmware_product() eq 'tools-for-freebsd') {
     my $freeBSDVersion = getFreeBSDVersion();
     if (dot_version_compare("$freeBSDVersion", '7.0') >= 0) {
       verify_bsd_libcompat();
     }
   }

   ***REMOVED*** Be sure that the SUNWuiu8 package is installed before trying to configure
   if (vmware_product() eq 'tools-for-solaris') {
       if(does_solaris_package_exist('SUNWuiu8') == 0){
           error("Package \"SUNWuiu8\" not found. " .
               "This package must be installed in order " .
               "for configuration to continue." . "\n\n");
       }
   }

   if (vmware_product() eq 'tools-for-linux' &&
       $gOption{'tools-switch'} == 0) {
      init_version_manifest();
   }

   if ($gOption{'tools-switch'} == 0) {
      if (vmware_product() eq 'tools-for-linux' ||
          vmware_product() eq 'tools-for-freebsd' ||
          vmware_product() eq 'tools-for-solaris') {
          setupSymlinks();
      }
   }

   ***REMOVED*** this call MUST come after setupSymlinks (if setupSymlinks is deemed necessary)
   system_info();

   ***REMOVED*** system_info needs to be called before we can validate the --kernel-version argument
   if($gOption{'kernel_version'} ne '') {
      ***REMOVED*** First check that they have installed the kernel we are buildind modules for...
      my $modDepPath = "/lib/modules/$gOption{'kernel_version'}/modules.dep";
      if (! -e $modDepPath) {
         error ("It appears that the $gOption{'kernel_version'} kernel " .
                "is not installed.\n");
      }

      ***REMOVED*** --kernel-version always implies modules_only and compile.  Only skip stop and start
      ***REMOVED*** if the kernel is not the one currently running.
      $gOption{'modules_only'} = 1;
      $gOption{'compile'} = 1;
      if($gOption{'kernel_version'} ne $gSystem{'uts_release'}) {
         $gOption{'skip-stop-start'} = 1;
      }
   }

   if (vmware_product() eq 'ws' && $gOption{'make-all-net'}) {
      make_all_net();
      exit 0;
   }

   if (($gOption{'compile'} == 1) && ($gOption{'prebuilt'} == 1)) {
      print wrap('The "--compile" and "--prebuilt" command line options are ' .
                 'mutually exclusive.  Also remember --kernel-version implies' .
                 "--compile. \n\n", 0);
      config_usage();
   }

   ***REMOVED*** Tools configurator entry point
   if (vmware_product() eq 'tools-for-linux' ||
       vmware_product() eq 'tools-for-freebsd' ||
       vmware_product() eq 'tools-for-solaris') {
      if ($gOption{'tools-switch'} == 1) {
         switch_tools_config();
      } else {
         ***REMOVED*** Initialize the dictionary which tracks non-vmware modules
         ***REMOVED*** This only applies to linux currently.
         if (vmware_product() eq 'tools-for-linux') {
           populate_vmware_modules();
         }
         symlink_icudt44l();
         configure_tools();

         if (vmware_product() eq 'tools-for-linux') {
           write_manifest_file();
         }

	 ***REMOVED*** Try to detect if there is a vmware tools install cd in a drive,
	 ***REMOVED*** due to the vmx 'install tools' feature, and if so eject it.
	 ***REMOVED***
	 ***REMOVED*** NOTE: You have to check if the image is inserted BEFORE you
	 ***REMOVED***       send the toolinstall.end RPC message, otherwise it won't
	 ***REMOVED***       answer corredctly.
	 ***REMOVED***       Only eject the tools cd AFTER the toolinstall.end RPC command
	 ***REMOVED***       has been sent.  Otherwise the VMX will think you are
	 ***REMOVED***       trying to cancel the tools install.
	 ***REMOVED***       See bug 409942 for more details.
	 my $rpcresult = send_rpc('toolinstall.is_image_inserted');

	 ***REMOVED*** Send the end RPC along with the results of the configurator run.
         if ($gOption{'rpc-on-end'} == 1) {
           ***REMOVED*** The sleep allows time for the Tools service to send its
           ***REMOVED*** capabilities, which is needed so the manifest copy will
           ***REMOVED*** succeed.
           sleep(3);
           send_rpc('toolinstall.end 1');
         }

	 if ($rpcresult =~ /1/) {
	   eject_tools_install_cd_if_mounted();
	 }
      }

      ***REMOVED*** record root access method for later use by module builder
      if (vmware_product() eq 'tools-for-linux') {
         if (defined $ENV{'SUDO_USER'}) {
            db_add_answer('ROOT_ACCESS_METHOD', 'sudo');
         } else {
            db_add_answer('ROOT_ACCESS_METHOD', 'su');
         }
      }
      db_save();

      ***REMOVED*** make sure changes are flushed to disk before this scripts exits:
      ***REMOVED*** (bug ***REMOVED***999703)
      system(internal_which('sync'));

      exit 0;
   }

   ***REMOVED*** Build the list of all and available ethernet adapters
   ***REMOVED*** The first list is all the adapters that we have.  The
   ***REMOVED*** second are ones that we can still be bridged.
   load_all_ethif_info();
   load_ethif_info();

   ***REMOVED*** Stop VMware's services
   if (!$gOption{'skip-stop-start'}) {
      print wrap('Making sure services for ' . vmware_product_name()
                 . ' are stopped.' . "\n\n", 0);
      if (system(shell_string(db_get_answer('INITSCRIPTSDIR') . '/vmware') .
                  ' status vmcount') >> 8 == 2 &&
          get_answer('Do you want to force a shutdown on the running VMs?',
                     'yesno', 'no') eq 'no') {
         error('Please shut down any running VMs and run this script again.' .
               "\n\n");
      } else {
         if (system(shell_string(db_get_answer('INITSCRIPTSDIR') . '/vmware')
                    . ' stop')) {
            error('Unable to stop services for ' . vmware_product_name() .  "\n\n");
         }
      }
   }
   print "\n";

   if (@setOption > 0) {
      $gOption{'default'} = 1;
      ***REMOVED*** User must specify 'EULA_AGREED=yes' on the command line
      db_add_answer('EULA_AGREED', 'no');
   }
   ***REMOVED*** Install answers specified on the command line
   foreach $opt (@setOption) {
      my ($key, $val);
      ($key, $val) = ($opt =~ /^([^=]*)=([^=]*)/);
      print $key, ' = ', $val, "\n";
      db_add_answer($key, $val);
   }

   if (vmware_product() ne 'ws') {
      ***REMOVED*** For wgs, don't show the EULA for developers' builds.
      if (vmware_product() eq 'wgs') {
        if ('1976090' != 0) {
          show_EULA();
        }
      } else {
        show_EULA();
      }
   }

  if (vmware_product() eq 'wgs') {
    ***REMOVED*** Check memory requirements for GSX/WGS
    check_wgs_memory();
  }

  if (vmware_product() ne 'server') {
    configure_mon();
    configure_vmci();
    configure_vsock();
    configure_pp();

    if (vmware_product() eq 'wgs') {
	configure_net();
    }

    build_vmnet();
  }

  if (isDesktopProduct()) {
    configure_vmblock();
    createMimePackageFile();
    configureDesktopFiles();
    if (vmware_binary() ne "vmplayer") {
      configure_eclipse_plugin();
    }

    ***REMOVED*** record root access method for later use by module builder and other
    ***REMOVED*** programs that require root access
    if (defined $ENV{'SUDO_USER'}) {
       db_add_answer('ROOT_ACCESS_METHOD', 'sudo');
    } else {
       db_add_answer('ROOT_ACCESS_METHOD', 'su');
    }
  }

  ***REMOVED*** Create the directory for the UNIX domain sockets
  create_dir($cConnectSocketDir, $cFlagDirectoryMark);
  safe_chmod(0755, $cConnectSocketDir);

  if ((vmware_product() ne 'wgs') && (vmware_product() ne 'server') &&
      defined($gDBAnswer{'NETWORKING'}) && get_samba_net() != -1) {
     unconfigure_samba();
  }

  if ((vmware_product() eq 'wgs') || (vmware_product() eq 'server')) {
     configure_server();
  }

  if (vmware_product() eq 'wgs') {
    configure_security();
    if (configure_hostd()) {
      configure_webAccess();
    } else {
      my $msg = "Hostd is not configured properly.  Once you have corrected"
                . " the problem, run " . $cConfiguratorFileName . " again.\n";
      error(wrap($msg, 0));
    }
  }

  if (vmware_product() ne 'server') {
     ***REMOVED*** We want VMware to start before samba. If this becomes messy in the future
     ***REMOVED*** we will probably have to dynamically determine the right priority to use
     ***REMOVED*** based on dependencies on other services as we do in the tools install.
     my $S_priority;
     if ($gSystem{'distribution'} eq 'suse') {
        ***REMOVED*** samba is 20 SuSE
        $S_priority = '19';
     } else {
        ***REMOVED*** samba is 91 on RedHat
        $S_priority = '90';
     }
     link_services("vmware", $S_priority, "08");
  }
  if (vmware_product() ne 'server') {
     write_vmware_config();
     if (vmware_product() eq 'wgs' ) {
        ***REMOVED*** This must come after write_vmware_config()
	check_license();
     }
  }

  ***REMOVED*** Look for the Vix tar ball that may be hitching a ride in this installation.
  ***REMOVED*** If the product is workstation or server, and is not vmplayer, its installer
  ***REMOVED*** will be called.
  my $product = vmware_product();
  if ((defined(db_get_answer_if_exists('INSTALL_CYCLE')) &&
       db_get_answer('INSTALL_CYCLE')  eq 'yes') &&
      ($product eq 'ws' || $product eq 'wgs') &&
      (vmware_binary() ne 'vmplayer')) {
    ***REMOVED*** Tell vix install that it is in a nested install.  This flag will be passed
    ***REMOVED*** on the command line, bridging between the vix db and this one.  So, No
    ***REMOVED*** need to pollute the local db.
    $gDBAnswer{'NESTED'} = 'yes';
    if (install_vix()) {
      my $msg = 'The ' . $cVixProductName .  ' failed to install. Please '
                . "correct the problem and run vmware-config.pl again.\n\n";
      print wrap($msg, 0);
    } else {
      ***REMOVED*** Remove the answer only if the install succeeded.  If installing failed,
      ***REMOVED*** then vmware-config.pl should try the install next time around. E.G.
      ***REMOVED*** the user declined the EULA but now wants VIX installed.
      db_remove_answer('INSTALL_CYCLE');
    }
  }

  ***REMOVED*** We use modinfo to determine if a module is installed or not in modconfig
  ***REMOVED*** so we should update this.
  if (isDesktopProduct()) {
    system(shell_string($gHelper{'depmod'}) . ' -a');
  }

  if (isDesktopProduct() || isServerProduct() || isToolsProduct()) {
    symlink_icudt44l();
  }

  ***REMOVED*** Remove the flag _before_
  uninstall_file($gConfFlag);
  db_save();
  ***REMOVED*** Then start VMware's services
  if (!$gOption{'skip-stop-start'}) {
    system(shell_string(db_get_answer('INITSCRIPTSDIR') . '/vmware') . ' start');
    print "\n";
  }

  show_PROMOCODE();

  print wrap('The configuration of ' . vmware_longname() . ' for this ' .
             'running kernel completed successfully.' . "\n\n", 0);
  if ((vmware_product() ne 'wgs') && (vmware_product() ne 'server')) {
    print wrap('You can now run ' . vmware_product_name() . ' by invoking' .
               ' the following command: "' . db_get_answer('BINDIR') .
               '/vmware-toolbox".' . "\n\n", 0);
    print wrap('Enjoy,' . "\n\n" . '    --the VMware team' . "\n\n", 0);
  }
  exit(0);
}

main();
