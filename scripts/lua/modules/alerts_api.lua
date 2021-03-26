--
-- (C) 2013-21 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path
package.path = dirs.installdir .. "/scripts/lua/modules/pools/?.lua;" .. package.path
package.path = dirs.installdir .. "/scripts/lua/modules/notifications/?.lua;" .. package.path


local json = require("dkjson")
local alert_severities = require "alert_severities"
local alert_consts = require("alert_consts")
local os_utils = require("os_utils")
local recipients = require "recipients"
local do_trace = false

local alerts_api = {}

-- Just helpers
local str_2_periodicity = {
  ["min"]     = 60,
  ["5mins"]   = 300,
  ["hour"]    = 3600,
  ["day"]     = 86400,
}

local known_alerts = {}
local current_script
local current_configset -- The configset used for the generation of this alert

-- ##############################################

-- Returns a string which identifies an alert
function alerts_api.getAlertId(alert)
  return(string.format("%s_%s_%s_%s_%s", alert.alert_type,
    alert.alert_subtype or "", alert.alert_granularity or "",
    alert.alert_entity, alert.alert_entity_val))
end

-- ##############################################

-- @brief Returns a key containing a hashed string of the `alert` to quickly identify the alert notification
-- @param alert A triggered/released alert table
-- @return The key as a string
local function get_notification_key(alert)
   return string.format("ntopng.cache.alerts.notification.%s", ntop.md5(alerts_api.getAlertId(alert)))
end

-- ##############################################

-- @brief Checks whether the triggered `alert` has already been notified
-- @param alert A triggered alert table
-- @return True if the `alert` has already been notified, false otherwise
local function is_trigger_notified(alert)
   local k = get_notification_key(alert)
   local res = tonumber(ntop.getCache(k))

   return res ~= nil
end

-- ##############################################

-- @brief Marks the triggered `alert` as notified to the recipients
-- @param alert A triggered alert table
-- @return nil
local function mark_trigger_notified(alert)
   local k = get_notification_key(alert)
   ntop.setCache(k, "1")
end

-- ##############################################

-- @brief Marks the released `alert` as notificed to the recipients
-- @param alert A released alert table
-- @return nil
local function mark_release_notified(alert)
   local k = get_notification_key(alert)
   ntop.delCache(k)
end

-- ##############################################

local function alertErrorTraceback(msg)
  traceError(TRACE_ERROR, TRACE_CONSOLE, msg)
  traceError(TRACE_ERROR, TRACE_CONSOLE, debug.traceback())
end

-- ##############################################

local function get_alert_triggered_key(alert_key, alert_subtype)
   if not alert_key or not alert_subtype then
      if not alert_subtype then
	 traceError(TRACE_ERROR, TRACE_CONSOLE, "alert_subtype is nil")
      end
      if not alert_key then
	 traceError(TRACE_ERROR, TRACE_CONSOLE, "alert_key is nil")
      end
      traceError(TRACE_ERROR, TRACE_CONSOLE, debug.traceback())
   end

   local res = string.format("%d@%s", alert_key, alert_subtype)

   return res
end

-- ##############################################

function alerts_api.addAlertGenerationInfo(alert_json, current_script)
  if alert_json and current_script then
    -- Add information about the script who generated this alert
    alert_json.alert_generation = {
      script_key = current_script.key,
      subdir = current_script.subdir,
    }
  else
    -- NOTE: there are currently some internally generated alerts which
    -- do not use the user_scripts api (e.g. the ntopng startup)
    --tprint(debug.traceback())
  end
end

local function addAlertGenerationInfo(alert_json)
  alerts_api.addAlertGenerationInfo(alert_json, current_script)
end

-- ##############################################

--! @brief Adds pool information to the alert
--! @param entity_info data returned by one of the entity_info building functions
local function addAlertPoolInfo(entity_info, alert_json)
   local pools_alert_utils = require "pools_alert_utils"

   if alert_json then
      local pool_id = pools_alert_utils.get_entity_pool_id(entity_info)
      alert_json.pool_id = pool_id
   end
end

-- ##############################################

--! @brief Adds host information to the alert (only works for host alerts)
--! @param alert_json Host info will be placed in key `host_info` of table `alert_json`
local function addAlertHostInfo(triggered)
   if triggered then
      alert = json.decode(triggered.alert_json)
      -- Add only minimal information to keep the final result as small as possible
      -- only if the alert_generation is not nil
      if alert.alert_generation then 
        alert.alert_generation.host_info = host.getMinInfo()
        triggered.alert_json = json.encode(alert)
      end
   end
