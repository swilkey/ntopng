--
-- (C) 2021-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

require "lua_utils"
local alert_store = require "alert_store"
local alert_consts = require "alert_consts"
local json = require "dkjson"

-- ##############################################

local host_alert_store = {}

-- ##############################################

function host_alert_store:new(args)
   -- Instance of the base class
   local _host_alert_store = alert_store:new()

   -- Subclass using the base class instance
   self.key = "host"
   self._table_name = "host_alerts"

   -- self is passed as argument so it will be set as base class metatable
   -- and this will actually make it possible to override functions
   local _host_alert_store_instance = _host_alert_store:new(self)

   -- Return the instance
   return _host_alert_store_instance
end

-- ##############################################

function host_alert_store:insert(alert)
   local table_name = "host_alerts"
  
   local hostinfo = hostkey2hostinfo(alert.alert_entity_val)
   local ip = hostinfo["host"]
   local vlan_id = hostinfo["vlan"] or 0
   local host_name = alert.symbolic_name or ""
   local is_attacker = ternary(alert.is_attacker, 1, 0) -- TODO
   local is_victim = ternary(alert.is_victim, 1, 0) -- TODO
   local json = alert.alert_json or ""

   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, ip, vlan_id, name, is_attacker, is_victim, tstamp, tstamp_end, severity, json) "..
      "VALUES (%u, '%s', %u, '%s', %u, %u, %u, %u, %u, '%s'); ",
      table_name,
      alert.alert_type,
      ip,
      vlan_id,
      self:_escape(host_name),
      is_attacker,
      is_victim,
      alert.alert_tstamp,
      alert.alert_tstamp_end,
      alert.alert_severity,
      self._escape(json))

   -- traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
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
