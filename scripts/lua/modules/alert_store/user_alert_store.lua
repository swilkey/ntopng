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

local user_alert_store = classes.class(alert_store)

-- ##############################################

function user_alert_store:init(args)
   self.super:init()

   self._table_name = "user_alerts"
end

-- ##############################################

function user_alert_store:insert(alert)

   -- TODO add user

   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, tstamp, tstamp_end, severity, name, granularity, json) "..
      "VALUES (%u, %u, %u, %u, %u, '%s', %u, '%s'); ",
      self._table_name, 
      alert.alert_type, -- TODO rename to alert_id
      alert.alert_tstamp,
      alert.alert_tstamp_end,
      alert.alert_severity,
      self:_escape(alert.alert_entity_val),
      alert.alert_granularity,
      self:_escape(alert.alert_json))

   -- traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
end

-- ##############################################

--@brief Add filters according to what is specified inside the REST API
function user_alert_store:_add_additional_request_filters()
   -- Add filters specific to the system family
end

-- ##############################################

return user_alert_store
