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

#ifndef _SMTP_SERVER_CONTACTS_H_
#define _SMTP_SERVER_CONTACTS_H_

#include "ntop_includes.h"

class SMTPServerContacts : public ServerContacts {
private:
  u_int32_t getContactedServers(Host *h) const { return h->getSMTPContactCardinality(); };
  HostAlertType getAlertType() const { return SMTPServerContactsAlert::getClassType(); };
  HostAlert *allocAlert(HostCallback *c, Host *f, u_int64_t _contacts, u_int64_t _contacts_threshold) { return new SMTPServerContactsAlert(c, f, _contacts, _contacts_threshold); };

 public:
  SMTPServerContacts();
  ~SMTPServerContacts() {};

  HostCallbackID getID() const { return host_callback_smtp_server_contacts; }
  std::string getName()        const { return(std::string("smtp_contacts")); }
};

#endif
