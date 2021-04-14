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

local snmp_alert_store = {}

-- ##############################################

function snmp_alert_store:new(args)
   -- Instance of the base class
   local _snmp_alert_store = alert_store:new()

   -- Subclass using the base class instance
   self.key = "snmp"
   self._table_name = "snmp_alerts"

   -- self is passed as argument so it will be set as base class metatable
   -- and this will actually make it possible to override functions
   local _snmp_alert_store_instance = _snmp_alert_store:new(self)

   -- Return the instance
   return _snmp_alert_store_instance
end

-- ##############################################

function snmp_alert_store:insert(alert)
   local device_ip
   local device_name
   local port
   local port_name

   if not isEmptyString(alert.alert_json) then
      local snmp_json = json.decode(alert.alert_json)
      if snmp_json then
         device_ip = snmp_json.device
         device_name = snmp_json.device_name
         port = snmp_json.interface
         port_name = snmp_json.interface_name
      end
   end

   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, tstamp, tstamp_end, severity, ip, name, port, port_name, json) "..
      "VALUES (%u, %u, %u, %u, '%s', '%s', %u, '%s', '%s'); ",
      self._table_name, 
      alert.alert_type,
      alert.alert_tstamp,
      alert.alert_tstamp_end,
      alert.alert_severity,
      self:_escape(device_ip or alert.alert_entity_val),
      self:_escape(device_name),
      port or 0,
      self:_escape(port_name),
      self:_escape(alert.alert_json))

   -- traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
end

-- ##############################################

return snmp_alert_store
