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

ServerContacts::ServerContacts() : HostCallback(ntopng_edition_community) {
};

/* ***************************************************** */

void ServerContacts::periodicUpdate(Host *h, std::list<HostAlert*> *engaged_alerts) {
  static const u_int8_t cli_score = 50;
  u_int32_t contacted_servers = 0;
  ServerContactsHostCallbackStatus *status = static_cast<ServerContactsHostCallbackStatus*>(getStatus(h));

  if((contacted_servers = getContactedServers(h)) >= contacts_threshold) {
    HostAlert *ha = allocAlert(this, h, status ? status->getContacts() : 0, contacts_threshold);
    //TODO alert_level_error, cli_score /* Attacker */, 0 /* Victim */
    h->triggerAlert(ha);
  }

  if(status) status->updateContacts(contacted_servers);

  /* TODO: reset contacted servers cardinality */
}

/* ***************************************************** */

bool ServerContacts::loadConfiguration(json_object *config) {
  HostCallback::loadConfiguration(config); /* Parse parameters in common */

  // ntop->getTrace()->traceEvent(TRACE_NORMAL, "%s", json_object_to_json_string(config));

  return(true);
}

/* ***************************************************** */

