#!/usr/bin/env perl
#
# Script: vyatta-show-dhcp-server
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
# Description: Wrapper script for DHCP operational commands 
#
# **** End License ****
#

use lib '/opt/vyatta/share/perl5';
use Vyatta::DHCPServerOpMode;
use Getopt::Long;

my ($show_stats, $pool);
GetOptions("show-stats!" => \$show_stats, 
           "pool=s"      => \$pool);


if (defined $show_stats){
  Vyatta::DHCPServerOpMode::print_stats($pool);
}
