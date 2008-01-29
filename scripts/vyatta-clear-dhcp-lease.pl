#!/usr/bin/perl -W

use strict;
use lib "/opt/vyatta/share/perl5/";

use Getopt::Long;
my $ilfile;
my $olfile;
my $lip;
my $init;
GetOptions("ilfile=s" => \$ilfile, "olfile=s" => \$olfile, "lip=s" => \$lip, "init=s" => \$init);

my $error = 0;

if (!defined($ilfile) || length($ilfile) == 0) {
	$error = 1;
	print STDERR "$0 Error:  Arg --ilfile not specified, ex: --ilfile=/var/log/dhcpd.leases\n";
}
if (!defined($olfile) || length($olfile) == 0) {
	print STDERR "$0 Warning:  Arg --olfile not specified, ex: --olfile=/var/log/dhcpd.leases\n";
}
if (!defined($lip) || length($lip) == 0) {
	$error = 1;
	print STDERR "$0 Error:  Arg --lip not specified, ex: --lip=192.168.2.122\n";
}
if (!defined($init) || length($init) == 0) {
	print STDERR "$0 Warning:  Arg --init not specified, ex: --init=/opt/vyatta/sbin/dhcpd.init\n";
}

exit(1) if ($error == 1);


if (defined($init) && length($init) > 0) {
	system("$init stop") or die "$0 Error:  Unable to stop DHCP server daemon:  $!";
}


local $/=undef;
open LEASES, $ilfile or die "$0 Error:  Couldn't open file $ilfile:  $!";
my $leases = <LEASES>;
close LEASES;


$leases =~ s/^|\nlease $lip {(.|\n)+?\n}//g;


if (defined($init) && length($init) > 0) {
	system("$init start") or die "$0 Error:  Unable to start DHCP server daemon:  $!";
}


if (defined($olfile) && length($olfile) > 0) {
	open LEASES, $olfile or die "$0 Error:  Couldn't open file $olfile:  $!";
	select LEASES;
}
print $leases;
if (defined($olfile) && length($olfile) > 0) {
	select STDOUT;
	close LEASES;
}
