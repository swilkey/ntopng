--
-- (C) 2019-21 - ntop.org
--

-- ##############################################

local host_alert_keys = require "host_alert_keys"
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path

local alert_creators = require "alert_creators"
local format_utils = require "format_utils"
-- Import the classes library.
local classes = require "classes"
-- Make sure to import the Superclass!
local alert = require "alert"

-- ##############################################

local host_alert_remote_connection = classes.class(alert)

-- ##############################################

host_alert_remote_connection.meta = {
  alert_key = host_alert_keys.host_alert_remote_connection,
  i18n_title = "alerts_dashboard.remote_connection_title",
  icon = "fas fa-info",
}

-- ##############################################

-- @brief Prepare an alert table used to generate the alert
-- @return A table with the alert built
function host_alert_remote_connection:init()
   -- Call the parent constructor
   self.super:init()

   self.alert_type_params = {}
end

-- #######################################################

-- @brief Format an alert into a human-readable string
-- @param ifid The integer interface id of the generated alert
-- @param alert The alert description table, including alert data such as the generating entity, timestamp, granularity, type
-- @param alert_type_params Table `alert_type_params` as built in the `:init` method
-- @return A human-readable string
function host_alert_remote_connection.format(ifid, alert, alert_type_params)
   local alert_consts = require "alert_consts"
   local host = alert_consts.formatHostAlert(ifid, alert["ip"], alert["vlan_id"])

   return i18n("alerts_dashboard.remote_connection_alert_descr", {
		  host = host,
		  connections = alert_type_params["num_flows"],
   })
end

-- #######################################################

return host_alert_remote_connection