end

-- ##############################################

--@brief Check if the `alert` belongs to an exclusion list
--! @param entity_info data returned by one of the entity_info building functions
--! @param type_info data returned by one of the type_info building functions
--@return True if the alert matches an exclusion list, false otherwise
local function matchExcludeFilter(entity_info, type_info)
   local user_scripts = require "user_scripts"

   -- Subdir equals the entity id, e.g., "host", "interface", etc.
   local cur_subdir = alert_consts.alertEntityRaw(entity_info.alert_entity.entity_id)

   -- Check if the alert has a filter and thus should not be generated
   local cur_filters = user_scripts.getFilters(current_configset, cur_subdir)

   -- Prepare the context with alert data
   local context = {
      alert_type = type_info.alert_type.alert_key,
      alert_subtype = type_info.alert_subtype,
      alert_entity = entity_info.alert_entity.entity_id,
      alert_entity_val = entity_info.alert_entity_val,
      alert_severity = type_info.alert_severity.severity_id,
      alert_json = type_info.alert_type_params,
   }

   if current_script and current_script.key and cur_filters then
      if user_scripts.matchExcludeFilter(cur_filters, current_script, cur_subdir, context) then
	 -- This alert is matching an exclusion filter. return, and do anything
	 return true
      end
   end

   return false
end

-- ##############################################

--! @param entity_info data returned by one of the entity_info building functions
--! @param type_info data returned by one of the type_info building functions
--! @param when (optional) the time when the release event occurs
--! @return true if the alert was successfully stored, false otherwise
function alerts_api.store(entity_info, type_info, when)
  if(not areAlertsEnabled()) then
    return(false)
  end

  local force = false
  local ifid = interface.getId()
  local granularity_sec = type_info.alert_granularity and type_info.alert_granularity.granularity_seconds or 0
  local granularity_id = type_info.alert_granularity and type_info.alert_granularity.granularity_id or -1

  type_info.alert_type_params = type_info.alert_type_params or {}
  addAlertGenerationInfo(type_info.alert_type_params)

  local alert_json = json.encode(type_info.alert_type_params)
  local subtype = type_info.alert_subtype or ""
  when = when or os.time()

  -- Here the alert is considered stored. The actual store will be performed
  -- asynchronously

  -- NOTE: keep in sync with SQLite alert format in AlertsManager.cpp
  local alert_to_store = {
    ifid = ifid,
    action = "store",
    alert_type = type_info.alert_type.alert_key,
    alert_subtype = subtype,
    alert_granularity = granularity_sec,
    alert_entity = entity_info.alert_entity.entity_id,
    alert_entity_val = entity_info.alert_entity_val,
    alert_severity = type_info.alert_severity.severity_id,
    alert_tstamp = when,
    alert_tstamp_end = when,
    alert_json = alert_json,
  }

  addAlertPoolInfo(entity_info, alert_to_store)

  if matchExcludeFilter(entity_info, type_info) then
     -- This alert is matching an exclusion filter. return, and do anything
     return false
  end

  if(entity_info.alert_entity.entity_id == alert_consts.alertEntity("host")) then
    -- NOTE: for engaged alerts this operation is performed during trigger in C
    
    -- Note: this is not required as there is no state (required for engage/release only)
    -- and this has been removed as it creates issues with external alerts (e.g. syslog)
    -- as there is no active host matching the alert.
    -- host.checkContext(entity_info.alert_entity_val)

    addAlertHostInfo(alert_to_store)
    interface.incTotalHostAlerts(entity_info.alert_entity_val, type_info.alert_type.alert_key)
  end

  recipients.dispatch_notification(alert_to_store, current_script)

  return(true)
end

-- ##############################################

