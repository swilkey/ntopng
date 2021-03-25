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

/* **************************************************** */

HostCallbacksExecutor::HostCallbacksExecutor(HostCallbacksLoader *fcl, NetworkInterface *_iface) {
  iface = _iface;
  loadHostCallbacks(fcl);
};

/* **************************************************** */

HostCallbacksExecutor::~HostCallbacksExecutor() {
  if(periodic_host_cb) delete periodic_host_cb;
};

/* **************************************************** */

HostAlert *HostCallbacksExecutor::execCallbacks(Host *h) {
  // HostAlertakkType predominant_alert = h->getPredominantAlert(); // TODO
  // HostCallback *predominant_callback = NULL; // TODO
  // std::list<HostCallback*> *callbacks = NULL; // TODO
  HostAlert *alert = NULL;

  for(list<HostCallback*>::iterator it = periodic_host_cb->begin(); it != periodic_host_cb->end(); ++it) {
    (*it)->periodicUpdate(h);

#if TODO
    /* Check if the callback triggered a predominant alert */
    if (h->getPredominantAlert().id != predominant_alert.id) {
      predominant_alert = h->getPredominantAlert();
      predominant_callback = (*it);
    }
#endif
  }

  /* Do NOT allocate any alert, there is nothing left to do as host alerts don't have to be emitted */
  if(ntop->getPrefs()->dontEmitHostAlerts()) return(NULL);

#if TODO
  /* Allocate the alert */
  alert = predominant_callback ? predominant_callback->buildAlert(f) : NULL;

  /* If the alert has been allocated successfully, set its severity */
  if(alert)
    alert->setSeverity(predominant_callback->getSeverity());
#endif
  
  return alert;
}

/* **************************************************** */
