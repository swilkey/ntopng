--
-- (C) 2019-21 - ntop.org
--

local user_scripts = require("user_scripts")
local alerts_api = require "alerts_api"
local alert_severities = require "alert_severities"
local alert_consts = require("alert_consts")

local UNEXPECTED_PLUGINS_ENABLED_CACHE_KEY = "ntopng.cache.user_scripts.unexpected_plugins_enabled"

-- #################################################################

local script = {
   -- Script category
   category = user_scripts.script_categories.security,

   -- This module is disabled by default
   default_enabled = false,

   -- This script is only for alerts generation
   is_alert = true,

   -- Specify the default value whe clicking on the "Reset Default" button
   default_value = {
      severity = alert_severities.error,
      items = {},
   },

   gui = {
      i18n_title        = "unexpected_dns.unexpected_dns_title",
      i18n_description  = "unexpected_dns.unexpected_dns_description",

      input_builder     = "items_list",
      item_list_type    = "ip_address",
      input_title       = "unexpected_dns.title",
      input_description = "unexpected_dns.description",
   }
}

-- #################################################################

function script.onEnable(hook, hook_config)
   -- Set a flag to indicate to the notifications system that an unexpected plugin
   -- has been enabled
   if isEmptyString(ntop.getCache(UNEXPECTED_PLUGINS_ENABLED_CACHE_KEY)) then
      ntop.setCache(UNEXPECTED_PLUGINS_ENABLED_CACHE_KEY, "1")
   end
end

-- #################################################################

return script
