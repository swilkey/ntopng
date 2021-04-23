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

local flow_alert_store = classes.class(alert_store)

-- ##############################################

function flow_alert_store:init(args)
   self.super:init()

   self._table_name = "flow_alerts"
   self._alert_entity = alert_entities.flow
end

-- ##############################################

function flow_alert_store:insert(alert)
   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, tstamp, tstamp_end, severity, cli_ip, srv_ip, cli_port, srv_port, vlan_id, "..
      "is_attacker_to_victim, is_victim_to_attacker, proto, l7_proto, l7_master_proto, l7_cat, "..
      "cli_name, srv_name, cli_country, srv_country, cli_blacklisted, srv_blacklisted, "..
      "cli2srv_bytes, srv2cli_bytes, cli2srv_pkts, srv2cli_pkts, first_seen, community_id, score, "..
      "flow_risk_bitmap, json) "..
      "VALUES (%u, %u, %u, %u, '%s', '%s', %u, %u, %u, %u, %u, %u, %u, %u, %u, '%s', '%s', '%s', "..
      "'%s', %u, %u, %u, %u, %u, %u, %u, '%s', %u, %u, '%s'); ",
      self._table_name, 
      alert.alert_id,
      alert.tstamp,
      alert.tstamp,
      alert.severity,
      alert.cli_addr,
      alert.srv_addr,
      alert.cli_port,
      alert.srv_port,
      alert.vlan_id,
      ternary(alert.is_cli_attacker, 1, 0),
      ternary(alert.is_srv_attacker, 1, 0),
      alert.proto,
      alert.l7_proto,
      alert.l7_master_proto,
      alert.l7_cat,
      self:_escape(alert.cli_name),
      self:_escape(alert.srv_name),
      alert.cli_country_name,
      alert.srv_country_name,
      ternary(alert.cli_blacklisted, 1, 0),
      ternary(alert.srv_blacklisted, 1, 0),
      alert.cli2srv_bytes,
      alert.srv2cli_bytes,
      alert.cli2srv_packets,
      alert.srv2cli_packets,
      alert.first_seen,
      alert.community_id,
      alert.score,
      alert.flow_risk_bitmap or 0,
      self:_escape(alert.json)
   )

   -- traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
end

-- ##############################################

--@brief Add filters according to what is specified inside the REST API
function flow_alert_store:_add_additional_request_filters()
   -- Add filters specific to the flow family
end

-- ##############################################

--@brief Convert an alert coming from the DB (value) to a record returned by the REST API
function flow_alert_store:format_record(value)
   local record = self:format_record_common(value, alert_entities.flow.entity_id)

   local score = tonumber(value["score"])
   local alert_info = alert_utils.getAlertInfo(value)
   local msg = alert_utils.formatFlowAlertMessage(ifid, value, alert_info)
   local application =  interface.getnDPIProtoName(tonumber(value["l7_proto"]))

   record["score"] = score
   record["msg"] = msg
   record["cli_name"] = value["cli_name"]
   record["srv_name"] = value["srv_name"]
   record["cli_ip"] = value["cli_ip"]
   record["srv_ip"] = value["srv_ip"]
   record["cli_port"] = value["cli_port"]
   record["srv_port"] = value["srv_port"]
   record["vlan_id"] = value["vlan_id"]
   record["proto"] = value["proto"]
   record["is_attacker_to_victim"] = value["is_attacker_to_victim"] == "1"
   record["is_victim_to_attacker"] = value["is_victim_to_attacker"] == "1"
   record["l7_proto"] = {
      value = value["l7_proto"],
      label = application
   }

   return record
end

-- ##############################################

return flow_alert_store
