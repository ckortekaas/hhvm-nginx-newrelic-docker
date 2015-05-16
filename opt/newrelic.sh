#!/bin/bash

if [ ! -f /tmp/supervisord-newrelic.log ] ; then
  # Wait until Nginx has been configured before launching
  while [ ! -f /tmp/supervisord-nginx.log ]
  do
    sleep 2
  done

  export NR_INSTALL_SILENT=true
  export NR_INSTALL_KEY=${NEWRELIC_LICENSE_KEY}
  newrelic-install install
  touch /tmp/supervisord-newrelic.log
fi

exec nrsysmond-config --set license_key=${NEWRELIC_LICENSE_KEY} && /usr/sbin/nrsysmond -c /etc/newrelic/nrsysmond.cfg -l /dev/stdout -f
