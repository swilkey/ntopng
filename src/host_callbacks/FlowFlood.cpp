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

#include "ntop_includes.h"
#include "host_callbacks_includes.h"

/* ***************************************************** */

FlowFlood::FlowFlood() : HostCallback(ntopng_edition_community) {
  flows_threshold = (u_int64_t)-1;
};

/* ***************************************************** */

void FlowFlood::periodicUpdate(Host *h) {
  static u_int8_t attacker_score = 100, victim_score = 20;
  char buf[64];

  ntop->getTrace()->traceEvent(TRACE_NORMAL, "%s PERIODIC UPDATE %s", getName().c_str(), h->get_ip()->print(buf, sizeof(buf)));

  /* Attacker alert has priority over the Victim alert */
  if(h->flow_flood_attacker_hits() >= flows_threshold)
    h->triggerAlertAsync(FlowFloodAttackerAlert::getClassType(), alert_level_error, attacker_score);
  else if(true || h->flow_flood_victim_hits() >= flows_threshold)
    h->triggerAlertAsync(FlowFloodVictimAlert::getClassType(), alert_level_error, victim_score);
}

/* ***************************************************** */

HostAlert *FlowFlood::buildAlert(HostAlertType t, Host *h) {
  FlowFloodAlert *ffa = NULL;

  switch(t.id) {
  case host_alert_flow_flood_attacker:
    ffa = new FlowFloodAttackerAlert(this, h, h->flow_flood_attacker_hits() /* Actual attacker hits */, flows_threshold);
    break;
  case host_alert_flow_flood_victim:
    ffa = new FlowFloodVictimAlert(this, h, h->flow_flood_victim_hits() /* Actual victim hits */, flows_threshold);
  default:
    break;
  }

  /* Reset counters once done */
  h->reset_flow_flood_hits();
  
  return ffa;
}

/* ***************************************************** */

bool FlowFlood::loadConfiguration(json_object *config) {
  json_object *json_threshold;

  HostCallback::loadConfiguration(config); /* Parse parameters in common */

  if(json_object_object_get_ex(config, "threshold", &json_threshold))
    flows_threshold = json_object_get_int64(json_threshold);

  // ntop->getTrace()->traceEvent(TRACE_NORMAL, "%s", json_object_to_json_string(config));

  return(true);
}

/* ***************************************************** */

