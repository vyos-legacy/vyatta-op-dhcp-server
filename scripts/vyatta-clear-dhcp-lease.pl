#!/usr/bin/perl -W

use strict;
use lib "/opt/vyatta/share/perl5/";

use Getopt::Long;
my $ilfile;
my $olfile;
my $lip;
my $pidf;
my $init;
GetOptions("ilfile=s" => \$ilfile, "olfile=s" => \$olfile, "lip=s" => \$lip, "pidf=s" => \$pidf, "init=s" => \$init);

my $error = 0;

if (!defined($ilfile) || length($ilfile) == 0) {
	$error = 1;
	print STDERR "$0 Error:  Arg --ilfile not specified, ex: --ilfile=/config/dhcpd.leases\n";
}
if (!defined($olfile) || length($olfile) == 0) {
	print STDERR "$0 Warning:  Arg --olfile not specified, ex: --olfile=/config/dhcpd.leases\n";
}
if (!defined($lip) || length($lip) == 0) {
	$error = 1;
	print STDERR "$0 Error:  Arg --lip not specified, ex: --lip=192.168.2.122\n";
}
if (!defined($pidf) || length($pidf) == 0) {
	print STDERR "$0 Warning:  Arg --pidf not specified, ex: --init=/var/run/dhcpd.pid\n";
}
if (!defined($init) || length($init) == 0) {
	print STDERR "$0 Warning:  Arg --init not specified, ex: --init=/opt/vyatta/sbin/dhcpd.init\n";
}

exit(1) if ($error == 1);


if (defined($pidf) && length($pidf) && defined($init) && length($init) > 0) {
	if (-f $pidf) {
		system("$init stop") == 0 or die "$0 Error:  Unable to stop DHCP server daemon:  $!";
	}
}

if (-e $ilfile) {
	if ($lip eq 'all') {
		unlink($ilfile) or die "$0 Error:  Unable to delete $ilfile:  $!";
	} else {
		local $/=undef;
		open LEASES, "<$ilfile" or die "$0 Error:  Couldn't open file $ilfile:  $!";
		my $leases = <LEASES>;
		close LEASES;


		$leases =~ s/^|\nlease $lip {(.|\n)+?\n}//g;


		if (defined($olfile) && length($olfile) > 0) {
			open LEASES, ">$olfile" or die "$0 Error:  Couldn't open file $olfile:  $!";
			select LEASES;
		}
		print $leases;
		if (defined($olfile) && length($olfile) > 0) {
			select STDOUT;
			close LEASES;
		}
	}
}

use Vyatta::Config;
my $vcDHCP = new Vyatta::Config();
$vcDHCP->setLevel('service dhcp-server');
if ($vcDHCP->existsOrig('.')) {
	my $disabled = 0;
	my $disabled_val = $vcDHCP->returnOrigValue('disabled');
	if (defined($disabled_val) && $disabled_val eq 'true') {
		$disabled = 1;
		print STDERR "Warning:  DHCP server will be deactivated because 'service dhcp-server disabled' is set to 'true'.\n";
	}

	if ($disabled == 0 && defined($init) && length($init) > 0) {
		system("$init start") == 0 or die "$0 Error:  Unable to start DHCP server daemon:  $!";
	}
}

