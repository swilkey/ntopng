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

#include "ntop_includes.h"
#include "host_callbacks_includes.h"

/* ***************************************************** */

ThroughputHostCallback::ThroughputHostCallback() : HostCallback(ntopng_edition_community) {
  throughput_threshold = (u_int64_t)-1;
};

/* ***************************************************** */

void ThroughputHostCallback::periodicUpdate(Host *h, std::list<HostAlert*> *engaged_alerts) {
  DeltaHostCallbackStatus *status = static_cast<DeltaHostCallbackStatus*>(getStatus(h));
  u_int64_t delta;
  time_t prev_call, cur_call, delta_call;

  if(status) {
    delta = status->delta(h->getNumBytes());

    if(delta > 0
       && (prev_call = status->getLastCallTime()) > 0 /* Time of the previous call */
       && (cur_call = time(NULL)) > 0 /* Time of the current call */
       && (delta_call = cur_call - prev_call) > 0 /* Positive difference */) {
      float thpt = delta / (float)delta_call;

      if(thpt * 8 * 1024 * 1024 /* throughput in Mbps */ > throughput_threshold)
	; /* TODO: trigger */
    }

  }
}

/* ***************************************************** */

bool ThroughputHostCallback::loadConfiguration(json_object *config) {
  json_object *json_threshold;

  HostCallback::loadConfiguration(config); /* Parse parameters in common */

  if(json_object_object_get_ex(config, "threshold", &json_threshold))
    throughput_threshold = json_object_get_int64(json_threshold);

  // ntop->getTrace()->traceEvent(TRACE_NORMAL, "%s %u", json_object_to_json_string(config), throughput_threshold);

  return(true);
}

/* ***************************************************** */

