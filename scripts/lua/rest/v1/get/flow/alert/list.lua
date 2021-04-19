--
-- (C) 2013-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

local format_utils = require "format_utils"
local alert_utils = require "alert_utils"
local alert_consts = require "alert_consts"
local alert_entities = require "alert_entities"
local rest_utils = require("rest_utils")
local flow_alert_store = require "flow_alert_store".new()

--
-- Read alerts data
-- Example: curl -u admin:admin -H "Content-Type: application/json" -d '{"ifid": "1"}' http://localhost:3000/lua/rest/v1/get/flow/alert/list.lua
--
-- NOTE: in case of invalid login, no error is returned but redirected to login
--

local rc = rest_utils.consts.success.ok
local res = {}

local ifid = _GET["ifid"]

if isEmptyString(ifid) then
   rc = rest_utils.consts.err.invalid_interface
   rest_utils.answer(rc)
   return
end

interface.select(ifid)

-- Fetch the results
local alerts, recordsFilter = flow_alert_store:select_request()

for _key,_value in ipairs(alerts or {}) do
   local record = {}

   local severity = alert_consts.alertSeverityLabel(tonumber(_value["severity"]))


   --local atype = alert_consts.getAlertType(tonumber(_value["alert_id"]), alert_entities.flow.entity_id)
   local score = tonumber(_value["score"])
   local alert_info = alert_utils.getAlertInfo(_value)
   local name = alert_consts.alertTypeLabel(tonumber(_value["alert_id"]), false, alert_entities.flow.entity_id)
   local msg = alert_utils.formatFlowAlertMessage(ifid, _value, alert_info)
   local date = format_utils.formatPastEpochShort(tonumber(_value["tstamp"]))
   local application =  interface.getnDPIProtoName(tonumber(_value["l7_proto"]))
   local count = 1 -- TODO (not yet supported)

   record["row_id"] = _value["rowid"]
   record["date"] = date
   record["duration"] = duration
   record["severity"] = severity
   record["alert_id"] = _value["alert_id"]

   record["count"] = count
   record["score"] = score
   record["name"] = name
   record["msg"] = msg
   record["cli_name"] = _value["cli_name"]
   record["srv_name"] = _value["srv_name"]
   record["cli_ip"] = _value["cli_ip"]
   record["srv_ip"] = _value["srv_ip"]
   record["cli_port"] = _value["cli_port"]
   record["srv_port"] = _value["srv_port"]
   record["vlan_id"] = _value["vlan_id"]
   record["proto"] = _value["proto"]
   record["l7_proto"] = application

   res[#res + 1] = record
end -- for

rest_utils.extended_answer(rc, {records = res}, {
			      ["draw"] = tonumber(_GET["draw"]),
			      ["recordsFiltered"] = recordsFilter,
			      ["recordsTotal"] = #res
})
