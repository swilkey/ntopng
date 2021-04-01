--
-- (C) 2020-21 - ntop.org
--

-- ##############################################

local host_alert_keys = {
   host_alert_normal                    =  0,
   host_alert_flow_flood                =  1,
   host_alert_syn_scan                  =  2,
   host_alert_syn_flood                 =  3,
   host_alert_replies_requests_ratio    =  4,
   host_alert_dns_requests_errors_ratio =  5,
   host_alert_smtp_server_contacts      =  6,
   host_alert_dns_server_contacts       =  7,
   host_alert_ntp_server_contacts       =  8,
   host_alert_p2p_traffic               =  9,
   host_alert_dns_traffic               = 10,
   host_alert_traffic                   = 11,
   host_alert_idle_time                 = 12,
   host_alert_activity_time             = 13,
   host_alert_flows                     = 14,
   host_alert_throughput                = 15,
   host_alert_score                     = 16,
   host_alert_packets                   = 17,
   host_alert_snmp_attack_mitigation    = 18,
   host_alert_unexpected_host_behavior  = 19,
   -- NOTE: for host alerts not not go beyond the size of Bitmap alert_map inside Host.h (currently 128)
}

-- ##############################################

return host_alert_keys

-- ##############################################
