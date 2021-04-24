--
-- (C) 2021-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

-- Import the classes library.
local classes = require "classes"

require "lua_utils"
local alert_store = require "alert_store"
local format_utils = require "format_utils"
local alert_consts = require "alert_consts"
local alert_utils = require "alert_utils"
local alert_entities = require "alert_entities"
local json = require "dkjson"

-- ##############################################

local network_alert_store = classes.class(alert_store)

-- ##############################################

function network_alert_store:init(args)
   self.super:init()

   self._table_name = "network_alerts"
   self._alert_entity = alert_entities.network
end

-- ##############################################

function network_alert_store:insert(alert)
   local name = alert.entity_val
   local alias = getLocalNetworkAlias(name)

   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, tstamp, tstamp_end, severity, local_network_id, name, alias, granularity, json) "..
      "VALUES (%u, %u, %u, %u, %u, '%s', '%s', %u, '%s'); ",
      self._table_name, 
      alert.alert_id,
      alert.tstamp,
      alert.tstamp_end,
      alert.severity,
      ntop.getLocalNetworkID(name),
      self:_escape(name),
      self:_escape(alias),
      alert.granularity,
      self:_escape(alert.json))

   -- traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
end

-- ##############################################

--@brief Add filters according to what is specified inside the REST API
function network_alert_store:_add_additional_request_filters()
   -- Add filters specific to the system family
end

-- ##############################################

--@brief Convert an alert coming from the DB (value) to a record returned by the REST API
function network_alert_store:format_record(value)
   local record = self:format_record_common(value, alert_entities.network.entity_id)

   local alert_id_label = alert_consts.alertTypeLabel(tonumber(value["alert_id"]), false)
   local alert_info = alert_utils.getAlertInfo(value)
   local msg = alert_utils.formatAlertMessage(ifid, value, alert_info)

   record["duration"] = duration
   record["name"] = {
      label = alert_id_label,
      value = value["alert_id"]
   }
   record["msg"] = msg

   return record
end

-- ##############################################

return network_alert_store
