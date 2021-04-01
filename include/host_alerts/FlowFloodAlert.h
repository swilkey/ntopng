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

#ifndef _FLOW_FLOOD_ALERT_H_
#define _FLOW_FLOOD_ALERT_H_


#include "ntop_includes.h"


class FlowFloodAlert : public HostAlert {
 private:
  u_int64_t flows, flows_threshold;
  bool is_attacker;

  ndpi_serializer* getAlertJSON(ndpi_serializer* serializer);
  
 public:
  static HostAlertType getClassType() { return { host_alert_flow_flood, alert_category_security }; }

  FlowFloodAlert(HostCallback *c, Host *f, bool is_attacker);
  ~FlowFloodAlert() {};

  HostAlertType getAlertType() const { return getClassType(); }

  void toggleAttacker(bool _is_attacker) { is_attacker = _is_attacker; }
  void setFlows(u_int64_t _flows) { flows = _flows;}
  void setThreshold(u_int64_t _flows_threshold) { flows_threshold = _flows_threshold; }
};

#endif /* _FLOW_FLOOD_ALERT_H_ */
