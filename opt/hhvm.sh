#!/bin/bash

# Configure on first load..
if [ ! -f /tmp/supervisord-hhvm.log ] ; then
  # Wait until Nginx has been configured before launching
  while [ ! -f /tmp/supervisord-nginx.log ]
  do
    sleep 2
  done
  # TODO: pass in service environment variables

  touch /tmp/supervisord-hhvm.log
fi

exec hhvm --mode server -vServer.Type=fastcgi -vServer.Port=9000 --config /mnt/hhvm/config.hdf