-- @brief Determine whether the alert has already been triggered
-- @param candidate_severity the candidate alert severity
-- @param candidate_type the candidate alert type
-- @param candidate_granularity the candidate alert granularity
-- @param candidate_alert_subtype the candidate alert subtype
-- @param cur_alerts a table of currently triggered alerts
-- @return true on if the alert has already been triggered, false otherwise
--
-- @note Example of cur_alerts
-- cur_alerts table
-- cur_alerts.1 table
-- cur_alerts.1.alert_type number 2
-- cur_alerts.1.alert_subtype string min_bytes
-- cur_alerts.1.alert_entity_val string 192.168.2.222@0
-- cur_alerts.1.alert_granularity number 60
-- cur_alerts.1.alert_severity number 2
-- cur_alerts.1.alert_json string {"metric":"bytes","threshold":1,"value":13727070,"operator":"gt"}
-- cur_alerts.1.alert_tstamp_end number 1571328097
-- cur_alerts.1.alert_tstamp number 1571327460
-- cur_alerts.1.alert_entity number 1
local function already_triggered(cur_alerts, candidate_severity, candidate_type,
				 candidate_granularity, candidate_alert_subtype, remove_from_cur_alerts)
   for i = #cur_alerts, 1, -1 do
      local cur_alert = cur_alerts[i]

      if candidate_severity == cur_alert.alert_severity
	 and candidate_type == cur_alert.alert_type
	 and candidate_granularity == cur_alert.alert_granularity
         and candidate_alert_subtype == cur_alert.alert_subtype then
	    if remove_from_cur_alerts then
	       -- Remove from cur_alerts, this will save cycles for
	       -- subsequent calls of this method.
	       -- Using .remove is OK here as there won't unnecessarily move memory multiple times:
	       -- we return immeediately
	       -- NOTE: see un-removed alerts will be released by releaseEntityAlerts in interface.lua
	       table.remove(cur_alerts, i)
	    end

	    return true
      end
   end

   return false
end

-- ##############################################

--! @brief Checks if a stateful alert should be triggered/released or if has already been triggered/released and there is nothing to do
--! @param cur_alerts a table containing triggered alerts for the current entity
--! @param candidate_severity the candidate alert severity
--! @param candidate_type the candidate alert type
--! @param candidate_granularity the candidate alert granularity
--! @param candidate_alert_subtype the candidate alert subtype
--! @param trigger The intention of the caller to trigger this alert (true) or to release this alert (false)
--! @return True if the alert should be processed, or false if there is nothing to do
function alerts_api.do_stateful_alert(cur_alerts, candidate_severity, candidate_type, candidate_granularity, candidate_alert_subtype, trigger)
   if not cur_alerts then
      return false
   end

   local severity_id = candidate_severity.severity_id
   local alert_key = candidate_type.meta.alert_key
   local granularity = alert_consts.alerts_granularities[candidate_granularity]
   local granularity_sec = granularity and granularity.granularity_seconds or 0

   if trigger then
      -- True if the alert has not been already triggered
      return not already_triggered(cur_alerts, severity_id, alert_key, granularity_sec, candidate_alert_subtype)
   else --[[ release --]]
      -- True if the alert was triggered
      return already_triggered(cur_alerts, severity_id, alert_key, granularity_sec, candidate_alert_subtype)
   end
end

-- ##############################################

