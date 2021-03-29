--
-- (C) 2020-21 - ntop.org
--

-- ##############################################

local host_alert_keys = {
   host_alert_normal                    =  0,
   host_alert_flow_flood_attacker       =  1,
   host_alert_flow_flood_victim         =  2,
   host_alert_syn_scan_attacker         =  3,
   host_alert_syn_scan_victim           =  4,
   host_alert_syn_flood_attacker        =  5,
   host_alert_syn_flood_victim          =  6,
   host_alert_replies_requests_ratio    =  8,
   host_alert_dns_requests_errors_ratio =  9,
   host_alert_smtp_server_contacts      = 10,
   host_alert_dns_server_contacts       = 11,
   host_alert_ntp_server_contacts       = 12,
   host_alert_p2p_traffic               = 13,
   host_alert_dns_traffic               = 14,
   host_alert_traffic                   = 15,
   host_alert_idle_time                 = 16,
   host_alert_activity_time             = 17,
   host_alert_flows                     = 18,
   host_alert_throughput                = 19,
   host_alert_score                     = 20,
   host_alert_packets                   = 21,
   host_alert_snmp_attack_mitigation    = 22,
   host_alert_unexpected_host_behavior  = 23,
   -- NOTE: for host alerts not not go beyond the size of Bitmap alert_map inside Host.h (currently 128)
}

-- ##############################################

return host_alert_keys

-- ##############################################
