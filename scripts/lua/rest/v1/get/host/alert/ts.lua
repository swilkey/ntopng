--
-- (C) 2013-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path
package.path = dirs.installdir .. "/scripts/lua/modules/alert_store/?.lua;" .. package.path

local alert_utils = require "alert_utils"
local alert_consts = require "alert_consts"
local alert_entities = require "alert_entities"
local rest_utils = require("rest_utils")
local host_alert_store = require "host_alert_store".new()
local alert_severities = require "alert_severities"

--
-- Read alerts count by time
-- Example: curl -u admin:admin -H "Content-Type: application/json" -d '{"ifid": "1"}' http://localhost:3000/lua/rest/v1/get/host/alert/ts.lua
--
-- NOTE: in case of invalid login, no error is returned but redirected to login
--

local rc = rest_utils.consts.success.ok

local ifid = _GET["ifid"]

if isEmptyString(ifid) then
   rc = rest_utils.consts.err.invalid_interface
   rest_utils.answer(rc)
   return
end

interface.select(ifid)

local res = {
   series = {},
   fill = {
      colors = {}
   }
}

local count_data = host_alert_store:count_by_severity_and_time()

for _, severity in pairsByField(alert_severities, "severity_id", rev) do
   res.series[#res.series + 1] = {
      name = i18n(severity.i18n_title),
      data = count_data[severity.severity_id],
   }
   res.fill.colors[#res.fill.colors + 1] = severity.color
end

rest_utils.answer(rc, res)
