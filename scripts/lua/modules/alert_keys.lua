--
-- (C) 2020-21 - ntop.org
--

-- ##############################################

local entities = {
   FLOW  = 0,
   HOST  = 1,
   OTHER = 2
}

-- ##############################################

local alert_keys = {
   ntopng = {
      -- First 1024 (0 to 1023) IDs reserved for flow status alerts.
      -- Flow statuses are a Bitmap of 128 bits. 1024 is just to keep a safe margin
      -- and possibly enlarge Bitmap in the future
      -- NOTE: Keep them in sync with ntop_typedefs.h FlowAlertType
      alert_normal                          = {entities.FLOW, 0},
      alert_blacklisted                     = {entities.FLOW, 1},
      alert_blacklisted_country             = {entities.FLOW, 2},
      alert_flow_blocked                    = {entities.FLOW, 3},
      alert_data_exfiltration               = {entities.FLOW, 4},
      alert_device_protocol_not_allowed     = {entities.FLOW, 5},
      alert_dns_data_exfiltration           = {entities.FLOW, 6},
      alert_dns_invalid_query               = {entities.FLOW, 7},
      alert_elephant_flow                   = {entities.FLOW, 8},
      alert_elephant_remote_to_local        = {entities.FLOW, 9},  -- No longer used, can be recycled
      alert_external                        = {entities.FLOW, 10},
      alert_longlived                       = {entities.FLOW, 11},
      alert_low_goodput                     = {entities.FLOW, 12},
      alert_malicious_signature             = {entities.FLOW, 13},
      alert_internals                       = {entities.FLOW, 14},
      alert_potentially_dangerous           = {entities.FLOW, 15},
      alert_remote_to_remote                = {entities.FLOW, 16},
      alert_suspicious_tcp_probing          = {entities.FLOW, 17},
      alert_suspicious_tcp_syn_probing      = {entities.FLOW, 18},
      alert_tcp_connection_issues           = {entities.FLOW, 19},
      alert_tcp_connection_refused          = {entities.FLOW, 20},
      alert_tcp_severe_connection_issues    = {entities.FLOW, 21},
      alert_tls_certificate_expired         = {entities.FLOW, 22},
      alert_tls_certificate_mismatch        = {entities.FLOW, 23},
      alert_tls_old_protocol_version        = {entities.FLOW, 24},
      alert_tls_unsafe_ciphers              = {entities.FLOW, 25},
      alert_udp_unidirectional              = {entities.FLOW, 26},
      alert_web_mining                      = {entities.FLOW, 27},
      alert_tls_certificate_selfsigned      = {entities.FLOW, 28},
      alert_suspicious_file_transfer        = {entities.FLOW, 29},
      alert_known_proto_on_non_std_port     = {entities.FLOW, 30},
      alert_flow_risk                       = {entities.FLOW, 31},
      alert_unexpected_dhcp_server          = {entities.FLOW, 32},
      alert_unexpected_dns_server           = {entities.FLOW, 33},
      alert_unexpected_smtp_server          = {entities.FLOW, 34},
      alert_unexpected_ntp_server           = {entities.FLOW, 35},
      alert_zero_tcp_window                 = {entities.FLOW, 36},
      alert_iec_invalid_transition          = {entities.FLOW, 37},
      alert_remote_to_local_insecure_proto  = {entities.FLOW, 38},
      alert_ndpi_url_possible_xss           = {entities.FLOW, 39},
      alert_ndpi_url_possible_sql_injection = {entities.FLOW, 40},
      alert_ndpi_url_possible_rce_injection = {entities.FLOW, 41},
      alert_ndpi_http_suspicious_user_agent = {entities.FLOW, 42},
      alert_ndpi_http_numeric_ip_host       = {entities.FLOW, 43},
      alert_ndpi_http_suspicious_url        = {entities.FLOW, 44},
      alert_ndpi_http_suspicious_header     = {entities.FLOW, 45},
      alert_ndpi_tls_not_carrying_https     = {entities.FLOW, 46},
      alert_ndpi_suspicious_dga_domain      = {entities.FLOW, 47},
      alert_ndpi_malformed_packet           = {entities.FLOW, 48},
      alert_ndpi_ssh_obsolete               = {entities.FLOW, 49},
      alert_ndpi_smb_insecure_version       = {entities.FLOW, 50},
      alert_ndpi_tls_suspicious_esni_usage  = {entities.FLOW, 51},
      alert_ndpi_unsafe_protocol            = {entities.FLOW, 52},
      alert_ndpi_dns_suspicious_traffic     = {entities.FLOW, 53},
      alert_ndpi_tls_missing_sni            = {entities.FLOW, 54},
      alert_iec_unexpected_type_id          = {entities.FLOW, 55},
      -- NOTE: for flow alerts not not go beyond the size of Bitmap alert_map inside Flow.h (currently 128)

      alert_device_connection              = {entities.OTHER, 1 },
      alert_device_disconnection           = {entities.OTHER, 2 },
      alert_dropped_alerts                 = {entities.OTHER, 3 },
      alert_flow_misbehaviour              = {entities.OTHER, 4 }, -- No longer used
      alert_flows_flood                    = {entities.OTHER, 5 }, -- No longer used, check alert_flows_flood_attacker and alert_flows_flood_victim
      alert_ghost_network                  = {entities.OTHER, 6 },
      alert_host_pool_connection           = {entities.OTHER, 7 },
      alert_host_pool_disconnection        = {entities.OTHER, 8 },
      alert_influxdb_dropped_points        = {entities.OTHER, 9 },
      alert_influxdb_error                 = {entities.OTHER, 10},
      alert_influxdb_export_failure        = {entities.OTHER, 11},
      alert_ip_outsite_dhcp_range          = {entities.OTHER, 13},
      alert_list_download_failed           = {entities.OTHER, 14},
      alert_login_failed                   = {entities.OTHER, 15},
      alert_mac_ip_association_change      = {entities.OTHER, 16},
      alert_misbehaving_flows_ratio        = {entities.OTHER, 17},
      alert_misconfigured_app              = {entities.OTHER, 18},
      alert_new_device                     = {entities.OTHER, 19}, -- No longer used
      alert_nfq_flushed                    = {entities.OTHER, 20},
      alert_none                           = {entities.OTHER, 21}, -- No longer used
      alert_periodic_activity_not_executed = {entities.OTHER, 22},
      alert_am_threshold_cross             = {entities.OTHER, 23},
      alert_port_duplexstatus_change       = {entities.OTHER, 24},
      alert_port_errors                    = {entities.OTHER, 25},
      alert_port_load_threshold_exceeded   = {entities.OTHER, 26},
      alert_port_mac_changed               = {entities.OTHER, 27},
      alert_port_status_change             = {entities.OTHER, 28},
      alert_process_notification           = {entities.OTHER, 29},
      alert_quota_exceeded                 = {entities.OTHER, 30},
      alert_request_reply_ratio            = {entities.OTHER, 31},
      alert_slow_periodic_activity         = {entities.OTHER, 32},
      alert_slow_purge                     = {entities.OTHER, 33},
      alert_snmp_device_reset              = {entities.OTHER, 34},
      alert_snmp_topology_changed          = {entities.OTHER, 35},
      alert_suspicious_activity            = {entities.OTHER, 36}, -- No longer used
      alert_tcp_syn_flood                  = {entities.OTHER, 37}, -- No longer used, check alert_tcp_syn_flood_attacker and alert_tcp_syn_flood_victim
      alert_tcp_syn_scan                   = {entities.OTHER, 38}, -- No longer used, check alert_tcp_syn_scan_attacker and alert_tcp_syn_scan_victim
      alert_test_failed                    = {entities.OTHER, 39},
      alert_threshold_cross                = {entities.OTHER, 40},
      alert_too_many_drops                 = {entities.OTHER, 41},
      alert_unresponsive_device            = {entities.OTHER, 42},
      alert_user_activity                  = {entities.OTHER, 43},
      alert_user_script_calls_drops        = {entities.OTHER, 44},
      alert_host_log                       = {entities.OTHER, 45},
      alert_attack_mitigation_via_snmp     = {entities.OTHER, 46},
      alert_iec104_error                   = {entities.OTHER, 47}, -- No longer used
      alert_lateral_movement               = {entities.OTHER, 48},
      alert_list_download_succeeded        = {entities.OTHER, 49},
      alert_no_if_activity                 = {entities.OTHER, 50}, -- scripts/plugins/alerts/internals/no_if_activity
      alert_unexpected_new_device          = {entities.OTHER, 51}, -- scripts/plugins/alerts/security/unexpected_new_device
      alert_shell_script_executed          = {entities.OTHER, 52}, -- scripts/plugins/endpoints/shell_alert_endpoint
      alert_periodicity_update             = {entities.OTHER, 53}, -- pro/scripts/enterprise_l_plugins/alerts/network/periodicity_update
      alert_dns_positive_error_ratio       = {entities.OTHER, 54}, -- pro/scripts/enterprise_l_plugins/alerts/network/dns_positive_error_ratio
      alert_fail2ban_executed              = {entities.OTHER, 55}, -- pro/scripts/pro_plugins/endpoints/fail2ban_alert_endpoint
      alert_flows_flood_attacker           = {entities.OTHER, 56},
      alert_flows_flood_victim             = {entities.OTHER, 57},
      alert_tcp_syn_flood_attacker         = {entities.OTHER, 58},
      alert_tcp_syn_flood_victim           = {entities.OTHER, 59},
      alert_tcp_syn_scan_attacker          = {entities.OTHER, 60},
      alert_tcp_syn_scan_victim            = {entities.OTHER, 61},
      alert_contacted_peers                = {entities.OTHER, 62},
      alert_contacts_anomaly               = {entities.OTHER, 63}, -- scripts/plugins/alerts/security/unexpected_host_behaviour/modules/contacted_hosts_behaviour
      alert_score_anomaly_client           = {entities.OTHER, 64}, -- scripts/plugins/alerts/security/unexpected_host_behaviour/modules/score_behaviour
      alert_score_anomaly_server           = {entities.OTHER, 65}, -- scripts/plugins/alerts/security/unexpected_host_behaviour/modules/score_behaviour
      alert_active_flows_anomaly_client    = {entities.OTHER, 66}, -- scripts/plugins/alerts/security/unexpected_host_behaviour/modules/active_flows_behaviour
      alert_active_flows_anomaly_server    = {entities.OTHER, 67}, -- scripts/plugins/alerts/security/unexpected_host_behaviour/modules/active_flows_behaviour
      alert_broadcast_domain_too_large     = {entities.OTHER, 68},
      
      -- Add here additional keys for alerts generated
      -- by ntopng plugins
      -- WARNING: make sure integers do NOT OVERLAP with
      -- user alerts
   },
   user = {
      alert_user_01                        = {entities.OTHER, 32768},
      alert_user_02                        = {entities.OTHER, 32769},
      alert_user_03                        = {entities.OTHER, 32770},
      alert_user_04                        = {entities.OTHER, 32771},
      alert_user_05                        = {entities.OTHER, 32772},
      -- Add here additional keys generated by
      -- user plugin
   },
}