--! @brief Trigger an alert of given type on the entity
--! @param entity_info data returned by one of the entity_info building functions
--! @param type_info data returned by one of the type_info building functions
--! @param when (optional) the time when the release event occurs
--! @param cur_alerts (optional) a table containing triggered alerts for the current entity
--! @return true on if the alert was triggered, false otherwise
--! @note The actual trigger is performed asynchronously
--! @note false is also returned if an existing alert is found and refreshed
function alerts_api.trigger(entity_info, type_info, when, cur_alerts)
  if(not areAlertsEnabled()) then
    return(false)
  end

  local ifid = interface.getId()

  if(type_info.alert_granularity == nil) then
    alertErrorTraceback("Missing mandatory 'alert_granularity'")
    return(false)
  end

  -- Apply defaults
  local granularity_sec = type_info.alert_granularity and type_info.alert_granularity.granularity_seconds or 0
  local granularity_id = type_info.alert_granularity and type_info.alert_granularity.granularity_id or 0 --[[ 0 is aperiodic ]]
  local subtype = type_info.alert_subtype or ""

  when = when or os.time()

  type_info.alert_type_params = type_info.alert_type_params or {}
  addAlertGenerationInfo(type_info.alert_type_params)

  -- Check whether this alert is matching an exclusion filter
  local match_exclude_filter = matchExcludeFilter(entity_info, type_info)

  if(cur_alerts and already_triggered(cur_alerts, type_info.alert_severity.severity_id,
				      type_info.alert_type.alert_key, granularity_sec, subtype, true) == true) then
     -- If there, the alert was already engaged at the time this function was called. Hence, if the alert
     -- is matching the exclusion filter, the alert must actually be RELEASED.
     -- NOTE: release is called without `cur_alerts` as there is no need to use this cache. Release MUST be done.
     if match_exclude_filter then
	return alerts_api.release(entity_info, type_info, when, nil --[[ Don't pass cur_alerts, don't want to use this cache --]])
     else
	-- Alert does not belong to an exclusion filter and it is already triggered. There's nothing to do, just return.
	return true
     end
  end

  if match_exclude_filter then
     -- This alert is matching an exclusion filter. Return, and do not perform any trigger action.
     return false
  end

  local alert_json = json.encode(type_info.alert_type_params)
  local triggered
  local alert_key_name = get_alert_triggered_key(type_info.alert_type.alert_key, subtype)

  local params = {
    alert_key_name, granularity_id,
    type_info.alert_severity.severity_id, type_info.alert_type.alert_key,
    subtype, alert_json,
  }

  if(entity_info.alert_entity.entity_id == alert_consts.alertEntity("host")) then
    host.checkContext(entity_info.alert_entity_val)
    triggered = host.storeTriggeredAlert(table.unpack(params))
    addAlertHostInfo(triggered)
  elseif(entity_info.alert_entity.entity_id == alert_consts.alertEntity("interface")) then
    interface.checkContext(entity_info.alert_entity_val)
    triggered = interface.storeTriggeredAlert(table.unpack(params))
  elseif(entity_info.alert_entity.entity_id == alert_consts.alertEntity("network")) then
    network.checkContext(entity_info.alert_entity_val)
    triggered = network.storeTriggeredAlert(table.unpack(params))
  else
    triggered = interface.triggerExternalAlert(entity_info.alert_entity.entity_id, entity_info.alert_entity_val, table.unpack(params))
  end

  if(triggered == nil) then
    if(do_trace) then print("[Don't Trigger alert (already triggered?) @ "..granularity_sec.."] "..
        entity_info.alert_entity_val .."@"..type_info.alert_type.i18n_title..":".. subtype .. "\n") end
    return(false)
  else
    if(do_trace) then print("[TRIGGER alert @ "..granularity_sec.."] "..
        entity_info.alert_entity_val .."@"..type_info.alert_type.i18n_title..":".. subtype .. "\n") end
  end

  triggered.ifid = ifid
  triggered.action = "engage"

  addAlertPoolInfo(entity_info, triggered)

  -- Emit the notification only if the notification hasn't already been emitted.
  -- This is to avoid alert storms when ntopng is restarted. Indeeed,
  -- if there are 100 alerts triggered when ntopng is switched off, chances are the
  -- same 100 alerts will be triggered again as soon as ntopng is restarted, causing
  -- 100 trigger notifications to be emitted twice. This check is to prevent such behavior.
  if not is_trigger_notified(triggered) then
     recipients.dispatch_notification(triggered, current_script)
     mark_trigger_notified(triggered)
  end

  return(true)
end

-- ##############################################

