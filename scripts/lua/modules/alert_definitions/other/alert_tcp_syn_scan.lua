--
-- (C) 2019-21 - ntop.org
--

-- ##############################################

local other_alert_keys = require "other_alert_keys"
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path

local json = require("dkjson")
local alert_creators = require "alert_creators"
local format_utils = require "format_utils"
-- Import the classes library.
local classes = require "classes"
-- Make sure to import the Superclass!
local alert = require "alert"

-- ##############################################

local alert_tcp_syn_scan = classes.class(alert)

-- ##############################################

alert_tcp_syn_scan.meta = {
  alert_key = other_alert_keys.alert_tcp_syn_scan,
  i18n_title = "alerts_dashboard.tcp_syn_scan",
  icon = "fas fa-life-ring",
  has_attacker = true,
}

-- ##############################################

function alert_tcp_syn_scan:init(metric, value, operator, threshold)
   -- Call the parent constructor
   self.super:init()

   self.alert_type_params = alert_creators.createThresholdCross(metric, value, operator, threshold)
end

-- #######################################################

function alert_tcp_syn_scan.format(ifid, alert, alert_type_params)
  local alert_consts = require("alert_consts")
  local entity = alert_consts.formatAlertEntity(ifid, alert_consts.alertEntityRaw(alert["alert_entity"]), alert["alert_entity_val"])

  return i18n("alert_messages.syn_scan_attacker", {
    entity = firstToUpper(entity),
    host_category = format_utils.formatAddressCategory((json.decode(alert.alert_json)).alert_generation.host_info),
    value = string.format("%u", math.ceil(alert_type_params.value)),
    threshold = alert_type_params.threshold,
  })
end

-- #######################################################

return alert_tcp_syn_scan
