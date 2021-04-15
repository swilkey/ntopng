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

local am_alert_store = classes.class(alert_store)

-- ##############################################

function am_alert_store:init(args)
   self.super:init()

   self._table_name = "active_monitoring_alerts"
end

-- ##############################################

function am_alert_store:insert(alert)
   local resolved_ip
   local resolved_name
   local measure_threshold
   local measure_value

   if not isEmptyString(alert.alert_json) then
      local am_json = json.decode(alert.alert_json)
      if am_json then
         resolved_ip = am_json.ip
         if am_json.host then
            resolved_name = am_json.host.host
         end
         measure_threshold = am_json.threshold
         measure_value = am_json.value
      end
   end

   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, tstamp, tstamp_end, severity, interface_id, resolved_ip, resolved_name, "..
      "measure_threshold, measure_value, json) "..
      "VALUES (%u, %u, %u, %u, %d, '%s', '%s', %u, %f, '%s'); ",
      self._table_name, 
      alert.alert_type,
      alert.alert_tstamp,
      alert.alert_tstamp_end,
      alert.alert_severity,
      getSystemInterfaceId(),
      self:_escape(resolved_ip),
      self:_escape(resolved_name),
      measure_threshold or 0,
      measure_value or 0,
      self:_escape(alert.alert_json))

   -- traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
end

-- ##############################################

return am_alert_store
