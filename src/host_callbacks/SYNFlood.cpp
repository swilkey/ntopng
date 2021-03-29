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

void SYNFlood::periodicUpdate(Host *h) {
  char buf[64];

  ntop->getTrace()->traceEvent(TRACE_NORMAL, "%s PERIODIC UPDATE %s", getName().c_str(), h->get_ip()->print(buf, sizeof(buf)));
  u_int8_t score_inc = 20;
  u_int16_t victim_hits, attacker_hits;

  if((victim_hits = h->syn_flood_victim_hits()))
    h->triggerAlertAsync(SYNFloodVictimAlert::getClassType(), alert_level_error, score_inc); /* Trigger SYN flood victim alert, with victim_hits */

  if((attacker_hits = h->syn_flood_attacker_hits()))
    h->triggerAlertAsync(SYNFloodAttackerAlert::getClassType(), alert_level_error, score_inc); /* Trigger SYN flood attacker alert, with attcker_hits */
}

/* ***************************************************** */

HostAlert *SYNFlood::buildAlert(HostAlertType t, Host *h) {
  SYNFloodAttackerAlert *res = new SYNFloodAttackerAlert(this, h);

  /* Reset counters once done */
  h->reset_syn_flood_hits();
  
  return res;
}

/* ***************************************************** */

bool SYNFlood::loadConfiguration(json_object *config) {
  HostCallback::loadConfiguration(config); /* Parse parameters in common */
  /*
    ntop->getTrace()->traceEvent(TRACE_NORMAL, "%s", json_object_to_json_string(config));
  */

  return(true);
}

/* ***************************************************** */