-- ##############################################

-- A table to keep the reverse mapping between integer alert keys and string alert keys
local alert_id_to_alert_key = {}

for _, ntopng_user in ipairs({"ntopng", "user"}) do
   for cur_key_string, cur_key_array in pairs(alert_keys[ntopng_user]) do
      local cur_entity, cur_id = cur_key_array[1], cur_key_array[2]

      if not alert_id_to_alert_key[cur_entity] then
	 alert_id_to_alert_key[cur_entity] = {}
      end

      alert_id_to_alert_key[cur_entity][cur_id] = cur_key_string
   end
end

-- ##############################################

-- @brief Parse an alert key, check if it is compliant with the expected format, and returns the parsed key and a status message
--
--        Alert keys must be specified as an array of two numbers as {<ENTITY>, <entity_key>}:
--          - <ENTITY> is an integer greater than or equal to zero and less than 65535 and can be used to uniquely identify an alert entity.
--          - <entity_key> is an integer greater than or equal to zero and less than 65535 which is combined with <ENTITY>
--            to uniquely identify an alert. The resulting alert key is a 32bit integer where the 16 most significant bits
--            reserved for the <ENTITY> and the 16 least significant bits reserved for the <entity_key>.
--
--        Any other format is discarded and the parse function fails.
--
-- @param key The alert key to be parsed.
--            Examples:
--              `alert_keys.ntopng.alert_connection_issues`
--              `alert_keys.user.alert_user_01`
--              `{312, 513}`.
--              `{0, alert_keys.user.alert_user_01}`. In this case where ENTITY equals zero only the <entity_key> is taken
--
-- @return An integer corresponding to the parsed alert key and a status message which equals "OK" when no error occurred during parsing.
--
function alert_keys.parse_alert_key(key)
   local parsed_alert_key
   local status = "OK"

   if type(key) == "table" and #key == 2 then
      -- A table, let's parse it with ENTITY and key
      local entity, entity_key = key[1], key[2]

      if not type(entity) == "number" or entity < 0 or entity >= 0xFFFF then
	 -- ENTITY is out of bounds or not a number
	 status = "Invalid ENTITY specified. ENTITY must be between 0 and 65535."
      elseif not type(entity_key) == "number" or entity_key < 0 or entity_key >= 0xFFFF then
	 -- entity_key is out of bounds or not a number
	 status = "Invalid alert key specified. Alert key must be between 0 and 65535."
      elseif entity == 0 then
	 -- ENTITY is zero, this is a builtin key and we need to verify its exsistance
	 if not alert_id_to_alert_key[entity] or not alert_id_to_alert_key[entity][entity_key] then
	    status = "Alert key specified is not among the available alert keys."
	 else
	    parsed_alert_key = entity_key
	 end
      else
	 -- ENTITY in the 16 MSB and entity_key in the 16 LSB
	 parsed_alert_key = (entity << 16) + entity_key
      end
   else
      status = "Unexpected alert key type."
   end

   return parsed_alert_key, status
end

-- ##############################################

return alert_keys

-- ##############################################
