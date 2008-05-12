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

<xsl:variable name="pad12" select="'            '"/>
<xsl:variable name="pad12_len" select="string-length($pad12)"/>
<xsl:variable name="pad40" select="'                                        '"/>
<xsl:variable name="pad40_len" select="string-length($pad40)"/>

<xsl:template match="opcommand">
<xsl:text>&newln;</xsl:text>
<xsl:text>&newln;</xsl:text>

<!-- /* we will no longer be displaying these counts as they present incorrect values, function generating these values has been commented as well
<xsl:text>Total DHCP requests for all pools:   </xsl:text>
<xsl:value-of select="num_requests"/>
<xsl:text>&newln;</xsl:text>

<xsl:text>Total DHCP responses for all pools:  </xsl:text>
<xsl:value-of select="num_responses"/>
<xsl:text>&newln;</xsl:text>
<xsl:text>&newln;</xsl:text>
*/ -->

<xsl:text>pool                                    pool size   # leased    # avail</xsl:text>
<xsl:text>&newln;</xsl:text>
<xsl:text>----                                    ---------   --------    -------</xsl:text>

<xsl:text>&newln;</xsl:text>

<xsl:for-each select="format/row">

<xsl:value-of select="pool"/>
<xsl:value-of select="substring($pad40,1,$pad40_len - string-length(pool))"/>

<xsl:value-of select="num_total_addr"/>
<xsl:value-of select="substring($pad12,1,$pad12_len - string-length(num_total_addr))"/>

<xsl:value-of select="num_lease_addr"/>
<xsl:value-of select="substring($pad12,1,$pad12_len - string-length(num_lease_addr))"/>

<xsl:value-of select="num_avail_addr"/>

<xsl:text>&newln;</xsl:text>

</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
