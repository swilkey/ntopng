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

void SYNFlood::periodicUpdate(Host *h, std::list<HostAlert*> *engaged_alerts) {
  static u_int8_t attacker_score = 100, victim_score = 20;
  std::list<HostAlert*>::iterator it;
  u_int16_t hits = 0;
  bool already_engaged;

  if((hits = h->syn_flood_attacker_hits()) >= syns_threshold) {
    SYNFloodAttackerAlert *attacker_alert = NULL;

    already_engaged = false;
    for (it = engaged_alerts->begin(); it != engaged_alerts->end(); ++it)
      if ((*it)->equals(SYNFloodAttackerAlert::getClassType()))
        attacker_alert = static_cast<SYNFloodAttackerAlert*>(*it), already_engaged = true;

    if (!already_engaged)
       attacker_alert = new SYNFloodAttackerAlert(this, h); 

    if (attacker_alert) {
      attacker_alert->setSeverity(alert_level_error);
      attacker_alert->setCliScore(attacker_score);
      attacker_alert->setHits(hits);
      attacker_alert->setThreshold(syns_threshold);
      if (!already_engaged) h->triggerAlert(attacker_alert);
    }
  }

  if((hits = h->syn_flood_victim_hits()) >= syns_threshold) {
    SYNFloodVictimAlert *victim_alert = NULL;

    already_engaged = false;
    for (it = engaged_alerts->begin(); it != engaged_alerts->end(); ++it)
      if ((*it)->equals(SYNFloodVictimAlert::getClassType()))
        victim_alert = static_cast<SYNFloodVictimAlert*>(*it), already_engaged = true;

    if (!already_engaged)
       victim_alert = new SYNFloodVictimAlert(this, h); 

    if (victim_alert) {
      victim_alert->setSeverity(alert_level_error);
      victim_alert->setCliScore(victim_score);
      victim_alert->setHits(hits);
      victim_alert->setThreshold(syns_threshold);
      if (!already_engaged) h->triggerAlert(victim_alert);
    }
  }

  /* Reset counters once done */
  h->reset_syn_flood_hits();  
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

