--
-- (C) 2020-21 - ntop.org
--

-- ##############################################

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/pools/?.lua;" .. package.path

-- ##############################################

local alert_entities = require "alert_entities"

-- ##############################################

-- Use for 'other' keys that don't overlap with other entities.
-- Eventually, every alert listed below will have its own entity defined and other will disappear.
-- Currently, it is necessary to handle the transition
local OTHER_BASE_KEY = 4096

-- ##############################################

local alert_keys = {
   ntopng = {
      -- First 1024 (0 to 1023) IDs reserved for flow status alerts.
      -- Flow statuses are a Bitmap of 128 bits. 1024 is just to keep a safe margin
      -- and possibly enlarge Bitmap in the future
      -- NOTE: Keep them in sync with ntop_typedefs.h FlowAlertType
      flow_alert_normal                          = {entity = alert_entities.flow, key = 0},
      flow_alert_blacklisted                     = {entity = alert_entities.flow, key = 1},
      flow_alert_blacklisted_country             = {entity = alert_entities.flow, key = 2},
      flow_alert_flow_blocked                    = {entity = alert_entities.flow, key = 3},
      flow_alert_data_exfiltration               = {entity = alert_entities.flow, key = 4},
      flow_alert_device_protocol_not_allowed     = {entity = alert_entities.flow, key = 5},
      flow_alert_dns_data_exfiltration           = {entity = alert_entities.flow, key = 6},
      flow_alert_dns_invalid_query               = {entity = alert_entities.flow, key = 7},
      flow_alert_elephant_flow                   = {entity = alert_entities.flow, key = 8},
      flow_alert_elephant_remote_to_local        = {entity = alert_entities.flow, key = 9},  -- No longer used, can be recycled
      flow_alert_external                        = {entity = alert_entities.flow, key = 10},
      flow_alert_longlived                       = {entity = alert_entities.flow, key = 11},
      flow_alert_low_goodput                     = {entity = alert_entities.flow, key = 12},
      flow_alert_malicious_signature             = {entity = alert_entities.flow, key = 13},
      flow_alert_internals                       = {entity = alert_entities.flow, key = 14},
      flow_alert_potentially_dangerous           = {entity = alert_entities.flow, key = 15},
      flow_alert_remote_to_remote                = {entity = alert_entities.flow, key = 16},
      flow_alert_suspicious_tcp_probing          = {entity = alert_entities.flow, key = 17},
      flow_alert_suspicious_tcp_syn_probing      = {entity = alert_entities.flow, key = 18},
      flow_alert_tcp_connection_issues           = {entity = alert_entities.flow, key = 19},
      flow_alert_tcp_connection_refused          = {entity = alert_entities.flow, key = 20},
      flow_alert_tcp_severe_connection_issues    = {entity = alert_entities.flow, key = 21},
      flow_alert_tls_certificate_expired         = {entity = alert_entities.flow, key = 22},
      flow_alert_tls_certificate_mismatch        = {entity = alert_entities.flow, key = 23},
      flow_alert_tls_old_protocol_version        = {entity = alert_entities.flow, key = 24},
      flow_alert_tls_unsafe_ciphers              = {entity = alert_entities.flow, key = 25},
      flow_alert_udp_unidirectional              = {entity = alert_entities.flow, key = 26},
      flow_alert_web_mining                      = {entity = alert_entities.flow, key = 27},
      flow_alert_tls_certificate_selfsigned      = {entity = alert_entities.flow, key = 28},
      flow_alert_suspicious_file_transfer        = {entity = alert_entities.flow, key = 29},
      flow_alert_known_proto_on_non_std_port     = {entity = alert_entities.flow, key = 30},
      flow_alert_flow_risk                       = {entity = alert_entities.flow, key = 31},
      flow_alert_unexpected_dhcp_server          = {entity = alert_entities.flow, key = 32},
      flow_alert_unexpected_dns_server           = {entity = alert_entities.flow, key = 33},
      flow_alert_unexpected_smtp_server          = {entity = alert_entities.flow, key = 34},
      flow_alert_unexpected_ntp_server           = {entity = alert_entities.flow, key = 35},
      flow_alert_zero_tcp_window                 = {entity = alert_entities.flow, key = 36},
      flow_alert_iec_invalid_transition          = {entity = alert_entities.flow, key = 37},
      flow_alert_remote_to_local_insecure_proto  = {entity = alert_entities.flow, key = 38},
      flow_alert_ndpi_url_possible_xss           = {entity = alert_entities.flow, key = 39},
      flow_alert_ndpi_url_possible_sql_injection = {entity = alert_entities.flow, key = 40},
      flow_alert_ndpi_url_possible_rce_injection = {entity = alert_entities.flow, key = 41},
      flow_alert_ndpi_http_suspicious_user_agent = {entity = alert_entities.flow, key = 42},
      flow_alert_ndpi_http_numeric_ip_host       = {entity = alert_entities.flow, key = 43},
      flow_alert_ndpi_http_suspicious_url        = {entity = alert_entities.flow, key = 44},
      flow_alert_ndpi_http_suspicious_header     = {entity = alert_entities.flow, key = 45},
      flow_alert_ndpi_tls_not_carrying_https     = {entity = alert_entities.flow, key = 46},
      flow_alert_ndpi_suspicious_dga_domain      = {entity = alert_entities.flow, key = 47},
      flow_alert_ndpi_malformed_packet           = {entity = alert_entities.flow, key = 48},
      flow_alert_ndpi_ssh_obsolete               = {entity = alert_entities.flow, key = 49},
      flow_alert_ndpi_smb_insecure_version       = {entity = alert_entities.flow, key = 50},
      flow_alert_ndpi_tls_suspicious_esni_usage  = {entity = alert_entities.flow, key = 51},
      flow_alert_ndpi_unsafe_protocol            = {entity = alert_entities.flow, key = 52},
      flow_alert_ndpi_dns_suspicious_traffic     = {entity = alert_entities.flow, key = 53},
      flow_alert_ndpi_tls_missing_sni            = {entity = alert_entities.flow, key = 54},
      flow_alert_iec_unexpected_type_id          = {entity = alert_entities.flow, key = 55},
      -- NOTE: for flow alerts not not go beyond the size of Bitmap alert_map inside Flow.h (currently 128)

      host_alert_normal                          = {entity = alert_entities.host, key =  0},
      host_alert_flow_flood_attacker             = {entity = alert_entities.host, key =  1},
      host_alert_flow_flood_victim               = {entity = alert_entities.host, key =  2},
      host_alert_syn_scan_attacker               = {entity = alert_entities.host, key =  3},
      host_alert_syn_scan_victim                 = {entity = alert_entities.host, key =  4},
      host_alert_syn_flood_attacker              = {entity = alert_entities.host, key =  5},
      host_alert_syn_flood_victim                = {entity = alert_entities.host, key =  6},
      host_alert_replies_requests_ratio          = {entity = alert_entities.host, key =  8},
      host_alert_dns_requests_errors_ratio       = {entity = alert_entities.host, key =  9},
      host_alert_smtp_server_contacts            = {entity = alert_entities.host, key = 10},
      host_alert_dns_server_contacts             = {entity = alert_entities.host, key = 11},
      host_alert_ntp_server_contacts             = {entity = alert_entities.host, key = 12},
      host_alert_p2p_traffic                     = {entity = alert_entities.host, key = 13},
      host_alert_dns_traffic                     = {entity = alert_entities.host, key = 14},
      host_alert_traffic                         = {entity = alert_entities.host, key = 15},
      host_alert_idle_time                       = {entity = alert_entities.host, key = 16},
      host_alert_activity_time                   = {entity = alert_entities.host, key = 17},
      host_alert_flows                           = {entity = alert_entities.host, key = 18},
      host_alert_throughput                      = {entity = alert_entities.host, key = 19},
      host_alert_score                           = {entity = alert_entities.host, key = 20},
      host_alert_packets                         = {entity = alert_entities.host, key = 21},
      host_alert_snmp_attack_mitigation          = {entity = alert_entities.host, key = 22},
      host_alert_unexpected_host_behavior        = {entity = alert_entities.host, key = 23},
      -- NOTE: for host alerts not not go beyond the size of Bitmap alert_map inside Host.h (currently 128)

      alert_device_connection              = {entity = alert_entities.other, key = OTHER_BASE_KEY + 1 },
      alert_device_disconnection           = {entity = alert_entities.other, key = OTHER_BASE_KEY + 2 },
      alert_dropped_alerts                 = {entity = alert_entities.other, key = OTHER_BASE_KEY + 3 },
      alert_flow_misbehaviour              = {entity = alert_entities.other, key = OTHER_BASE_KEY + 4 }, -- No longer used
      alert_flows_flood                    = {entity = alert_entities.other, key = OTHER_BASE_KEY + 5 }, -- No longer used, check alert_flows_flood_attacker and alert_flows_flood_victim
      alert_ghost_network                  = {entity = alert_entities.other, key = OTHER_BASE_KEY + 6 },
      alert_host_pool_connection           = {entity = alert_entities.other, key = OTHER_BASE_KEY + 7 },
      alert_host_pool_disconnection        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 8 },
      alert_influxdb_dropped_points        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 9 },
      alert_influxdb_error                 = {entity = alert_entities.other, key = OTHER_BASE_KEY + 10},
      alert_influxdb_export_failure        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 11},
      alert_ip_outsite_dhcp_range          = {entity = alert_entities.other, key = OTHER_BASE_KEY + 13},
      alert_list_download_failed           = {entity = alert_entities.other, key = OTHER_BASE_KEY + 14},
      alert_login_failed                   = {entity = alert_entities.other, key = OTHER_BASE_KEY + 15},
      alert_mac_ip_association_change      = {entity = alert_entities.other, key = OTHER_BASE_KEY + 16},
      alert_misbehaving_flows_ratio        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 17},
      alert_misconfigured_app              = {entity = alert_entities.other, key = OTHER_BASE_KEY + 18},
      alert_new_device                     = {entity = alert_entities.other, key = OTHER_BASE_KEY + 19}, -- No longer used
      alert_nfq_flushed                    = {entity = alert_entities.other, key = OTHER_BASE_KEY + 20},
      alert_none                           = {entity = alert_entities.other, key = OTHER_BASE_KEY + 21}, -- No longer used
      alert_periodic_activity_not_executed = {entity = alert_entities.other, key = OTHER_BASE_KEY + 22},
      alert_am_threshold_cross             = {entity = alert_entities.other, key = OTHER_BASE_KEY + 23},
      alert_port_duplexstatus_change       = {entity = alert_entities.other, key = OTHER_BASE_KEY + 24},
      alert_port_errors                    = {entity = alert_entities.other, key = OTHER_BASE_KEY + 25},
      alert_port_load_threshold_exceeded   = {entity = alert_entities.other, key = OTHER_BASE_KEY + 26},
      alert_port_mac_changed               = {entity = alert_entities.other, key = OTHER_BASE_KEY + 27},
      alert_port_status_change             = {entity = alert_entities.other, key = OTHER_BASE_KEY + 28},
      alert_process_notification           = {entity = alert_entities.other, key = OTHER_BASE_KEY + 29},
      alert_quota_exceeded                 = {entity = alert_entities.other, key = OTHER_BASE_KEY + 30},
      alert_request_reply_ratio            = {entity = alert_entities.other, key = OTHER_BASE_KEY + 31},
      alert_slow_periodic_activity         = {entity = alert_entities.other, key = OTHER_BASE_KEY + 32},
      alert_slow_purge                     = {entity = alert_entities.other, key = OTHER_BASE_KEY + 33},
      alert_snmp_device_reset              = {entity = alert_entities.other, key = OTHER_BASE_KEY + 34},
      alert_snmp_topology_changed          = {entity = alert_entities.other, key = OTHER_BASE_KEY + 35},
      alert_suspicious_activity            = {entity = alert_entities.other, key = OTHER_BASE_KEY + 36}, -- No longer used
      alert_tcp_syn_flood                  = {entity = alert_entities.other, key = OTHER_BASE_KEY + 37}, -- No longer used, check alert_tcp_syn_flood_attacker and alert_tcp_syn_flood_victim
      alert_tcp_syn_scan                   = {entity = alert_entities.other, key = OTHER_BASE_KEY + 38}, -- No longer used, check alert_tcp_syn_scan_attacker and alert_tcp_syn_scan_victim
      alert_test_failed                    = {entity = alert_entities.other, key = OTHER_BASE_KEY + 39},
      alert_threshold_cross                = {entity = alert_entities.other, key = OTHER_BASE_KEY + 40},
      alert_too_many_drops                 = {entity = alert_entities.other, key = OTHER_BASE_KEY + 41},
      alert_unresponsive_device            = {entity = alert_entities.other, key = OTHER_BASE_KEY + 42},
      alert_user_activity                  = {entity = alert_entities.other, key = OTHER_BASE_KEY + 43},
      alert_user_script_calls_drops        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 44},
      alert_host_log                       = {entity = alert_entities.other, key = OTHER_BASE_KEY + 45},
      alert_attack_mitigation_via_snmp     = {entity = alert_entities.other, key = OTHER_BASE_KEY + 46},
      alert_iec104_error                   = {entity = alert_entities.other, key = OTHER_BASE_KEY + 47}, -- No longer used
      alert_lateral_movement               = {entity = alert_entities.other, key = OTHER_BASE_KEY + 48},
      alert_list_download_succeeded        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 49},
      alert_no_if_activity                 = {entity = alert_entities.other, key = OTHER_BASE_KEY + 50}, -- scripts/plugins/alerts/internals/no_if_activity
      alert_unexpected_new_device          = {entity = alert_entities.other, key = OTHER_BASE_KEY + 51}, -- scripts/plugins/alerts/security/unexpected_new_device
      alert_shell_script_executed          = {entity = alert_entities.other, key = OTHER_BASE_KEY + 52}, -- scripts/plugins/endpoints/shell_alert_endpoint
      alert_periodicity_update             = {entity = alert_entities.other, key = OTHER_BASE_KEY + 53}, -- pro/scripts/enterprise_l_plugins/alerts/network/periodicity_update
      alert_dns_positive_error_ratio       = {entity = alert_entities.other, key = OTHER_BASE_KEY + 54}, -- pro/scripts/enterprise_l_plugins/alerts/network/dns_positive_error_ratio
      alert_fail2ban_executed              = {entity = alert_entities.other, key = OTHER_BASE_KEY + 55}, -- pro/scripts/pro_plugins/endpoints/fail2ban_alert_endpoint
      alert_flows_flood_attacker           = {entity = alert_entities.other, key = OTHER_BASE_KEY + 56},
      alert_flows_flood_victim             = {entity = alert_entities.other, key = OTHER_BASE_KEY + 57},
      alert_tcp_syn_flood_attacker         = {entity = alert_entities.other, key = OTHER_BASE_KEY + 58},
      alert_tcp_syn_flood_victim           = {entity = alert_entities.other, key = OTHER_BASE_KEY + 59},
      alert_tcp_syn_scan_attacker          = {entity = alert_entities.other, key = OTHER_BASE_KEY + 60},
      alert_tcp_syn_scan_victim            = {entity = alert_entities.other, key = OTHER_BASE_KEY + 61},
      alert_contacted_peers                = {entity = alert_entities.other, key = OTHER_BASE_KEY + 62},
      alert_contacts_anomaly               = {entity = alert_entities.other, key = OTHER_BASE_KEY + 63}, -- scripts/plugins/alerts/security/unexpected_host_behaviour/modules/contacted_hosts_behaviour
      alert_score_anomaly_client           = {entity = alert_entities.other, key = OTHER_BASE_KEY + 64}, -- scripts/plugins/alerts/security/unexpected_host_behaviour/modules/score_behaviour
      alert_score_anomaly_server           = {entity = alert_entities.other, key = OTHER_BASE_KEY + 65}, -- scripts/plugins/alerts/security/unexpected_host_behaviour/modules/score_behaviour
      alert_active_flows_anomaly_client    = {entity = alert_entities.other, key = OTHER_BASE_KEY + 66}, -- scripts/plugins/alerts/security/unexpected_host_behaviour/modules/active_flows_behaviour
      alert_active_flows_anomaly_server    = {entity = alert_entities.other, key = OTHER_BASE_KEY + 67}, -- scripts/plugins/alerts/security/unexpected_host_behaviour/modules/active_flows_behaviour
      alert_broadcast_domain_too_large     = {entity = alert_entities.other, key = OTHER_BASE_KEY + 68},
      
      -- Add here additional keys for alerts generated
      -- by ntopng plugins
      -- WARNING: make sure integers do NOT OVERLAP with
      -- user alerts
   },
   user = {
      alert_user_01                        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 32768},
      alert_user_02                        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 32769},
      alert_user_03                        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 32770},
      alert_user_04                        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 32771},
      alert_user_05                        = {entity = alert_entities.other, key = OTHER_BASE_KEY + 32772},
      -- Add here additional keys generated by
      -- user plugin
   },
}

-- ##############################################

-- A table to keep the reverse mapping between integer alert keys and string alert keys
local alert_id_to_alert_key = {}

for _, ntopng_user in ipairs({"ntopng", "user"}) do
   for cur_key_string, cur_key_array in pairs(alert_keys[ntopng_user]) do
      local cur_entity_id = cur_key_array.entity.entity_id
      local cur_key = cur_key_array.key

      if not alert_id_to_alert_key[cur_entity_id] then
	 alert_id_to_alert_key[cur_entity_id] = {}
      end

      alert_id_to_alert_key[cur_entity_id][cur_key] = cur_key_string
   end
end

-- ##############################################

return alert_keys

-- ##############################################
