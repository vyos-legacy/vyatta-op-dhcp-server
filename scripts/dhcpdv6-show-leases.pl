#!/usr/bin/perl

# Module: dhcpdv6-leases.pl
#
# **** License ****
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# A copy of the GNU General Public License is available as
# `/usr/share/common-licenses/GPL' in the Debian GNU/Linux distribution
# or on the World Wide Web at `http://www.gnu.org/copyleft/gpl.html'.
# You can also obtain it by writing to the Free Software Foundation,
# Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# This code was originally developed by Vyatta, Inc.
# Portions created by Vyatta are Copyright (C) 2010 Vyatta, Inc.
# All Rights Reserved.
#
# Author: Bob Gilligan
# Date: April 2010
# Description: Script to display DHCPv6 server leases in a user-friendly form
#
# **** End License ****

use strict;
use lib "/opt/vyatta/share/perl5/";

use Getopt::Long;
use Vyatta::Config;


# Globals
my $lease_filename = "/config/dhcpdv6.leases";
my $debug_flag = 0;

GetOptions(
    "debug"     => \$debug_flag,
    "lease-file=s" =>  \$lease_filename,
    );


sub log_msg {
    my $message = shift;

    print "DEBUG: $message" if $debug_flag;
}


#
# Main section.
#
my @lines=();

if (!open(LEASE_FILE, "<$lease_filename")) {
    printf("DHCPv6 server is not running");
    exit 1;
}

@lines = <LEASE_FILE>;
close(LEASE_FILE);
chomp @lines;

my $level = 0;
my $s1;
my $s2;
my $ia_na;
my $iaaddr;
my $ends_day;
my $ends_time;
my $binding_state;
my %ghash = ();

# Parse the leases file into a hash keyed by IPv6 addr.
foreach my $line (@lines) {
    log_msg("Line: $line\n");
    if ($line =~ /^ia-na .*\{/) {
	if ($level != 0) {
	    printf("Found ia-na at level $level\n");
	    exit 1;
	}
	log_msg("setting ia_na\n");
	($s1, $ia_na, $s2) = split(' ', $line);
	$level++;
    } elsif ($line =~ /^.*iaaddr .*\{/) {
	if ($level != 1) {
	    printf("Found iaaddr at level $level\n");
	    exit 1;
	}
	($s1, $iaaddr, $s2) = split(' ', $line);
	log_msg("Setting iaaddr to $iaaddr.\n");
	log_msg("s1 $s1 s2 $s2\n");
	$level++;
    } elsif ($line =~ /^.*ends /) {
	if ($level != 2) {
	    printf("Found ends at level $level\n");
	    exit 1;
	}
	log_msg("Setting ends_day ends_time\n");
	($s1, $s2, $ends_day, $ends_time) = split(' ', $line);
	$ends_time =~ s/;//;
    } elsif ($line =~ /^.*binding state /) {
	if ($level != 2) {
	    printf("Found binding state at level $level\n");
	    exit 1;
	}
	log_msg("Setting binding state\n");
	($s1, $s2, $binding_state) = split(' ', $line);
	$binding_state =~ s/;//;
    } elsif ($line =~ /^.*\{/) {
	log_msg("Unknown clause: $line\n");
	$level++;
    } elsif ($line =~ /\}/) {
	$level--;
	if ($level == 0) {
	    if (!defined($ia_na)) {
		printf("ia_na not defined\n");
		exit 1;
	    }

	    if (!defined($iaaddr)) {
		printf("iaaddr not defined\n");
		exit 1;
		}

	    if (!defined($ends_day)) {
		printf("ends_day not defined\n");
		exit 1;
	    }

	    if (!defined($ends_time)) {
		printf("ends_time.\n");
		exit 1;
	    }

	    log_msg("Setting ghash entry for $iaaddr to $ends_day $ends_time\n");
	    my @array = ($ends_day, $ends_time, $binding_state);
	    $ghash{$iaaddr} = \@array;
	    undef $ia_na;
	    undef $iaaddr;
	    undef $ends_day;
	    undef $ends_time;
	}
    }
}

# Display the leases...

my $num_entries = scalar(keys %ghash);
if ($num_entries == 0) {
    printf("There are no DHCPv6 leases.\n");
    exit 0;
} elsif ($num_entries == 1) {
    printf("There is one DHCPv6 lease:\n");
} else {
    printf("There are $num_entries DHCPv6 leases:\n");
}

printf("\n");
printf("IPv6 Address                            Expiration          State\n");
printf("--------------------------------------- ------------------- ------\n");
foreach my $key (keys %ghash) {
    my $entry = $ghash{$key};
    my ($day, $time, $state) = @$entry;
    printf ("%-39s %s %s %s\n", $key, $day, $time, $state);
}
