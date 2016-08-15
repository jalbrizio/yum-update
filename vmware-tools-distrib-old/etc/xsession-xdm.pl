***REMOVED***!/usr/bin/perl -w
***REMOVED***
***REMOVED*** Copyright 2007-2013 VMware, Inc.  All rights reserved.
***REMOVED***

use strict;

***REMOVED***
***REMOVED*** xsession-xdm.pl --
***REMOVED***   Massage xrdb(1) output of xdm-config to help determine the location of
***REMOVED***   the user's Xsession script.
***REMOVED***
***REMOVED*** First extract the display number from the user's DISPLAY environment
***REMOVED*** variable.  Then examine input looking for either of the following:
***REMOVED***   1.  Xsession script specific to this display.
***REMOVED***   2.  Wildcard Xsession resource (applies to all displays).
***REMOVED***
***REMOVED*** If a display-specific resource was found, print its value.  Otherwise,
***REMOVED*** if a generic resource was found, print its value.  If neither was found,
***REMOVED*** there is no output.
***REMOVED***

my $sessionSpecific;    ***REMOVED*** Path to display-specific Xsession script.
my $sessionDefault;     ***REMOVED*** Path to default Xsession script.

my $display;    ***REMOVED*** Refers to user's display number.
my $spattern;   ***REMOVED*** Pattern generated at run-time (based on $display) to match
                ***REMOVED*** a display-specific DisplayManager*session line.

***REMOVED*** The generic/default pattern.
my $gpattern = '^[^!]*DisplayManager\.?\*\.?session';

if (defined($ENV{'DISPLAY'}) && $ENV{'DISPLAY'} =~ /:([0-9]+)/) {
   ***REMOVED*** Based on the well-formed $DISPLAY, build our display-specific session
   ***REMOVED*** pattern thingy.
   $display = $1;
   $spattern = sprintf("^[^!]*DisplayManager._%d.session", $display);

   ***REMOVED*** Okay, patterns have been built.  Let's get our search on.
   while (<STDIN>) {
      chomp($_);

      if ($_ =~ /$spattern:\s*(.*)/) {
         $sessionSpecific = $1;
      } elsif ($_ =~ /$gpattern:\s*(.*)/) {
         $sessionDefault = $1;
      }
   }

   if ($sessionSpecific) {
      print "$sessionSpecific\n";
   } elsif ($sessionDefault) {
      print "$sessionDefault\n";
   }
}
