--
-- (C) 2021-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

-- Import the classes library.
local classes = require "classes"

require "lua_utils"
local alert_store = require "alert_store"
local alert_consts = require "alert_consts"
local json = require "dkjson"

-- ##############################################

local mac_alert_store =  classes.class(alert_store)

-- ##############################################

function mac_alert_store:init(args)
   self.super:init()

   self._table_name = "mac_alerts"
end

-- ##############################################

function mac_alert_store:insert(alert)
   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, tstamp, tstamp_end, severity, address, device_type, name, "..
      "is_attacker, is_victim, json) "..
      "VALUES (%u, %u, %u, %u, '%s', %u, '%s', %u, %u, '%s'); ",
      self._table_name, 
      alert.alert_type,
      alert.alert_tstamp,
      alert.alert_tstamp_end,
      alert.alert_severity,
      self:_escape(alert.alert_entity_val),
      alert.device_type or 0,
      self:_escape(alert.device_name),
      ternary(alert.is_attacker, 1, 0),
      ternary(alert.is_victim, 1, 0),
      self:_escape(alert.alert_json))

   -- traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
end

-- ##############################################

--@brief Add filters according to what is specified inside the REST API
function mac_alert_store:add_request_filters()
   -- Parse common params of the base class
   self.super:add_request_filters()

   -- Add filters specific to the mac family
end

-- ##############################################

return mac_alert_store
