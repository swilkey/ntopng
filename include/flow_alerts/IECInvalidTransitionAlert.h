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

#ifndef _IEC_INVALID_TRANSITION_ALERT_H_
#define _IEC_INVALID_TRANSITION_ALERT_H_

#include "ntop_includes.h"

class IECInvalidTransitionAlert : public FlowAlert {
 private:
  u_int32_t packet_epoch;
  u_int16_t type_i;
  u_int8_t type_id;

  ndpi_serializer* getAlertJSON(ndpi_serializer* serializer);

 public:
  static FlowAlertType getClassType() { return { flow_alert_iec_invalid_transition, alert_category_security }; }

  IECInvalidTransitionAlert(FlowCallback *c, Flow *f, struct timeval *_time, u_int16_t _type_i, u_int8_t _type_id) : FlowAlert(c, f) {
    type_i = _type_i;
    type_id = _type_id;
    packet_epoch = _time->tv_sec;
  };
  ~IECInvalidTransitionAlert() { };

  FlowAlertType getAlertType() const { return getClassType(); }
  std::string getName() const { return std::string("alert_iec_invalid_transition"); }
};

#endif /* _IEC_INVALID_TRANSITION_ALERT_H_ */
