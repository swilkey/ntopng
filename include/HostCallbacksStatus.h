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

#ifndef _HOST_CALLBACKS_STATUS_H_
#define _HOST_CALLBACKS_STATUS_H_

#include "ntop_includes.h"

class HostCallbacksStatus { /* Container to keep per-callback status (e.g., traffic delta between consecutive calls) */
 private:
  time_t last_call_min, /* The last time minute callbacks were executed  */
    last_call_5min;     /* The last time 5minute callbacks were executed */

 public:
  HostCallbacksStatus() { last_call_min = last_call_5min = 0; }
  virtual ~HostCallbacksStatus() {};

  inline bool isTimeToRunMinCallbacks(time_t now)  const { return last_call_min  +  60 <= now; }
  inline bool isTimeToRun5MinCallbacks(time_t now) const { return last_call_5min + 300 <= now; }

  inline void setMinLastCallTime(time_t now)  { last_call_min  = now; }
  inline void set5MinLastCallTime(time_t now) { last_call_5min = now; }
};

#endif /* _HOST_CALLBACKS_STATUS_H_ */
