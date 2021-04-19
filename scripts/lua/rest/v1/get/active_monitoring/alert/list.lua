--
-- (C) 2021-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

local format_utils = require "format_utils"
local alert_utils = require "alert_utils"
local alert_consts = require "alert_consts"
local alert_entities = require "alert_entities"
local rest_utils = require("rest_utils")
local am_alert_store = require "am_alert_store".new()

--
-- Read alerts data
-- Example: curl -u admin:admin -H "Content-Type: application/json" -d '{"ifid": "1"}' http://localhost:3000/lua/rest/v1/get/am/alert/list.lua
--
-- NOTE: in case of invalid login, no error is returned but redirected to login
--

local rc = rest_utils.consts.success.ok
local res = {}

-- Active monitoring stay in the system interface
interface.select(getSystemInterfaceId())

-- Fetch the results
local alerts, recordsFiltered = am_alert_store:select_request()

for _key,_value in ipairs(alerts or {}) do
   local record = {}

   local severity = alert_consts.alertSeverityRaw(tonumber(_value["severity"]))
   --local atype = alert_consts.getAlertType(tonumber(_value["alert_id"]), alert_entities.am_host.entity_id)
   local alert_info = alert_utils.getAlertInfo(_value)
   local name = alert_consts.alertTypeLabel(tonumber(_value["alert_id"]), false, alert_entities.am_host.entity_id)
   local msg = alert_utils.formatAlertMessage(ifid, _value, alert_info)
   local date = tonumber(_value["tstamp"])
   local count = 1 -- TODO (not yet supported)

   record["row_id"] = _value["rowid"]
   record["date"] = date
   record["duration"] = duration
   record["severity"] = severity
   record["alert_id"] = _value["alert_id"]
   record["count"] = count -- historical only 
   record["threshold"] = 0
   record["value"] = 0
   record["name"] = name
   record["msg"] = msg

   res[#res + 1] = record
end -- for


rest_utils.extended_answer(rc, {records = res}, {
			      ["draw"] = tonumber(_GET["draw"]),
			      ["recordsFiltered"] = recordsFiltered,
			      ["recordsTotal"] = #res
})
