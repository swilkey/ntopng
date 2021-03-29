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

HostCallback *HostCallbacksExecutor::findCallback(HostCallbackType callback_type) {
  /* TODO optimize this lookup */
  for(list<HostCallback*>::iterator it = periodic_host_cb->begin(); it != periodic_host_cb->end(); ++it) {
    if((*it)->getType() == callback_type)
      return (*it);
  }
  return NULL;
}

/* **************************************************** */

void HostCallbacksExecutor::execCallbacks(Host *h) {
  std::list<HostAlert*> *engaged_alerts = h->getEngagedAlerts();

  /* Reset engages alerts status - this is used to check which one should be releaed */
  for(list<HostAlert*>::iterator it = engaged_alerts->begin(); it != engaged_alerts->end(); ++it) {
    HostAlert *alert = (*it);
    alert->setReleased(); /* initializing the status to released, on trigger this is set to engaged */
  }

  // TODO host_alert_normal

  /* Exec all enabled callbacks */
  for(list<HostCallback*>::iterator it = periodic_host_cb->begin(); it != periodic_host_cb->end(); ++it) {
    HostAlertType t = { host_alert_normal, alert_category_other };
    HostCallback *hc = (*it);

    h->setPendingAlert(t, alert_level_none); /* reset */

    /* TODO check if it's time for the callback to process the host,
     * otherwise set as still engaged all engaged alerts tied this callback.
     * Or, each plugin can declare it's periodicity (or change it with 'call me
     * in X minuted), and the engine calls it when (at least) that time is elapsed */

    /* Call Handler */
    hc->periodicUpdate(h);

    if (!ntop->getPrefs()->dontEmitHostAlerts()
        && h->getPendingAlert().id != host_alert_normal) {
      HostAlert *alert = NULL;

      /* Check if it's already engaged */
      alert = h->findEngagedAlert(h->getPendingAlert());

      if (alert) {
        /* Alert already engaged, update */
        hc->updateAlert(alert);
      } else {
        /* Build new alert */
        alert = hc->buildAlert(h->getPendingAlert(), h);

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
  }

  /* Check engaged alerts to be released */
  for(list<HostAlert*>::iterator it = engaged_alerts->begin(); it != engaged_alerts->end(); ++it) {
    HostAlert *alert = (*it);
    Host *host = alert->getHost();

    if (alert->isReleased()) {
      HostCallback *hc = findCallback(alert->getCallbackType());

      /* Update alert info */
      if (hc) hc->updateAlert(alert);

      /* Remove from the list of engaged alerts */
      host->removeEngagedAlert(alert);

      /* Enqueue the alert to be notified */
      iface->enqueueHostAlert(alert);
    }
  }
}

/* **************************************************** */
