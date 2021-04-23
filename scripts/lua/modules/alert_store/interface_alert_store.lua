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

local interface_alert_store = classes.class(alert_store)

-- ##############################################

function interface_alert_store:init(args)
   self.super:init()

   self._table_name = "interface_alerts"
end

-- ##############################################

function interface_alert_store:insert(alert)
   local name = getInterfaceName(alert.ifid)
   local alias = getHumanReadableInterfaceName(name)

   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, tstamp, tstamp_end, severity, ifid, name, alias, granularity, json) "..
      "VALUES (%u, %u, %u, %u, %u, '%s', '%s', %u, '%s'); ",
      self._table_name, 
      alert.alert_id,
      alert.tstamp,
      alert.tstamp_end,
      alert.severity,
      alert.ifid,
      self:_escape(name),
      self:_escape(alias),
      self:_escape(alert.entity_val),
      alert.granularity,
      self:_escape(alert.json))

   -- traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
end

-- ##############################################

--@brief Add filters according to what is specified inside the REST API
function interface_alert_store:_add_additional_request_filters()
   -- Add filters specific to the system family
end

-- ##############################################

return interface_alert_store
