opdir		 = $(datadir)/vyatta-op/templates

bin_sudo_usersdir = $(bindir)/sudo-users
share_perl5dir   = $(datarootdir)/perl5/Vyatta/

bin_sudo_users_SCRIPTS = scripts/vyatta-clear-dhcp-lease.pl
bin_sudo_users_SCRIPTS += scripts/vyatta-show-dhcp-server.pl

share_perl5_DATA = lib/DHCPServerOpMode.pm

sbin_SCRIPTS = scripts/dhcpdv6-show-leases.pl
sbin_SCRIPTS += scripts/dhcpdv6-show-status.pl

cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | \
	cpio -0pd

install-exec-hook:
	mkdir -p $(DESTDIR)$(opdir)
	cd templates; $(cpiop) $(DESTDIR)$(opdir)


