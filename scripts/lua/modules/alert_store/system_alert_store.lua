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

local system_alert_store = {}

-- ##############################################

function system_alert_store:new(args)
   -- Instance of the base class
   local _system_alert_store = alert_store:new()

   -- Subclass using the base class instance
   self.key = "system"
   self._table_name = "system_alerts"

   -- self is passed as argument so it will be set as base class metatable
   -- and this will actually make it possible to override functions
   local _system_alert_store_instance = _system_alert_store:new(self)

   -- Return the instance
   return _system_alert_store_instance
end

-- ##############################################

function system_alert_store:insert(alert)
   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, tstamp, tstamp_end, severity, name, json) "..
      "VALUES (%u, %u, %u, %u, '%s', '%s'); ",
      self._table_name, 
      alert.alert_type,
      alert.alert_tstamp,
      alert.alert_tstamp_end,
      alert.alert_severity,
      self:_escape(alert.alert_entity_val),
      self:_escape(alert.alert_json))

   -- traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
end

-- ##############################################

return system_alert_store
