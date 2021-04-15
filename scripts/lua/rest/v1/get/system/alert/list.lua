--
-- (C) 2021-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

local alert_utils = require "alert_utils"
local alert_consts = require "alert_consts"
local alert_entities = require "alert_entities"
local rest_utils = require("rest_utils")
local system_alert_store = require "system_alert_store".new()

--
-- Read alerts data
-- Example: curl -u admin:admin -H "Content-Type: application/json" -d '{"ifid": "1"}' http://localhost:3000/lua/rest/v1/get/system/alert/list.lua
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
local alerts, recordsTotal = system_alert_store:select_request()

for _key,_value in ipairs(alerts or {}) do
   local record = {}

   local severity = alert_consts.alertSeverityRaw(tonumber(_value["severity"]))
   local atype = alert_consts.getAlertType(tonumber(_value["alert_id"]), tonumber(_value["entity_id"]))
   local alert_info = alert_utils.getAlertInfo(_value)
   local msg = alert_utils.formatAlertMessage(ifid, _value, alert_info)
   local date = tonumber(_value["tstamp"])

   record["date"] = date
   record["duration"] = duration
   record["severity"] = severity
   record["type"] = atype
   record["count"] = count -- historical only
   record["msg"] = msg

   res[#res + 1] = record
end -- for

local recordsFiltered = #res

rest_utils.extended_answer(rc, {records = res}, {
			      ["draw"] = tonumber(_GET["draw"]),
			      ["recordsFiltered"] = recordsFiltered,
			      ["recordsTotal"] = recordsTotal
})
