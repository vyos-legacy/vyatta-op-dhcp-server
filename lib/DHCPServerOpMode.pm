#!/usr/bin/env perl
#
# Module Vyatta::DHCPServerOpMode
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
# This code was originally developed by Vyatta, Inc.
# Portions created by Vyatta are Copyright (C) 2008 Vyatta, Inc.
# All Rights Reserved.
#
# Portions created by SO3 Group are Copyright (C) 2013 SO3 Group
#
# Author: John Southworth
# Date: January 2011
# Description: Library containing functions for DHCP operational commands
#
# **** End License ****
#

package Vyatta::DHCPServerOpMode;

use lib "/opt/vyatta/share/perl5/";
use strict;
use Math::BigInt;
use File::Slurp;

sub iptoint {
    # Based on the perl Net::IP module
    my $ip = shift;
    my $binip = unpack('B32', pack('C4C4C4C4', split(/\./, $ip)));
    # $n is the increment, $dec is the returned value
    my ($n, $dec) = (Math::BigInt->new(1), Math::BigInt->new(0));
    # Reverse the bit string
    foreach (reverse(split '', $binip)) {
        # If the nth bit is 1, add 2**n to $dec
        $_ and $dec += $n;
        $n *= 2;
    }
    # Strip leading + sign
    $dec =~ s/^\+//;
    
    return $dec->bstr();
}

