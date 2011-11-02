opdir		 = $(datadir)/vyatta-op/templates

xsldir          = @XSLDIR@

bin_sudo_usersdir = $(bindir)/sudo-users
share_perl5dir   = $(datarootdir)/perl5/Vyatta/


xsl_DATA =

bin_sudo_users_SCRIPTS = scripts/vyatta-clear-dhcp-lease.pl
bin_sudo_users_SCRIPTS += scripts/vyatta-show-dhcp-server.pl

share_perl5_DATA = lib/DHCPServerOpMode.pm

sbin_SCRIPTS = scripts/dhcpdv6-show-leases.pl
sbin_SCRIPTS += scripts/dhcpdv6-show-status.pl

xsl_DATA        += src/xsl/show_dhcp_leases.xsl
xsl_DATA        += src/xsl/show_dhcp_stats.xsl
xsl_DATA        += src/xsl/show_dhcp_leases_expired.xsl


bin_sudo_users_PROGRAMS	= command_proc_show_dhcp_leases command_proc_show_dhcp_stat


command_proc_show_dhcp_leases_SOURCES = src/command_proc_base.hh
command_proc_show_dhcp_leases_SOURCES += src/command_proc_show_dhcp_leases.cc
command_proc_show_dhcp_leases_SOURCES += src/command_proc_show_dhcp_leases.hh
command_proc_show_dhcp_leases_SOURCES += src/rl_str_proc.cc
command_proc_show_dhcp_leases_SOURCES += src/rl_str_proc.hh
command_proc_show_dhcp_leases_SOURCES += src/xsl_processor.cc
command_proc_show_dhcp_leases_SOURCES += src/xsl_processor.hh
command_proc_show_dhcp_leases_LDADD = -lsablot


command_proc_show_dhcp_stat_SOURCES = src/command_proc_base.hh
command_proc_show_dhcp_stat_SOURCES += src/command_proc_show_dhcp_stat.cc
command_proc_show_dhcp_stat_SOURCES += src/command_proc_show_dhcp_stat.hh
command_proc_show_dhcp_stat_SOURCES += src/rl_str_proc.cc
command_proc_show_dhcp_stat_SOURCES += src/rl_str_proc.hh
command_proc_show_dhcp_stat_SOURCES += src/xsl_processor.cc
command_proc_show_dhcp_stat_SOURCES += src/xsl_processor.hh
command_proc_show_dhcp_stat_LDADD = -lsablot


cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | \
	cpio -0pd

install-exec-hook:
	mkdir -p $(DESTDIR)$(opdir)
	cd templates; $(cpiop) $(DESTDIR)$(opdir)


