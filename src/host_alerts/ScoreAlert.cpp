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

ScoreAlert::ScoreAlert(HostCallback *c, Host *f) : HostAlert(c, f) {
  score = score_threshold = 0;
};

/* ***************************************************** */

ndpi_serializer* ScoreAlert::getAlertJSON(ndpi_serializer* serializer) {
  if(serializer == NULL)
    return NULL;

  ndpi_serialize_string_uint64(serializer, "value", score);
  ndpi_serialize_string_uint64(serializer, "threshold", score_threshold);
  
  return serializer;
}

/* ***************************************************** */
