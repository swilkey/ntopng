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

SYNFlood::SYNFlood() : HostCallback(ntopng_edition_community) {
  syns_threshold = (u_int64_t)-1;
};

/* ***************************************************** */

void SYNFlood::periodicUpdate(Host *h) {
  static u_int8_t attacker_score = 100, victim_score = 20;
  u_int16_t hits = 0;
  char buf[64];
  SYNFloodHostCallbackStatus *status = static_cast<SYNFloodHostCallbackStatus*>(getStatus(h));

  ntop->getTrace()->traceEvent(TRACE_NORMAL, "%s PERIODIC UPDATE %s", getName().c_str(), h->get_ip()->print(buf, sizeof(buf)));

  /* Attacker alert has priority over the Victim alert */
  if((hits = h->syn_flood_attacker_hits()) >= syns_threshold)
    h->triggerAlertAsync(SYNFloodAttackerAlert::getClassType(), alert_level_error, attacker_score, 0);
  else if((hits = h->syn_flood_victim_hits()) >= syns_threshold)
    h->triggerAlertAsync(SYNFloodVictimAlert::getClassType(), alert_level_error, 0, victim_score);

  /* Updates the status with the hits detected. This will be possibly used later by buildAlert */
  if(status) status->updateHits(hits);

  /* Reset counters once done */
  h->reset_syn_flood_hits();  
}

/* ***************************************************** */

HostAlert *SYNFlood::buildAlert(HostAlertType t, Host *h) {
  SYNFloodHostCallbackStatus *status = static_cast<SYNFloodHostCallbackStatus*>(getStatus(h));
  SYNFloodAlert *sfa = NULL;

  switch(t.id) {
  case host_alert_syn_flood_attacker:
    sfa = new SYNFloodAttackerAlert(this, h, status ? status->getHits() : 0 /* Actual hits */, syns_threshold);
    break;
  case host_alert_syn_flood_victim:
    sfa = new SYNFloodVictimAlert(this, h, status ? status->getHits() : 0 /* Actual hits */, syns_threshold);
  default:
    break;
  }
  
  return sfa;
}

/* ***************************************************** */

bool SYNFlood::loadConfiguration(json_object *config) {
  json_object *json_threshold;

  HostCallback::loadConfiguration(config); /* Parse parameters in common */

  if(json_object_object_get_ex(config, "threshold", &json_threshold))
    syns_threshold = json_object_get_int64(json_threshold);

  // ntop->getTrace()->traceEvent(TRACE_NORMAL, "%s", json_object_to_json_string(config));

  return(true);
}

/* ***************************************************** */

