--
-- (C) 2013-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

require "lua_utils"
local alert_utils = require "alert_utils"
require "flow_utils"
local alert_consts = require "alert_consts"
local alert_entities = require "alert_entities"
local json = require "dkjson"
local rest_utils = require("rest_utils")
local flow_alert_store = require "flow_alert_store":new()

--
-- Read alerts data
-- Example: curl -u admin:admin -H "Content-Type: application/json" -d '{"ifid": "1"}' http://localhost:3000/lua/rest/v1/get/flow/alert/data.lua
--
-- NOTE: in case of invalid login, no error is returned but redirected to login
--

local rc = rest_utils.consts.success.ok
local res = {}

local ifid = _GET["ifid"]
local epoch_begin = _GET["epoch_begin"]
local epoch_end = _GET["epoch_end"]
local alert_type = _GET["alert_type"]
local alert_severity = _GET["alert_severity"]
local draw = tonumber(_GET["draw"]) or 0

local NUM_RECORDS = 5

if isEmptyString(ifid) then
   rc = rest_utils.consts.err.invalid_interface
   rest_utils.answer(rc)
   return
end

interface.select(ifid)

local count_query = flow_alert_store:select("count(*) as count")
local recordsTotal = tonumber(count_query[1]["count"])
local recordsFiltered = 0

-- Add limits and sort criteria only after the count has been done
flow_alert_store:add_limit(NUM_RECORDS, NUM_RECORDS * draw)
-- flow_alert_store:order_by("severity desc")

local alerts = flow_alert_store:select()

for _key,_value in ipairs(alerts or {}) do
   local record = {}
   local alert_entity
   local alert_entity_val

   recordsFiltered = recordsFiltered + 1

   local severity = alert_consts.alertSeverityRaw(tonumber(_value["severity"]))
   local atype = alert_consts.getAlertType(tonumber(_value["alert_id"]), alert_entities.flow.entity_id)
   local score = tonumber(_value["score"])
   local alert_info = alert_utils.getAlertInfo(_value)
   local msg = alert_utils.formatFlowAlertMessage(ifid, _value, alert_info)
   local date = tonumber(_value["alert_tstamp"])

   record["date"] = date
   record["duration"] = duration
   record["severity"] = severity
   record["type"] = atype
   record["count"] = count
   record["score"] = score
   record["msg"] = msg

   res[#res + 1] = record
end -- for

rest_utils.extended_answer(rc, {records = res}, {
			      ["draw"] = tonumber(_GET["draw"]),
			      ["recordsFiltered"] = recordsFiltered,
			      ["recordsTotal"] = recordsTotal
})

