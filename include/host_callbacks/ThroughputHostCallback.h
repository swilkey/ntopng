/*
 *
 * (C) 2013-21 - ntop.org
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 */

#ifndef _THROUGHPUT_HOST_CALLBACK_H_
#define _THROUGHPUT_HOST_CALLBACK_H_

#include "ntop_includes.h"

class ThroughputHostCallback : public HostCallback {
private:
  u_int64_t throughput_threshold;    

 public:
  ThroughputHostCallback();
  ~ThroughputHostCallback() {};

  void periodicUpdate(Host *h, std::list<HostAlert*> *engaged_alerts);

  bool loadConfiguration(json_object *config);  

  HostCallbackStatus *allocStatus() { return new DeltaHostCallbackStatus(this); };

  HostCallbackType getType() const { return host_callback_throughput_host; } 
  std::string getName()        const { return(std::string("throughput")); }
};

#endif
