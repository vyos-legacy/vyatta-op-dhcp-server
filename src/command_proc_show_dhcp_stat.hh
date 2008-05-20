/**
 *    Module: command_proc_show_dhcp_stat.hh
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
#ifndef __COMMAND_PROC_SHOW_DHCP_STAT_HH__
#define __COMMAND_PROC_SHOW_DHCP_STAT_HH__

#include <map>
#include <set>
#include <string>
#include "command_proc_base.hh"
//#include "libxorp/ipv4.hh"


#define XSLDIR		"/opt/vyatta/share/xsl"
#define SYSCONFDIR	"/opt/vyatta/etc"


/**
 *
 *
 **/
class DHCPStatistics
{
public:
  typedef std::map<std::string, std::string> SubnetColl;
  typedef std::map<std::string, std::string>::const_iterator SubnetIter;

  DHCPStatistics() {}

public:
  std::string _pool;
  SubnetColl _subnet_coll;
  std::string _interface;
  std::set<std::string> _ips;

  unsigned long getTotalIPsAvailable() const {
    return getTotalRange() - getTotalIPsLeased();
  }
  unsigned long getTotalIPsLeased() const {
    return _ips.size();
  }
  unsigned long getTotalRange() const;

};


/**
 *
 *
 **/
class CommandProcShowDHCPStat : public CommandProcBase
{
public:
  CommandProcShowDHCPStat();
  ~CommandProcShowDHCPStat();

  /**
   *
   **/
  static std::string
  name() {return "showdhcpstat";}

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

private:
  bool process_lease_file();
//  bool process_statistics();      // no longer being used
  bool process_conf();
  void write_xml(const std::string & pool);
  void write_xml(const DHCPStatistics & ds);

protected:
  std::string _xml_out;
  std::string _dhcp_req; // no longer used
  std::string _dhcp_resp; // no longer used
  std::map<std::string, DHCPStatistics*> _stats;
};

#endif //__COMMAND_PROC_SHOW_DHCP_STAT_H__
