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
  memset(host_cb_arr, 0, sizeof(host_cb_arr));
  loadHostCallbacks(fcl);
};

/* **************************************************** */

HostCallbacksExecutor::~HostCallbacksExecutor() {
  if(periodic_host_cb) delete periodic_host_cb;
};

/* **************************************************** */
  
void HostCallbacksExecutor::loadHostCallbacks(HostCallbacksLoader *fcl) {

  /* Load list of 'periodicUpdate' callbacks */
  periodic_host_cb = fcl->getCallbacks(iface);

  /* Initialize callbacks array for quick lookup */
  for(std::list<HostCallback*>::iterator it = periodic_host_cb->begin(); it != periodic_host_cb->end(); ++it) {
    HostCallback *cb = (*it);
    host_cb_arr[cb->getType()] = cb;
  }
}

/* **************************************************** */

bool HostCallbacksExecutor::isTimeToRunCallback(HostCallback *callback, HostCallbackStatus *status, time_t now) {
  if (!callback->getPeriod()) return true; /* No periodicity configured - always run */
  if (!status || !status->getLastCallTime()) return true; /* First time - run */
  if (status->getLastCallTime() + callback->getPeriod() <= now) return true; /* Timeout reached - run */
  return false; /* Not yet */
}

/* **************************************************** */

void HostCallbacksExecutor::releaseAlert(HostAlert *alert) {
  Host *h = alert->getHost();

  /* Remove from the list of engaged alerts */
  h->removeEngagedAlert(alert);

  /* Enqueue the released alert to be notified */
  iface->enqueueHostAlert(alert);
}

/* **************************************************** */

void HostCallbacksExecutor::releaseAllDisabledAlerts(Host *h) {
  for (u_int i = 0; i < NUM_DEFINED_HOST_CALLBACKS; i++) {
    HostCallbackType t = (HostCallbackType) i;
    HostCallback *cb = getCallback(t);

    if (!cb) { /* callback disabled, check engaged alerts with auto release */
      std::list<HostAlert*> *cb_alerts = h->getEngagedAlerts(t);

      for(std::list<HostAlert*>::iterator it = cb_alerts->begin(); it != cb_alerts->end(); ++it) {
        HostAlert *alert = (*it);
        if (alert->hasAutoRelease()) {
          alert->release();
          releaseAlert(alert);
        }
      }
    }
  }
}

/* **************************************************** */

void HostCallbacksExecutor::execCallbacks(Host *h) {
  time_t now = time(NULL);

  /* Release (auto-release) alerts for disabled callbacks */
  releaseAllDisabledAlerts(h);

  /* Exec all enabled callbacks */
  for(std::list<HostCallback*>::iterator it = periodic_host_cb->begin(); it != periodic_host_cb->end(); ++it) {
    HostCallback *cb = (*it);
    HostCallbackStatus *cbs = cb->getStatus(h, true /* create */);
    HostCallbackType ct = cb->getType();
    std::list<HostAlert*> *cb_alerts = h->getEngagedAlerts(ct);

    /* Check if it's time to run the callback on this host */
    if (isTimeToRunCallback(cb, cbs, now)) {
      std::list<HostAlert*>::iterator it;

      /* Initializing (auto-release) alerts to expiring, to check if
       * they need to be released when not engaged again */
      for (it = cb_alerts->begin(); it != cb_alerts->end(); ++it)
        if ((*it)->hasAutoRelease()) (*it)->setExpiring();

      /* Call Handler */
      cb->periodicUpdate(h, cb_alerts);

      /* Check alerts to be released */
      it = cb_alerts->begin();
      while (it != cb_alerts->end()) {
        HostAlert *alert = (*it);
        ++it; /* inc the iterator before removing */
        if (alert->isExpired() && !alert->isReleased()) alert->release();
        if (alert->isReleased()) releaseAlert(alert);
      }

      if (cbs)
        cbs->setLastCallTime(now);
    }
  }
}

/* **************************************************** */

