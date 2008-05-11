/**
 *    Module: command_proc_show_dhcp_leases.hh
 *
 *    Author: Michael Larson
 *    Date: 2005
 *    Description:
 *
 *    This program is free software; you can redistribute it and/or modify 
 *    it under the terms of the GNU General Public License as published 
 *    by the Free Software Foundation; either version 2 of the License, 
 *    or (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be  useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 *    02110-1301 USA
 *
 *    Copyright 2006, Vyatta, Inc.
 */
#ifndef __COMMAND_PROC_SHOW_DHCP_LEASES_HH__
#define __COMMAND_PROC_SHOW_DHCP_LEASES_HH__

#include <map>
#include <string>
#include "command_proc_base.hh"


#define XSLDIR		"/opt/vyatta/share/xsl"
#define SYSCONFDIR	"/opt/vyatta/etc"


class CommandProcShowDHCPLeases : public CommandProcBase
{
public:
  CommandProcShowDHCPLeases();
  ~CommandProcShowDHCPLeases();

  /**
   *
   **/
  static std::string
  name() {return "showleasestable";}

  /**
   *
   **/
  static StringColl
  register_command();

  /**
   *
   **/
  std::string
  process(const std::string &cmd, bool debug, std::string &reason);

  /**
   *
   **/ 
  bool
  is_valid() {return true;}

  /**
   *
   **/
  void 
  convert_to_xml(const std::string &line, const std::string &pool, bool active_leases);

  /**
   *
   **/
  void
  complete_xml();

protected:
  std::string _xml_out;
  std::map<std::string, std::string> _coll;
  std::string _ip;
  std::string _xml_frag;
  std::string _pool;
};

#endif //__COMMAND_PROC_SHOW_DHCP_LEASES_H__