--! @brief Release an alert of given type on the entity
--! @param entity_info data returned by one of the entity_info building functions
--! @param type_info data returned by one of the type_info building functions
--! @param when (optional) the time when the release event occurs
--! @param cur_alerts (optional) a table containing triggered alerts for the current entity
--! @note The actual release is performed asynchronously
--! @return true on success, false otherwise
function alerts_api.release(entity_info, type_info, when, cur_alerts)
  if(not areAlertsEnabled()) then
    return(false)
  end

  -- Apply defaults
  local granularity_sec = type_info.alert_granularity and type_info.alert_granularity.granularity_seconds or 0
  local granularity_id = type_info.alert_granularity and type_info.alert_granularity.granularity_id or 0 --[[ 0 is aperiodic ]]
  local subtype = type_info.alert_subtype or ""

  if(cur_alerts and (not already_triggered(cur_alerts, type_info.alert_severity.severity_id,
	  type_info.alert_type.alert_key, granularity_sec, subtype, true))) then
     return(true)
  end

  when = when or os.time()
  local alert_key_name = get_alert_triggered_key(type_info.alert_type.alert_key, subtype)
  local ifid = interface.getId()
  local params = {alert_key_name, granularity_id, when}
  local released = nil

  if(type_info.alert_severity == nil) then
    alertErrorTraceback(string.format("Missing alert_severity [type=%s]", type_info.alert_type and type_info.alert_type.alert_key or ""))
    return(false)
  end

  if(entity_info.alert_entity.entity_id == alert_consts.alertEntity("host")) then
    host.checkContext(entity_info.alert_entity_val)
    released = host.releaseTriggeredAlert(table.unpack(params))
    addAlertHostInfo(released)
  elseif(entity_info.alert_entity.entity_id == alert_consts.alertEntity("interface")) then
    interface.checkContext(entity_info.alert_entity_val)
    released = interface.releaseTriggeredAlert(table.unpack(params))
  elseif(entity_info.alert_entity.entity_id == alert_consts.alertEntity("network")) then
    network.checkContext(entity_info.alert_entity_val)
    released = network.releaseTriggeredAlert(table.unpack(params))
  else
    released = interface.releaseExternalAlert(entity_info.alert_entity.entity_id, entity_info.alert_entity_val, table.unpack(params))
  end

  if(released == nil) then
    if(do_trace) then tprint("[Dont't Release alert (not triggered?) @ "..granularity_sec.."] "..
      entity_info.alert_entity_val .."@"..type_info.alert_type.i18n_title..":".. subtype .. "\n") end
    return(false)
  else
    if(do_trace) then tprint("[RELEASE alert @ "..granularity_sec.."] "..
        entity_info.alert_entity_val .."@"..type_info.alert_type.i18n_title..":".. subtype .. "\n") end
  end

  released.ifid = ifid
  released.action = "release"

  addAlertPoolInfo(entity_info, released)

  mark_release_notified(released)

  if matchExcludeFilter(entity_info, type_info) then
     -- This alert is matching an exclusion filter, return.
     -- NOTE: this code is placed after the in-memory release (see <entity>.releaseTriggeredAlert calls above)
     -- as we want to remove triggered alerts matching filters from memory. The only thing that
     -- should be avoided is the generation of notifications causing the alert to be inserted into SQLite
     -- and also sent to external endpoints
     return false
  end

  recipients.dispatch_notification(released, current_script)

  return(true)
end

-- ##############################################

-- Convenient method to release multiple alerts on an entity
function alerts_api.releaseEntityAlerts(entity_info, alerts)
  if(alerts == nil) then
    alerts = interface.getEngagedAlerts(entity_info.alert_entity.entity_id, entity_info.alert_entity_val)
  end

  for _, cur_alert in pairs(alerts) do
     -- NOTE: do not pass alerts here as a parameters as deleting items while
     -- does not work in lua

     local cur_alert_type = alert_consts.alert_types[alert_consts.getAlertType(cur_alert.alert_type)]
     -- Instantiate the alert.
     -- NOTE: No parameter is passed to :new() as parameters are NOT used when releasing alerts
     -- This may change in the future.
     local cur_alert_instance = cur_alert_type:new(--[[ empty, no parameters for the release --]])

     -- Set alert params.
     cur_alert_instance:set_severity(alert_severities[alert_consts.alertSeverityRaw(cur_alert.alert_severity)])
     cur_alert_instance:set_subtype(cur_alert.alert_subtype)
     cur_alert_instance:set_granularity(alert_consts.sec2granularity(cur_alert.alert_granularity))

     cur_alert_instance:release(entity_info)
  end
end

-- ##############################################
-- entity_info building functions
-- ##############################################

function alerts_api.hostAlertEntity(hostip, hostvlan)
  return {
    alert_entity = alert_consts.alert_entities.host,
    -- NOTE: keep in sync with C (Alertable::setEntityValue)
    alert_entity_val = hostinfo2hostkey({ip = hostip, vlan = hostvlan}, nil, true)
  }
end

-- ##############################################

function alerts_api.interfaceAlertEntity(ifid)
  return {
    alert_entity = alert_consts.alert_entities.interface,
    -- NOTE: keep in sync with C (Alertable::setEntityValue)
    alert_entity_val = string.format("%d", ifid)
  }
end

-- ##############################################

function alerts_api.networkAlertEntity(network_cidr)
  return {
    alert_entity = alert_consts.alert_entities.network,
    -- NOTE: keep in sync with C (Alertable::setEntityValue)
    alert_entity_val = network_cidr
  }
