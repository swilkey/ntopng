/*
 *
 * (C) 2021 - ntop.org
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

/* ****************************************** */

HostAlertableEntity::HostAlertableEntity(NetworkInterface *iface, AlertEntity entity) : AlertableEntity(iface, entity) {
}

/* ****************************************** */

HostAlertableEntity::~HostAlertableEntity() {
  clearEngagedAlerts();
}

/* *************************************** */

void HostAlertableEntity::addEngagedAlert(HostAlert *a) {
  engaged_alerts_lock.wrlock(__FILE__, __LINE__);

  engaged_alerts[a->getCallbackType()].push_back(a); 
  engaged_alerts_map.setBit(a->getAlertType().id);

  engaged_alerts_lock.unlock(__FILE__, __LINE__);
} 

/* *************************************** */

void HostAlertableEntity::removeEngagedAlert(HostAlert *a) { 
  engaged_alerts_lock.wrlock(__FILE__, __LINE__);

  engaged_alerts[a->getCallbackType()].remove(a);
  engaged_alerts_map.clearBit(a->getAlertType().id);

  engaged_alerts_lock.unlock(__FILE__, __LINE__);
}

/* *************************************** */

HostAlert *HostAlertableEntity::findEngagedAlert(HostAlertType alert_type, HostCallbackType callback_type) {
  if (isEngagedAlert(alert_type))
    for(std::list<HostAlert*>::iterator it = engaged_alerts[callback_type].begin(); it != engaged_alerts[callback_type].end(); ++it)
      if ((*it)->getAlertType().id == alert_type.id)
        return (*it);

  return NULL;
}

/* *************************************** */

void HostAlertableEntity::clearEngagedAlerts() {
  for (u_int i = 0; i < NUM_DEFINED_HOST_CALLBACKS; i++) {
    std::list<HostAlert*>::iterator it = engaged_alerts[i].begin();
    while (it != engaged_alerts[i].end()) {
      HostAlert *a = (*it);
      ++it; /* inc the iterator before removing */
      removeEngagedAlert(a);
      delete a;
    }
  }
}

/* ****************************************** */

void HostAlertableEntity::countAlerts(grouped_alerts_counters *counters) {
  engaged_alerts_lock.rdlock(__FILE__, __LINE__);

  for (u_int i = 0; i < NUM_DEFINED_HOST_CALLBACKS; i++) {
    for(std::list<HostAlert*>::iterator it = engaged_alerts[i].begin(); it != engaged_alerts[i].end(); ++it) {
      HostAlert *alert = (*it);
      counters->severities[alert->getSeverity()]++;
      counters->types[alert->getAlertType().id]++;
    }
  }

  engaged_alerts_lock.unlock(__FILE__, __LINE__);
}

/* ****************************************** */

void HostAlertableEntity::luaAlert(lua_State* vm, HostAlert *alert) {
  ndpi_serializer *alert_json_serializer = NULL;
  char *alert_json = NULL;
  u_int32_t alert_json_len;

  /* NOTE: must conform to the AlertsManager format */
  lua_push_int32_table_entry(vm,  "alert_type", alert->getAlertType().id);
  lua_push_str_table_entry(vm,    "alert_subtype", "" /* No subtype for hosts */);
  lua_push_int32_table_entry(vm,  "alert_severity", alert->getSeverity());
  lua_push_int32_table_entry(vm,  "alert_entity", alert_entity_host);
  lua_push_str_table_entry(vm,    "alert_entity_val", alert->getHost()->getEntityValue().c_str());
  lua_push_uint64_table_entry(vm, "alert_tstamp", alert->getEngageTime());
  lua_push_uint64_table_entry(vm, "alert_tstamp_end", alert->getReleaseTime());

  HostCallback *cb = getAlertInterface()->getCallback(alert->getCallbackType());
  lua_push_int32_table_entry(vm,  "alert_granularity", cb ? cb->getPeriod() : 0);

  alert_json_serializer = alert->getSerializedAlert();
  if(alert_json_serializer)
    alert_json = ndpi_serializer_get_buffer(alert_json_serializer, &alert_json_len);

  lua_push_str_table_entry(vm,    "alert_json", alert_json ? alert_json : "");
 
  if(alert_json_serializer) {
    ndpi_term_serializer(alert_json_serializer);
    free(alert_json_serializer);
  }
}

/* ****************************************** */

void HostAlertableEntity::getAlerts(lua_State* vm, ScriptPeriodicity p /* not used */,
  AlertType type_filter, AlertLevel severity_filter, u_int *idx) {

  engaged_alerts_lock.rdlock(__FILE__, __LINE__);

  for (u_int i = 0; i < NUM_DEFINED_HOST_CALLBACKS; i++) {
    for(std::list<HostAlert*>::iterator it = engaged_alerts[i].begin(); it != engaged_alerts[i].end(); ++it) {
      HostAlert *alert = (*it);

      if ((type_filter == alert_none || type_filter == alert->getAlertType().id) &&
          (severity_filter == alert_level_none || severity_filter == alert->getSeverity())) {
        lua_newtable(vm);
        luaAlert(vm, alert);

        lua_pushinteger(vm, ++(*idx));
        lua_insert(vm, -2);
        lua_settable(vm, -3);
      }
    }
  }

  engaged_alerts_lock.unlock(__FILE__, __LINE__);
}

/* ****************************************** */
