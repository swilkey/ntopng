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

#ifndef _HOST_ALERT_H_
#define _HOST_ALERT_H_

#include "ntop_includes.h"

class HostCallback;

class HostAlert {
 private:
  Host *host;
  AlertLevel severity_id;
  bool released; /* to be released */
  bool expiring; /* engaged, under re-evaluation */
  bool auto_release;
  HostCallbackType callback_type;
  std::string callback_name;
  time_t engage_time;
  time_t release_time;

  /* 
     Adds to the passed `serializer` (generated with `getAlertSerializer`) information specific to this alert
   */
  virtual ndpi_serializer* getAlertJSON(ndpi_serializer* serializer)  { return serializer; }  

 public:
  HostAlert(HostCallback *c, Host *h);
  virtual ~HostAlert();

  bool loadConfiguration(json_object *config);
  inline void setSeverity(AlertLevel alert_severity) { severity_id = alert_severity; };

  virtual HostAlertType getAlertType() const = 0;
  virtual std::string   getName()      const = 0;

  inline AlertLevel    getSeverity()  const { return(severity_id); }  
  inline Host *getHost() const { return(host); }
  inline HostCallbackType getCallbackType() const { return(callback_type); }
  inline std::string getCallbackName() const { return(callback_name); }

  inline void setEngaged()  { expiring = released = false; }

  inline void setExpiring() { expiring = true; }
  inline bool isExpired()   { return expiring; }

  inline void setReleased() { released = true; release_time = time(NULL); }
  inline bool isReleased()  { return released; }

  inline void disableAutoRelease() { auto_release = false; }
  inline bool isAutoReleaseEnabled() { return auto_release; }

  inline time_t getEngageTime()  { return engage_time; }
  inline time_t getReleaseTime() { return release_time; }

  /* 
     Generates the JSON alert serializer with base information and per-callback information gathered with `getAlertJSON`.
     NOTE: memory must be freed by the caller.
  */
  ndpi_serializer* getSerializedAlert();
};

#endif /* _HOST_ALERT_H_ */
