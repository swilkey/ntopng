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

/* **************************************************** */

HostAlert::HostAlert(HostCallback *c, Host *h) {
  host = h;
  severity_id = alert_level_notice;
  expiring = released = false;
  callback_type = c->getType();
  callback_name = c->getName();
  engage_time = time(NULL);
  release_time = 0;
  auto_release = true;
}

/* **************************************************** */

HostAlert::~HostAlert() {
}

/* **************************************************** */

/* This will parse the configuration specific to this alert, including it's default severity */
bool HostAlert::loadConfiguration(json_object *config) {
  bool rc = true;

  // ntop->getTrace()->traceEvent(TRACE_NORMAL, "%s() %s", __FUNCTION__, json_object_to_json_string(config));

  /* Read and parse the default severity */

  /* TODO
  json_object *json_severity, *json_severity_id;


  if(json_object_object_get_ex(config, "severity", &json_severity)
     && json_object_object_get_ex(json_severity, "severity_id", &json_severity_id)) {
    if((severity_id = (AlertLevel)json_object_get_int(json_severity_id)) >= ALERT_LEVEL_MAX_LEVEL)
      severity_id = alert_level_emergency;
  }
  */
  
  return(rc);
}

/* ***************************************************** */

ndpi_serializer* HostAlert::getSerializedAlert() {
  char buf[64];
  ndpi_serializer *serializer = (ndpi_serializer *) malloc(sizeof(ndpi_serializer));
  
  if(serializer == NULL)
    return NULL;

  if(ndpi_init_serializer(serializer, ndpi_serialization_format_json) == -1) {
    free(serializer);
    return NULL;
  }

  /* Add here global callback information, common to any alerted host */

  /* Add information relative to this callback */
  ndpi_serialize_start_of_block(serializer, "alert_generation");
  ndpi_serialize_string_string(serializer, "script_key", getCallbackName().c_str());
  ndpi_serialize_string_string(serializer, "subdir", "host");

  ndpi_serialize_start_of_block(serializer, "host_info");
  
  ndpi_serialize_string_string(serializer, "name", host->get_visual_name(buf, sizeof(buf)));
  ndpi_serialize_string_boolean(serializer, "localhost", host->isLocalHost());
  ndpi_serialize_string_boolean(serializer, "systemhost", host->isSystemHost());
  ndpi_serialize_string_boolean(serializer, "privatehost", host->isPrivateHost());
  ndpi_serialize_string_boolean(serializer, "broadcast_domain_host", host->isBroadcastDomainHost());
  ndpi_serialize_string_boolean(serializer, "dhcpHost", host->isDhcpHost());
  ndpi_serialize_string_boolean(serializer, "is_blacklisted", host->isBlacklisted());
  ndpi_serialize_string_boolean(serializer, "is_broadcast", host->isBroadcastHost());
  ndpi_serialize_string_boolean(serializer, "is_multicast", host->isMulticastHost());
  
#ifdef HAVE_NEDGE
  ndpi_serialize_string_boolean(serializer, "childSafe", host->isChildSafe());
  ndpi_serialize_string_boolean(serializer, "drop_all_host_traffic", host->dropAllTraffic());
#endif


  ndpi_serialize_end_of_block(serializer); /* host_info        */
  ndpi_serialize_end_of_block(serializer); /* alert_generation */
  
  /* This call adds callback-specific information to the serializer */
  getAlertJSON(serializer);

  return serializer;
}
