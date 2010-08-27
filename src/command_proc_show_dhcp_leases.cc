/**
 *    Module: command_proc_show_dhcp_leases.cc
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

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>

#include <iostream>
#include <list>
#include <string>
#include <time.h>
#include <stdlib.h>

//#include "config.h"
#include "rl_str_proc.hh"
#include "command_proc_show_dhcp_leases.hh"
#include "xsl_processor.hh"

using namespace std;





int main(int argc, char ** argv) {

	//Build out string request based on the number of argcs.
	string request;
	bool debug = false;
	for (int i = 1; i < argc; ++i) {
		const char *arg = argv[i];
		if (strcmp(arg, "--debug") == 0) {
			debug = true;
		} else {
			request += string(arg) + string(" ");
		}
	}
	if (debug) {
		cout << "request: " << request << endl;
	}


	CommandProcShowDHCPLeases proc;

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




/**
 *
 **/
CommandProcShowDHCPLeases::CommandProcShowDHCPLeases()
{

}

/**
 *
 **/
CommandProcShowDHCPLeases::~CommandProcShowDHCPLeases()
{


}

/**
 *
 **/
std::string
CommandProcShowDHCPLeases::process(const string &cmd, bool debug, string &reason)
{
  bool active_leases;
  string pool;
  StrProc proc_str(cmd, " ");

  if (proc_str.size() == 3) {
    _xsl = XSLDIR "/" + proc_str.get(0);
    pool = proc_str.get(1);
    active_leases = false;
  }
  else if (proc_str.size() == 2 && proc_str.get(1) == "expired") {
    _xsl = XSLDIR "/" + proc_str.get(0);
    active_leases = false;
  }
  else if (proc_str.size() == 2) {
    _xsl = XSLDIR "/" + proc_str.get(0);
    pool = proc_str.get(1);
    active_leases = true;
  }
  else {
    _xsl = XSLDIR "/" + proc_str.get(0);
    active_leases = true;
  }

  reason = "";

  struct stat buf;
  if (stat("/var/run/dhcpd.pid", &buf) != 0) {
    reason = "DHCP server is not running";
    return string("");
  }
  
  //first thing, execute this command;
  if (cmd.empty() == false) {
    //    syslog(LOG_DEBUG | LOG_USER , "********* rl_cmd::execute(): %s\n", cmd.c_str());
    FILE *f = popen("cat /var/log/dhcpd.leases", "r");
    if (f) {
      char buf[2048];
      
      while(fgets(buf, 2048, f) != NULL) { 
//	printf("process line: %s\n", buf);
	string line(buf);
	convert_to_xml(line, pool, active_leases);
      } 
      if (pclose(f) != 0) {
	return string("");
      }
      complete_xml();
    }
  } 
  else {
    //    syslog(LOG_DEBUG | LOG_USER , "********* rl_cmd::execute(): command is empty\n");
  }

/*  if (_coll.empty() == true) {
    reason = "no clients leased";
    return string("");
  }*/

  _xml_out = "<opcommand name='dhcpleases'><format type='row'>";
  map<string, string>::iterator iter = _coll.begin();
  while (iter != _coll.end()) {
    _xml_out += "<row>" + iter->second + "</row>";
    ++iter;
  }
  _xml_out += "</format></opcommand>";


  string foo = cmd;
  debug = true;
  return _xml_out;
}

