--
-- (C) 2019-21 - ntop.org
--

local user_scripts = require("user_scripts")
local flow_consts = require("flow_consts")
local alert_severities = require "alert_severities"
local alerts_api = require "alerts_api"
local alert_consts = require("alert_consts")
local flow_alert_keys = require "flow_alert_keys"

-- #################################################################

local script = {
   -- Script category
   category = user_scripts.script_categories.security, 

   -- This script is only for alerts generation
   alert_id = flow_alert_keys.flow_alert_blacklisted,
   
   default_value = {
      severity = alert_severities.error,
   },

   gui = {
      i18n_title = "flow_callbacks_config.blacklisted",
      i18n_description = "flow_callbacks_config.blacklisted_description",
   }
}

-- #################################################################

return script
