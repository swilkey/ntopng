/*
 *
 * (C) 2013-21 - ntop.org
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 */

#include "host_alerts_includes.h"

/* ***************************************************** */

NTPServerContactsAlert::NTPServerContactsAlert(HostCallback *c, Host *f, AlertLevel severity, u_int8_t cli_score, u_int8_t srv_score, u_int64_t _contacts, u_int64_t _contacts_threshold)
  : ServerContactsAlert(c, f, severity, cli_score, srv_score, _contacts, _contacts_threshold) {
};

/* ***************************************************** */
