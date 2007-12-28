<?xml version="1.0"?>
<!DOCTYPE stylesheet [
<!ENTITY newln "&#10;">
]>

<!-- /*
      *  Copyright 2006, Vyatta, Inc.
      *
      *  GNU General Public License
      * 
      *  This program is free software; you can redistribute it and/or modify
      *  it under the terms of the GNU General Public License, version 2, 
      *  as published by the Free Software Foundation.
      * 
      *  This program is distributed in the hope that it will be useful,
      *  but WITHOUT ANY WARRANTY; without even the implied warranty of
      *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      *  GNU General Public License for more details.
      *
      *  You should have received a copy of the GNU General Public License
      *  along with this program; if not, write to the Free Software
      *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
      *  02110-1301 USA
      *
      * Module: show_dhcp_leases.xsl
      * 
      * Author: Mike Horn
      * Date: 2006
      *
      */ -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:variable name="pad9" select="'         '"/>
<xsl:variable name="pad9_len" select="string-length($pad9)"/>
<xsl:variable name="pad17" select="'                 '"/>
<xsl:variable name="pad17_len" select="string-length($pad17)"/>
<xsl:variable name="pad19" select="'                   '"/>
<xsl:variable name="pad19_len" select="string-length($pad19)"/>
<xsl:variable name="pad21" select="'                     '"/>
<xsl:variable name="pad21_len" select="string-length($pad21)"/>

<xsl:template match="opcommand">

<xsl:text>&newln;</xsl:text>
<xsl:text>&newln;</xsl:text>
<xsl:text>IP address       Hardware Address   Lease expiration     Pool     Client Name</xsl:text>
<xsl:text>&newln;</xsl:text>
<xsl:text>----------       ----------------   ----------------     ----     -----------</xsl:text>
<xsl:text>&newln;</xsl:text>

<xsl:for-each select="format/row">

<xsl:value-of select="ip"/>
<xsl:value-of select="substring($pad17,1,$pad17_len - string-length(ip))"/>

<xsl:value-of select="hardware"/>
<xsl:value-of select="substring($pad19,1,$pad19_len - string-length(hardware))"/>

<xsl:value-of select="end"/>
<xsl:value-of select="substring($pad21,1,$pad21_len - string-length(end))"/>

<xsl:value-of select="shared_network"/>
<xsl:value-of select="substring($pad9,1,$pad9_len - string-length(shared_network))"/>

<xsl:value-of select="client_hostname"/>

<xsl:text>&newln;</xsl:text>

</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
