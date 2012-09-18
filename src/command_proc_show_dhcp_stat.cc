/**
 *    Module: command_proc_show_dhcp_stat.cc
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

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <iostream>
#include <list>
#include <string>
#include <time.h>
#include <string.h>
#include <stdlib.h>

//#include "config.h"
#include "rl_str_proc.hh"
#include "command_proc_show_dhcp_stat.hh"
#include "xsl_processor.hh"

using namespace std;



int main(int argc, char ** argv) {

	//Build out string request based on the number of argcs.
	string request;
	bool debug = false;
	for (int i = 1; i < argc; ++i) {
		if (strcmp((const char *)argv[i], "--debug") == 0) {
			debug = true;
		} else {
			request += string(argv[i]) + string(" ");
		}
	}
	if (debug) {
		cout << "request: " << request << endl;
	}


	CommandProcShowDHCPStat proc;

	// process command and create xml output
	string reason;
	string xml_out = proc.process(request, debug, reason);
	if (debug) {
		cout << "output xml:" << endl << xml_out << endl;
	}

	if (xml_out.empty() == true) {
		cout << reason << endl;
		exit(0);
	}

	bool catch_param_name = false;
	bool catch_param_val = false;
	string param_name;
	string param_val;
	list<pair<string,string> > listParams;
	for (int i = 1; i < argc; ++i) {
		if (strcmp(argv[i], "--pname") == 0) {
			catch_param_name = true;
			catch_param_val = false;
			param_name = "";
			param_val = "";
		} else if (strcmp(argv[i], "--pval") == 0) {
			catch_param_name = false;
			catch_param_val = true;
			param_val = "";
		} else {
			if (catch_param_name) {
				param_name = argv[i];
				catch_param_name = false;
			}
			if (catch_param_val) {
				param_val = argv[i];
				catch_param_val = false;
			}
		}
		if (param_name.length() > 0 && param_val.length() > 0) {
			listParams.push_back(pair<string,string>(param_name, param_val));
			param_name = "";
			param_val = "";
		}
	}





	XSLProcessor xsl_processor(debug);

	cout << xsl_processor.transform(xml_out, proc.xsl(), listParams) << endl;
}


unsigned long DHCPStatistics::getTotalRange() const {
  unsigned long totalRange = 0;
  SubnetIter iter = _subnet_coll.begin();
  while (iter != _subnet_coll.end()) {
    unsigned long start = ntohl(inet_addr(iter->first.c_str()));
    unsigned long stop = ntohl(inet_addr(iter->second.c_str()));
    totalRange += stop - start + 1;
    ++iter;
  }
  return totalRange;
}

/**
 *
 **/
CommandProcShowDHCPStat::CommandProcShowDHCPStat() : _dhcp_req("0"), _dhcp_resp("0")
{

}

/**
 *
 **/
CommandProcShowDHCPStat::~CommandProcShowDHCPStat()
{
  std::map<std::string, DHCPStatistics*>::iterator i = _stats.begin();
  const std::map<std::string, DHCPStatistics*>::const_iterator iEnd = _stats.end();
  for (std::map<std::string, DHCPStatistics*>::iterator i = _stats.begin(); i != _stats.end(); ++i) {
    DHCPStatistics * p_ds = i->second;
    if (p_ds != NULL) delete p_ds;
    i->second = NULL;
  }
}

/**
 *
 **/
std::string
CommandProcShowDHCPStat::process(const string &cmd, bool debug, string &reason)
{
  UNUSED(debug);
  StrProc proc_str(cmd, " ");
  std::string pool;

  if (proc_str.size() == 2) {
     _xsl = XSLDIR "/" + proc_str.get(0);
     pool = proc_str.get(1);
  } 
  else {
     _xsl = XSLDIR "/" + proc_str.get(0);
  }

  reason = "";

  struct stat buf;
  if (stat("/var/run/dhcpd.pid", &buf) != 0) {
    reason = "DHCP server is not running";
    return string("");
  }

  //we'll need to pre-process the data for this command from the
  //following sources:
  //daemon generated statistics file
  //configuration file
  //leases file

  //this kind of goes against my original intention of keeping this a
  //strictly parsing module, without interpretation of the data, but
  //given that putting the processing elsewhere would make this a less
  //efficient process it makes sense for now.

  if (!process_lease_file()) {
    return string("");
  }
  /* commenting this function call as the function has been commented and is not being used now
  if (!process_statistics()) {
    return string("");
  }
  */
  if (!process_conf()) {
    return string("");
  }

  write_xml(pool);

  return _xml_out;
}


/**
 *
 * example of a lease
lease 10.0.0.236 {
  starts 4 2006/02/23 18:34:48;
  ends 5 2006/02/24 18:34:48;
  #shared-network: foo;
  binding state active;
  next binding state free;
  hardware ethernet 00:12:3f:b3:02:b2;
}
*
* we'll extract the number of leased addrs for the pool from this file
*
 **/
