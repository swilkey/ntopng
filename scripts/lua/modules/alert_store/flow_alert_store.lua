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

local flow_alert_store = {}

-- ##############################################

function flow_alert_store:new(args)
   -- Instance of the base class
   local _flow_alert_store = alert_store:new()

   -- Subclass using the base class instance
   self.key = "flow"

   -- self is passed as argument so it will be set as base class metatable
   -- and this will actually make it possible to override functions
   local _flow_alert_store_instance = _flow_alert_store:new(self)

   -- Return the instance
   return _flow_alert_store_instance
end

-- ##############################################

function flow_alert_store:insert(alert)
   local table_name = "flow_alerts"
 
   local insert_stmt = string.format("INSERT INTO %s "..
      "(alert_id, tstamp, tstamp_end, severity, cli_ip, srv_ip, cli_port, srv_port, vlan_id, "..
      "is_attacker_to_victim, is_victim_to_attacker, proto, l7_proto, l7_master_proto, l7_cat, "..
      "cli_name, srv_name, cli_country, srv_country, cli_blacklisted, srv_blacklisted, "..
      "cli2srv_bytes, srv2cli_bytes, cli2srv_pkts, srv2cli_pkts, first_seen, community_id, score, "..
      "flow_risk_bitmap, json) "..
      "VALUES (%u, %u, %u, %u, '%s', '%s', %u, %u, %u, %u, %u, %u, %u, %u, %u, '%s', '%s', '%s', "..
      "'%s', %u, %u, %u, %u, %u, %u, %u, '%s', %u, %u, '%s'); ",
      table_name, 
      alert.alert_type,
      alert.first_seen, -- TODO
      alert.alert_tstamp,
      alert.alert_severity,
      alert.cli_addr,
      alert.srv_addr,
      alert.cli_port,
      alert.srv_port,
      alert.vlan_id,
      ternary(alert.is_attacker_to_victim, 1, 0), -- TODO
      ternary(alert.is_victim_to_attacker, 1, 0), -- TODO
      alert.proto,
      alert.l7_proto,
      alert.l7_master_proto,
      alert.l7_cat,
      alert.cli_name,
      alert.srv_name,
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
      0, -- TODO flow_risk_bitmap
      alert.alert_json or "")

   traceError(TRACE_NORMAL, TRACE_CONSOLE, insert_stmt)

   return interface.alert_store_query(insert_stmt)
end

-- ##############################################

return flow_alert_store