end

-- ##############################################

function alerts_api.snmpInterfaceEntity(snmp_device, snmp_interface)
  return {
    alert_entity = alert_consts.alert_entities.snmp_device,
    alert_entity_val = string.format("%s_ifidx%s", snmp_device, ""..snmp_interface)
  }
end

-- ##############################################

function alerts_api.snmpDeviceEntity(snmp_device)
  return {
    alert_entity = alert_consts.alert_entities.snmp_device,
    alert_entity_val = snmp_device
  }
end

-- ##############################################

function alerts_api.macEntity(mac)
  return {
    alert_entity = alert_consts.alert_entities.mac,
    alert_entity_val = mac
  }
end

-- ##############################################

function alerts_api.userEntity(user)
  return {
    alert_entity = alert_consts.alert_entities.user,
    alert_entity_val = user
  }
end

-- ##############################################

function alerts_api.processEntity(process)
  return {
    alert_entity = alert_consts.alert_entities.process,
    alert_entity_val = process
  }
end

-- ##############################################

function alerts_api.hostPoolEntity(pool_id)
  return {
    alert_entity = alert_consts.alert_entities.host_pool,
    alert_entity_val = tostring(pool_id)
  }
end

-- ##############################################

function alerts_api.periodicActivityEntity(activity_path)
  return {
    alert_entity = alert_consts.alert_entities.periodic_activity,
    alert_entity_val = activity_path
  }
end

-- ##############################################

function alerts_api.amThresholdCrossEntity(host)
  return {
    alert_entity = alert_consts.alert_entities.am_host,
    alert_entity_val = host
  }
end

-- ##############################################

function alerts_api.categoryListsEntity(list_name)
  return {
    alert_entity = alert_consts.alert_entities.category_lists,
    alert_entity_val = list_name
  }
end

-- ##############################################

function alerts_api.influxdbEntity(dburl)
  return {
    alert_entity = alert_consts.alert_entities.influx_db,
    alert_entity_val = dburl
  }
end

-- ##############################################

function alerts_api.iec104Entity(flow)
  return {
    alert_entity = alert_consts.alert_entities.flow,
    alert_entity_val = "flow"
  }
end

-- ##############################################
-- type_info building functions
-- ##############################################

function alerts_api.tooManyDropsType(drops, drop_perc, threshold)
  return({
    alert_type = alert_consts.alert_types.alert_too_many_drops,
    alert_severity = alert_severities.error,
    alert_granularity = alert_consts.alerts_granularities.min,
    alert_type_params = {
      drops = drops, drop_perc = drop_perc, edge = threshold,
    },
  })
end

-- ##############################################

-- TODO document
function alerts_api.checkThresholdAlert(params, alert_type, value, attacker, victim)
  local user_scripts = require "user_scripts"
  local script = params.user_script
  local threshold_config = params.user_script_config
  local alarmed = false  
  local threshold = threshold_config.threshold or threshold_config.default_contacts

  -- Retrieve the function to be used for the threshold check.
  -- The function depends on the operator, i.e., "gt", or "lt".
  -- When there's no operator, the default "gt" function is taken from the available
  -- operation functions
  local op_fn = user_scripts.operator_functions[threshold_config.operator] or user_scripts.operator_functions.gt
  if op_fn and op_fn(value, threshold) then alarmed = true end

  -- tprint({params.cur_alerts, threshold_config.severity, alert_type.meta, params.granularity, script.key --[[ the subtype--]], alarmed})

  -- Check if there is work to do before creating an instance of the alert and doing the actual trigger release
  if not alerts_api.do_stateful_alert(params.cur_alerts, threshold_config.severity,
				      alert_type, params.granularity, script.key --[[ the subtype --]], alarmed) then
     -- Nothing to do. Alert either already triggered or already released
     return
  end

  local alert = alert_type.new(
    params.user_script.key,
    value,
    threshold_config.operator,
    threshold
  )

  alert:set_severity(threshold_config.severity)
  alert:set_granularity(params.granularity)
  alert:set_subtype(script.key)

  if attacker ~= nil then
    alert:set_attacker(attacker)
  end

  if victim ~= nil then
    alert:set_victim(victim)
  end

  if(alarmed) then
    alert:trigger(params.alert_entity, nil, params.cur_alerts)
  else
    alert:release(params.alert_entity, nil, params.cur_alerts)
  end
