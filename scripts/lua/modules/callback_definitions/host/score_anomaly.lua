--
-- (C) 2019-21 - ntop.org
--

local user_scripts = require("user_scripts")
local alert_severities = require "alert_severities"
local host_alert_keys = require "host_alert_keys"

-- #################################################################

local score_anomaly = {
   -- Script category
   category = user_scripts.script_categories.security,

   default_enabled = true,
   alert_id = host_alert_keys.host_alert_score_anomaly,

   default_value = {
      severity = alert_severities.warning,
   },

   gui = {
      i18n_title = "alerts_thresholds_config.score_anomaly_title",
      i18n_description = "alerts_thresholds_config.score_anomaly_description",
   }
}

-- #################################################################

return score_anomaly