/**
 *
 * Sample lease file below
 *
 *

# All times in this file are in UTC (GMT), not your local timezone.   This is
# not a bug, so please don't ask about it.   There is no portable way to
# store leases in the local timezone, so please don't request this as a
# feature.   If this is inconvenient or confusing to you, we sincerely
# apologize.   Seriously, though - don't ask.
# The format of this file is documented in the dhcpd.leases(5) manual page.
# This lease file was written by isc-dhcp-V3.0.3

lease 10.0.0.236 {
  starts 4 2006/02/23 18:34:48;
  ends 5 2006/02/24 18:34:48;
  binding state active;
  next binding state free;
  hardware ethernet 00:12:3f:b3:02:b2;
}

*
*
**/
void 
CommandProcShowDHCPLeases::convert_to_xml(const string &line, const string &pool, bool active_leases)
{
  StrProc str_proc(line, " ");
  static int active_lease = 0;
  static int lease_state_backup = 1;

  if (line.find("lease") != string::npos) {
    _ip = str_proc.get(1);
    _coll.erase(_ip);
    _xml_frag = "<ip>" + str_proc.get(1) + "</ip>";
  }

  if (line.find("starts") != string::npos) {
    _xml_frag += "<start>" + str_proc.get(2) + " " + str_proc.get(3).substr(0, str_proc.get(3).length()-1) + "</start>";
  }

  if (line.find("ends") != string::npos) {
    _xml_frag += "<end>" + str_proc.get(2) + " " + str_proc.get(3).substr(0, str_proc.get(3).length()-1) + "</end>";
  }

  if (line.find("  binding") != string::npos) {
     if (str_proc.get(2) == "active;") {
         active_lease = 1;
         lease_state_backup = 0;
     }
     else if (str_proc.get(2) == "free;") {
         active_lease = 0;
         lease_state_backup = 0;
     }
     else {
 	 lease_state_backup = 1;
     }
        _xml_frag += "<bind_state>" + str_proc.get(2) + " " + "</bind_state>";
  }

  if (line.find("next binding") != string::npos) {
    _xml_frag += "<next_bind_state>" + str_proc.get(3) + " " + "</next_bind_state>";
  }

  if (line.find("hardware") != string::npos) {
    _xml_frag += "<hardware>" + str_proc.get(2).substr(0, str_proc.get(2).length()-1) + "</hardware>";
  }

  if (line.find("uid") != string::npos) {
    //skip uid as it is not used and has illegal xml characters
    //    _xml_frag += "<uid>" + str_proc.get(1).substr(0, str_proc.get(1).length()-1) + "</uid>";
    _xml_frag += "<uid></uid>";
  }
   
  if (line.find("client-hostname") != string::npos) {
    string::size_type indexQS = line.find_first_of("\"");
    string::size_type indexQE = line.find_last_of("\"");
    if (indexQS != string::npos && indexQE != string::npos && indexQS < indexQE) {
      std::string strClientHostname = line.substr(indexQS + 1, indexQE - indexQS - 1);
      if (strClientHostname.length() > 0) {
        _xml_frag += "<client_hostname>" + strClientHostname + "</client_hostname>";
      }
    }
  }

  if (line.find("shared-network") != string::npos) {
    _pool = str_proc.get(1).substr(0, str_proc.get(1).length());
    _xml_frag += "<shared_network>" + str_proc.get(1).substr(0, str_proc.get(1).length()) + "</shared_network>";
  }


  if (line.find("}") != string::npos) {
    //printf("before insertion: %s\n", _xml_frag.c_str());
    if (pool.empty() == false) {
      if (pool == _pool) {
       if (lease_state_backup == 0) {
         if (active_leases == true){ 
             if (active_lease == 1) {             
	     _coll.insert(pair<string, string>(_ip, _xml_frag));
            }
	 } else if (active_leases == false) {
                   if (active_lease == 0) {
 		      _coll.insert(pair<string, string>(_ip, _xml_frag));
		   }	
         } 	      
       } 
     }
    }
    else {
          if (lease_state_backup == 0) {
           if (active_leases == true){
             if (active_lease == 1) {
                 _coll.insert(pair<string, string>(_ip, _xml_frag));
	     }
         } else if (active_leases == false) {
		   if (active_lease == 0) {
	   		_coll.insert(pair<string, string>(_ip, _xml_frag));
		   } 
	}
      }
    } 
  } 
  return;
}

/**
 *
 **/
void
CommandProcShowDHCPLeases::complete_xml()
{
  if (_xml_out.empty() == false) {
    _xml_out += "</format></opcommand>";
  }
}