sub get_active {
    open( my $leases, '<', "/config/dhcpd.leases" );
    my $pool;
    my $ip;
    my $active = 0;
    my %active_hash = ();
    my %active_leases = ();
    while (<$leases>){
        my $line = $_;
        if ($line =~ /lease\s(.*)\s{/){
            $ip = $1;
        }
        next if (!defined($ip));
        if ($line =~ /shared-network:\s(.*)/) {
            $pool = $1;
        }
        next if (!defined($pool));
        if (!defined($active_hash{"$pool"}->{"$ip"})){
            $active_hash{"$pool"}->{"$ip"} = 0;
        } else {
            if ($line =~ /binding state active;/) {
                $active_hash{"$pool"}->{"$ip"} += 1 ;
                ($pool, $ip) = (undef, undef);
            } elsif ($line =~ /binding state free;/ && !($line =~ /next/)) {
                $active_hash{"$pool"}->{"$ip"} -= 1 ;
                ($pool, $ip) = (undef, undef);
            }
        }
    }
    for my $pool (keys %{active_hash}){
        for my $ip ( keys %{$active_hash{$pool}}) {
            if (!defined($active_leases{$pool})){
                $active_leases{$pool} = 0;
            }
            $active_leases{$pool} += 1 if ( $active_hash{"$pool"}->{"$ip"} >= 0 );
        }
    }
    
    return \%active_leases;
}

sub get_pool_size {
    open( my $conf, '<', "/opt/vyatta/etc/dhcpd.conf" )
        or die "Can't open dhcpd.conf";
    my $level = 0;
    my $shared_net;
    my %shared_net_hash = ();
    while (<$conf>) {
        my $line = $_;
        $level++ if ( $line =~ /{/ );
        $level-- if ( $line =~ /}/ );
        if ($line =~ /shared-network\s(.*)\s{/) {
            $shared_net = $1;
        } elsif ($line =~ /range\s(.*?)\s(.*?);/) {
            my $start = iptoint($1);
            my $stop = iptoint($2);
            $shared_net_hash{"$shared_net"} += ($stop - $start + 1);
        } 
    }
    #sanity check the file
    if ($level != 0){
        die "Invalid dhcpd.conf, mismatched braces";
    }
    
    return \%shared_net_hash;
}

sub print_stats {
    my $pool_filter = $_[0];
    my $pool_sizes = get_pool_size();
    my $active = get_active();
    my $format = "%-25s %-11s %-11s %s\n";
    print "\n";
    printf($format, "Pool", "Pool size", "# Leased", "# Avail");
    printf($format, "----", "---------", "--------", "-------");
    for my $pool (keys %{$pool_sizes}) {
        if (defined ($pool_filter)) {
            next if ($pool ne $pool_filter);
        }
        my $pool_size = $pool_sizes->{$pool};
        my $used = $active->{$pool};
        $used = 0 if (!defined($used));
        $pool_size = 0 if (!defined($pool_size));
        my $avail = $pool_size - $used;
        printf($format, $pool, $pool_size, $used, $avail);
    }
    print "\n";
}

# Read leases file into string
#
# If this really causes performance troubles,
# replace with line- or character-oriented parser
sub read_lease_file {
    my $leases_file = read_file('/config/dhcpd.leases');

    return $leases_file;
}

# Extract individual leases and return array
sub get_leases {
    my $leases_raw = shift;
    my @leases = $leases_raw =~ /(lease \s+ [\d\.]+ \s+ {.*?})/gsx;

    return @leases;
}

# Parse individual lease, return parameter hash
sub parse_lease {
    my $lease = shift;
    my %lease_hash = ();

    # Get state
    my ($state) = $lease =~ /binding \s+ state \s+ (.*?) \s* ;/sx;
    die("Malformed lease: missing state!") unless defined($state);
    $lease_hash{"state"} = $state;
    
    # Get client IP address
    my ($ip_address) = $lease =~ /lease \s+ ([\d\.]+) \s+ {/sx;
    die("Malformed lease: missing IP address!") unless defined($ip_address);
    $lease_hash{"ip_address"} = $ip_address;

    # Get hardware address
    # May be absent in backup and free leases so don't complain in that case
    my ($hardware_address) = $lease =~ /hardware \s+ ethernet \s+ (.*?) \s* ;/sx;
    if ($state !~ /backup|free/) {    
        die("Malformed lease: missing hardware address!") unless defined($hardware_address);
    } else {
        $hardware_address = "" unless defined($hardware_address);
    }
    $lease_hash{"hardware_address"} = $hardware_address;

    # Get start time
    # May be absent in free leases so don't complain in that case
    my ($start_time) = $lease =~ /starts \s+ \d \s+ (.*?) \s* ;/sx;
    if ($state ne "free") {
        die("Malformed lease: missing start time!") unless defined($start_time);
    } else {
        $start_time = "" unless defined($start_time);
    }
    $lease_hash{"start_time"} = $start_time;

    # Get end time
    # May be absent in backup and free leases so don't complain in that case
    my ($end_time) = $lease =~ /ends \s+ \d \s+ (.*?) \s* ;/sx;
    if ($state !~ /backup|free/) {
        die("Malformed lease: missing end time!") unless defined($end_time);
    } else {
        $end_time = "" unless defined($end_time);
    }
    $lease_hash{"end_time"} = $end_time;

    # Get pool
    my ($pool) = $lease =~ /shared-network: \s+ (.*?) \s+/sx;
    $pool = "" unless defined($pool);
    $lease_hash{"pool"} = $pool;

    # Get client name
    my ($client_name) = $lease =~ /client-hostname \s+ "* (.*?) "* \s* ;/sx;
    if (defined($client_name)) {
        my $prefix = $pool."_";
        $client_name =~ s/$prefix//;
    } else {
        $client_name = "";
    }
    $lease_hash{"hostname"} = $client_name;

    return %lease_hash;
}

sub print_leases {
    my ($pool, $state) = @_;

    # Show active leases by default
    $state = "active" unless defined($state);

    my @leases = get_leases(read_lease_file());

    my $format = "%-16s %-18s %-20s %-25s %s\n";

    printf("\n");
    printf($format, "IP address", "Hardware address", "Lease expiration", "Pool", "Client Name");
    printf($format, "----------", "----------------", "----------------", "----", "-----------");

    for my $lease (@leases) {
        my %lease_hash = parse_lease($lease);

        my $skip = 0;
        if ( (defined($state) && ($lease_hash{"state"} ne $state)) ||
             (defined($pool) && ($lease_hash{"pool"} ne $pool) ) ) {
            $skip = 1;
        }

        if ( !$skip ) {
            printf($format,
                   $lease_hash{"ip_address"},
                   $lease_hash{"hardware_address"},
                   $lease_hash{"end_time"},
                   $lease_hash{"pool"},
                   $lease_hash{"hostname"} );
        }
    }
}

return 1;
