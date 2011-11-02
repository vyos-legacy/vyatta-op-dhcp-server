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
  return $dec;
}

sub get_active {
    open( my $leases, '<', "/var/log/dhcpd.leases" );
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
        } elsif ($line =~ /binding state free;/ && !($line =~ /next/)) {
          $active_hash{"$pool"}->{"$ip"} -= 1 ;
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
  while (<$conf>){
    my $line = $_;
    $level++ if ( $line =~ /{/ );
    $level-- if ( $line =~ /}/ );
    if ($line =~ /shared-network\s(.*)\s{/){
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
  my $pool_sizes = get_pool_size();
  my $active = get_active();
  my $format = "%-39s %-11s %-11s %s\n";
  print "\n";
  printf($format, "pool", "pool size", "# leased", "# avail");
  printf($format, "----", "---------", "--------", "-------");
  for my $pool (keys %{$pool_sizes}){
    my $pool_size = $pool_sizes->{$pool};
    my $used = $active->{$pool};
    my $avail = $pool_size - $used;
    printf($format, $pool, $pool_size, $used, $avail);
  }
  print "\n";
}

return 1;