bool
CommandProcShowDHCPStat::process_lease_file()
{
  const string file_conf(SYSCONFDIR "/dhcpd.conf");
  const string file("/config/dhcpd.leases");

  string ip_addr;
  std::string pool;
  char line[256];

  FILE* fconf = fopen(file_conf.c_str(), "r");
  if (fconf) {
    while (fgets(line, 255, fconf) != NULL) {
	StrProc proc_str(line, " ");
	if (proc_str.get(0) == "shared-network") {
	    pool = proc_str.get(1);
	    DHCPStatistics * p_ds = _stats[pool];
            if (p_ds == NULL) {
               p_ds = new DHCPStatistics();
               p_ds->_pool = pool;
               _stats[pool] = p_ds;
	    }
        }  
     } 
  }
  fclose(fconf);

  FILE* fd = fopen(file.c_str(), "r");
  if (fd) {
    while (fgets(line, 255, fd) != NULL) {
      StrProc proc_str(line, " ");
      if (proc_str.get(2) == "{") {
	ip_addr = proc_str.get(1);
      }
      if (proc_str.get(0) == "#shared-network:") {
          pool = proc_str.get(1);
      }
      if (proc_str.get(0) == "binding") {
        DHCPStatistics * p_ds = _stats[pool];
         if (proc_str.get(2) == "active;") {
             p_ds->_ips.insert(ip_addr);
         } else {
             p_ds->_ips.erase(ip_addr);
         }
      }
    }
    fclose(fd);
  }
  return true;
}

/**
 *
 **/
/* commenting this function as its no longer going to be used
bool
CommandProcShowDHCPStat::process_statistics()
{
  const string file("/var/log/dhcpd.status");
  char line[256];
  FILE* fd = fopen(file.c_str(), "r");
  if (fd) {
    while (fgets(line, 255, fd) != NULL) {
      StrProc proc_str(line, " ");
      if (proc_str.get(0) == "request-count:") {
	_dhcp_req = (proc_str.get(1).empty() ? "0" : proc_str.get(1));
      }
      if (proc_str.get(0) == "response-count:") {
	_dhcp_resp = (proc_str.get(1).empty() ? "0" : proc_str.get(1));
      }
    }
    fclose(fd);
  }
  return true;
}
*/

/**
 * total addr available, ip subnet, interface
 **/
bool
CommandProcShowDHCPStat::process_conf()
{
  const string file(SYSCONFDIR "/dhcpd.conf");
  std::string pool;
  bool in_config_block = false;
  
  int subnet_count;
  int subnet_end;
  char line[256];
  FILE *fd = fopen(file.c_str(), "r");
  if (fd) {
    while (fgets(line, 255, fd) != NULL) {
      StrProc proc_str(line, " ");

      if (proc_str.get(0) == "shared-network") {
        subnet_count = 0;
        subnet_end = 0;
	in_config_block = true;
        pool = proc_str.get(1);
      }
      
      if (proc_str.get(0) == "subnet") {
	  subnet_count = subnet_count + 2;
      }
      
      if (proc_str.get(0) == "}") {
        subnet_end++;
        if (subnet_end > subnet_count)
	   in_config_block = false;
      }
      
      if ((in_config_block == true) && (proc_str.get(0) == "range")) {
	DHCPStatistics * p_ds = _stats[pool];
	if (p_ds != NULL) {
          p_ds->_subnet_coll.insert(pair<string, string>(proc_str.get(1), proc_str.get(2).substr(0, proc_str.get(2).length()-1)));
        }
      }
    }
    fclose(fd);
  }

  return true;
}

/**
 *
 **/
void
CommandProcShowDHCPStat::write_xml(const std::string & pool) 
{
  _xml_out = "<opcommand name='dhcpstat'>";
  //_xml_out += "<num_requests>" + _dhcp_req + "</num_requests>";
  //_xml_out += "<num_responses>" + _dhcp_resp + "</num_responses>";
  _xml_out += "<format type='row'>";

  if (pool.empty() == false) {
      const DHCPStatistics * p_ds = _stats[pool];
      if (p_ds != NULL) write_xml(*p_ds); 
  } else {
    for (std::map<std::string, DHCPStatistics*>::const_iterator i = _stats.begin(); i != _stats.end(); i++) {
      const DHCPStatistics * p_ds = i->second;
      if (p_ds != NULL) write_xml(*p_ds); 
    }
  }   
  _xml_out += "</format></opcommand>";
}
void
CommandProcShowDHCPStat::write_xml(const DHCPStatistics & ds)
{
  char buf[80];

  _xml_out += "<row>";
  _xml_out += "<pool>" + ds._pool + "</pool>";

  sprintf(buf, "%ld", ds.getTotalRange());
  _xml_out += "<num_total_addr>" + string(buf) + "</num_total_addr>";

  sprintf(buf, "%ld", ds.getTotalIPsLeased());
  _xml_out += "<num_lease_addr>" + string(buf) + "</num_lease_addr>"; 
 
  sprintf(buf, "%ld", ds.getTotalIPsAvailable());
  _xml_out += "<num_avail_addr>" + string(buf) + "</num_avail_addr>";

  _xml_out += "<interface>" + ds._interface + "</interface>";
  _xml_out += "</row>";

}

