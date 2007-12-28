opdir		 = $(datadir)/vyatta-op/templates

xsldir          = @XSLDIR@

bin_sudo_usersdir = $(bindir)/sudo-users

xsl_DATA =

bin_sudo_users_SCRIPTS = 

xsl_DATA        += src/xsl/show_dhcp_leases.xsl
xsl_DATA        += src/xsl/show_dhcp_stats.xsl

cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | \
	cpio -0pd

install-exec-hook:
	mkdir -p $(DESTDIR)$(opdir)
	cd templates; $(cpiop) $(DESTDIR)$(opdir)


