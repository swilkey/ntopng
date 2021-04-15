--
-- (C) 2021-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

-- Import the classes library.
local classes = require "classes"

require "lua_utils"
local alert_store = require "alert_store"
local alert_consts = require "alert_consts"
local alert_entities = require "alert_entities"
local json = require "dkjson"

-- ##############################################

local host_alert_store = classes.class(alert_store)

-- ##############################################

function host_alert_store:init(args)
   self.super:init()

   self._table_name = "host_alerts"
   self._alert_entity = alert_entities.host
end

-- ##############################################

function host_alert_store:insert(alert)
   local hostinfo = hostkey2hostinfo(alert.alert_entity_val)
   local is_attacker = ternary(alert.is_attacker, 1, 0)
   local is_victim = ternary(alert.is_victim, 1, 0)

   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, ip, vlan_id, name, is_attacker, is_victim, tstamp, tstamp_end, severity, json) "..
      "VALUES (%u, '%s', %u, '%s', %u, %u, %u, %u, %u, '%s'); ",
      self._table_name, 
      alert.alert_type,
      hostinfo["host"],
      hostinfo["vlan"] or 0,
      self:_escape(alert.symbolic_name),
      is_attacker,
      is_victim,
      alert.alert_tstamp,
      alert.alert_tstamp_end,
      alert.alert_severity,
      self:_escape(alert.alert_json))

   -- traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
end

-- ##############################################

--@brief Add filters according to what is specified inside the REST API
function host_alert_store:_add_additional_request_filters()
   -- Add filters specific to the host family
end

-- ##############################################

function host_alert_store:add_host_filter(host)
   if isIPv4(host) or isIPv6(host) then
      self._where[#self._where + 1] = string.format("ip = '%s'", host)
      return true
   end

   return false
end

-- ##############################################

function host_alert_store:add_vlan_filter(vlan_id)
   if tonumber(vlan_id) then
      self._where[#self._where + 1] = string.format("vlan_id = %u", vlan_id) 
      return true
   end

   return false
end

-- ##############################################

return host_alert_store