end

-- #####################################

function alerts_api.handlerPeerBehaviour(params, stats, tot_anomalies, host_ip, threshold, behaviour_type, subtype)
   local anomaly     = stats["anomaly"]
   local lower_bound = stats["lower_bound"]
   local upper_bound = stats["upper_bound"]
   local value       = stats["value"]
   local prediction  = stats["prediction"]

   local alert_unexpected_behaviour = behaviour_type.new(
      value,
      prediction,
      upper_bound,
      lower_bound
   )

   if threshold and tot_anomalies and tot_anomalies > threshold then
      alert_unexpected_behaviour:set_severity(alert_severities.error)
   else
      alert_unexpected_behaviour:set_severity(alert_severities.warning)
   end
      
   alert_unexpected_behaviour:set_granularity(params.granularity)

   if subtype then
      alert_unexpected_behaviour:set_subtype(subtype)
   end
   
   if anomaly then
      alert_unexpected_behaviour:trigger(params.alert_entity)
   else
      alert_unexpected_behaviour:release(params.alert_entity)
   end
end

-- ##############################################

-- An alert check function which checks for anomalies.
-- The user_script key is the type of the anomaly to check.
-- The user_script must implement a anomaly_type_builder(anomaly_key) function
-- which returns a type_info for the given anomaly.
function alerts_api.anomaly_check_function(params)
  local anomal_key = params.user_script.key
  local type_info = params.user_script.anomaly_type_builder()

  type_info:set_severity(alert_severities.error)
  type_info:set_granularity(params.granularity)
  type_info:set_subtype(anomal_key)

  if params.entity_info.anomalies[anomal_key] then
    type_info:trigger(params.alert_entity, nil, params.cur_alerts)
  else
    type_info:release(params.alert_entity, nil, params.cur_alerts)
  end
end

-- ##############################################

-- @brief Performs a difference between the current metric value and
-- the previous saved value and saves the current value for next call.
-- @param reg lua C context pointer to the alertable entity storage
-- @param metric_name name of the metric to retrieve
-- @param granularity the granularity string
-- @param curr_val the current metric value
-- @param skip_first if true, 0 will be returned when no cached value is present
-- @return the difference between current and previous value
local function delta_val(reg, metric_name, granularity, curr_val, skip_first)
   local granularity_num = alert_consts.granularity2id(granularity)
   local key = string.format("%s:%s", metric_name, granularity_num)

   -- Read cached value and purify it
   local prev_val = tonumber(reg.getCachedAlertValue(key, granularity_num))

   -- Save the value for the next round
   reg.setCachedAlertValue(key, tostring(curr_val), granularity_num)

   if((skip_first == true) and (prev_val == nil)) then
      return(0)
   else
      return(curr_val - (prev_val or 0))
   end
end

-- ##############################################

function alerts_api.host_delta_val(metric_name, granularity, curr_val, skip_first)
  return(delta_val(host --[[ the host Lua reg ]], metric_name, granularity, curr_val, skip_first))
end

function alerts_api.interface_delta_val(metric_name, granularity, curr_val, skip_first)
  return(delta_val(interface --[[ the interface Lua reg ]], metric_name, granularity, curr_val, skip_first))
end

function alerts_api.network_delta_val(metric_name, granularity, curr_val, skip_first)
  return(delta_val(network --[[ the network Lua reg ]], metric_name, granularity, curr_val, skip_first))
end

-- ##############################################

function alerts_api.application_bytes(info, application_name)
   local curr_val = 0

   if info["ndpi"] and info["ndpi"][application_name] then
      curr_val = info["ndpi"][application_name]["bytes.sent"] + info["ndpi"][application_name]["bytes.rcvd"]
   end

   return curr_val
end

-- ##############################################

function alerts_api.category_bytes(info, category_name)
   local curr_val = 0

   if info["ndpi_categories"] and info["ndpi_categories"][category_name] then
      curr_val = info["ndpi_categories"][category_name]["bytes.sent"] + info["ndpi_categories"][category_name]["bytes.rcvd"]
   end

   return curr_val
end

-- ##############################################

function alerts_api.invokeScriptHook(user_script, configset, hook_fn, p1, p2, p3)
  current_script = user_script
  current_configset = configset

  return(hook_fn(p1, p2, p3))
end

-- ##############################################

return(alerts_api)
