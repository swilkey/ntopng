--
-- (C) 2019-21 - ntop.org
--

-- ##############################################

local host_alert_keys = require "host_alert_keys"
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path

local json = require("dkjson")
local alert_creators = require "alert_creators"
local format_utils = require "format_utils"
-- Import the classes library.
local classes = require "classes"
-- Make sure to import the Superclass!
local alert = require "alert"

-- ##############################################

local host_alert_tcp_syn_scan_attacker = classes.class(alert)

-- ##############################################

host_alert_tcp_syn_scan_attacker.meta = {
  alert_key = host_alert_keys.host_alert_syn_scan_attacker,
  i18n_title = "alerts_dashboard.tcp_syn_scan_attacker",
  icon = "fas fa-life-ring",
  has_attacker = true,
}

-- ##############################################

function host_alert_tcp_syn_scan_attacker:init(metric, value, operator, threshold)
   -- Call the parent constructor
   self.super:init()

   self.alert_type_params = alert_creators.createThresholdCross(metric, value, operator, threshold)
end

-- #######################################################

function host_alert_tcp_syn_scan_attacker.format(ifid, alert, alert_type_params)
  local alert_consts = require("alert_consts")
  local entity = alert_consts.formatAlertEntity(ifid, alert_consts.alertEntityRaw(alert["alert_entity"]), alert["alert_entity_val"])

  return i18n("alert_messages.syn_scan_attacker", {
    entity = firstToUpper(entity),
    host_category = format_utils.formatAddressCategory((json.decode(alert.alert_json)).alert_generation.host_info),
    value = string.format("%u", math.ceil(alert_type_params.value or 0)),
    threshold = alert_type_params.threshold or 0,
  })
end

-- #######################################################

return host_alert_tcp_syn_scan_attacker
