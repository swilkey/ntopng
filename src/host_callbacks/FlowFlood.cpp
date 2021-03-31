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

template<class T> void FlowFlood::triggerFlowFloodAlert(Host *h, std::list<HostAlert*> *engaged,
    u_int16_t flows, u_int64_t threshold, u_int8_t cli_score, u_int8_t srv_score) {
  std::list<HostAlert*>::iterator it;
  bool already_engaged = false;
  T *alert = NULL;

  /* Check alerts already engaged */
  for (it = engaged->begin(); it != engaged->end(); ++it)
    if ((*it)->equals(T::getClassType()))
      alert = static_cast<T*>(*it), already_engaged = true;

  /* New alert */
  if (!already_engaged)
     alert = new T(this, h); 

  if (alert) {
    /* Set alert info */
    alert->setSeverity(alert_level_error);
    alert->setCliScore(cli_score);
    alert->setSrvScore(srv_score);
    alert->setFlows(flows);
    alert->setThreshold(threshold);

    /* Trigger if new */
    if (!already_engaged) h->triggerAlert(alert);
  }
}

/* ***************************************************** */

void FlowFlood::periodicUpdate(Host *h, std::list<HostAlert*> *engaged_alerts) {
  u_int16_t flows = 0;

  if((flows = h->flow_flood_attacker_hits()) >= flows_threshold)
    triggerFlowFloodAlert<FlowFloodAttackerAlert>(h, engaged_alerts, flows, flows_threshold, 100, 0);

  if((flows = h->flow_flood_victim_hits()) >= flows_threshold)
    triggerFlowFloodAlert<FlowFloodVictimAlert>(h, engaged_alerts, flows, flows_threshold, 0, 20);

  /* Reset counters once done */
  h->reset_flow_flood_hits();
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

