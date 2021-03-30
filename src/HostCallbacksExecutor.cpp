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
  if (!callback) return false; /* Callback not available */
  if (!callback->getPeriod()) return true; /* No periodicity configured - always run */
  if (!status || !status->getLastCallTime()) return true; /* First time - run */
  if (status->getLastCallTime() + callback->getPeriod() <= now) return true; /* Timeout reached - run */
  return false; /* Not yet */
}

/* **************************************************** */

void HostCallbacksExecutor::execCallbacks(Host *h) {
  std::list<HostAlert*> *engaged_alerts = h->getEngagedAlerts();
  HostCallbackStatus *host_cb_status_cache[NUM_DEFINED_HOST_CALLBACKS]; /* optimization */
  time_t now = time(NULL);

  h->getCallbacksStatus(host_cb_status_cache);

  /* This is used to check which of the engaged should be released due to: 
   * - Callback disabled
   * - Alert no longer engaged */
  for(std::list<HostAlert*>::iterator it = engaged_alerts->begin(); it != engaged_alerts->end(); ++it) {
    HostAlert *alert = (*it);
    HostCallback *cb = getCallback(alert->getCallbackType());
    HostCallbackStatus *cbs = NULL;

    /* Get callback status */
    if (cb) {
      HostCallbackType ct = cb->getType();
      cbs = host_cb_status_cache[ct];
    }

    if (alert->isAutoReleaseEnabled() && isTimeToRunCallback(cb, cbs, now)) {
      /* Initializing the status to expiring, to check if this needs to be released (when not engaged again) */
      alert->setExpiring();
    }
  }

  /* Exec all enabled callbacks */
  for(std::list<HostCallback*>::iterator it = periodic_host_cb->begin(); it != periodic_host_cb->end(); ++it) {
    HostAlertType t = { host_alert_normal, alert_category_other };
    HostCallback *cb = (*it);
    HostCallbackType ct = cb->getType();
    HostCallbackStatus *cbs;

    if (!host_cb_status_cache[ct]) host_cb_status_cache[ct] = cb->getStatus(h, true /* create */);
    cbs = host_cb_status_cache[ct];

    /* Reset pending alert */
    h->setPendingAlert(t, alert_level_none);

   /* Check if it's time to run the callback on this host */
    if (isTimeToRunCallback(cb, cbs, now)) {

      /* Call Handler */
      cb->periodicUpdate(h);

      if (!ntop->getPrefs()->dontEmitHostAlerts()
          && h->getPendingAlert().id != host_alert_normal) {
        HostAlert *alert = NULL;

        /* Check if it's already engaged */
        alert = h->findEngagedAlert(h->getPendingAlert());

        if (alert) {
          /* Alert already engaged, update */
          cb->updateAlert(alert);
        } else {
          /* Build new alert */
          alert = cb->buildAlert(h->getPendingAlert(), h);

          if (alert) {
            /* Add to the list of engaged alerts*/
            h->addEngagedAlert(alert);
          }
        }

        if (alert) {
          alert->setEngaged();
          alert->setSeverity(h->getPendingAlertSeverity());

          /* Enqueue the alert to be notified */
          iface->enqueueHostAlert(alert);
        }
      }

      if (cbs)
        cbs->setLastCallTime(now);
    }
  }

  /* Check engaged alerts to be released */
  std::list<HostAlert*>::iterator it = engaged_alerts->begin();
  while (it != engaged_alerts->end()) {
    HostAlert *alert = (*it);
    Host *host = alert->getHost();

    ++it; /* inc the iterator before removing */

    if (alert->isExpired()) {
      HostCallback *cb = getCallback(alert->getCallbackType());

      alert->setReleased();

      /* Update alert info */
      if (cb) cb->updateAlert(alert);

      /* Remove from the list of engaged alerts */
      host->removeEngagedAlert(alert);

      /* Enqueue the alert to be notified */
      iface->enqueueHostAlert(alert);
    }
  }
}

/* **************************************************** */
