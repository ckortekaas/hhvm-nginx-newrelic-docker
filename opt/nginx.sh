#!/bin/bash

# Configure on first load..
if [ ! -f /tmp/supervisord-nginx.log ] ; then
  mkdir -p /var/app/current

  # Grab the code from an S3 bucket?
  if [ -n "$AWS_S3_OBJECT" ] ; then
    echo Copying application archive..
    aws s3 cp $AWS_S3_OBJECT app.zip
    echo Extracting to web server directory..
    unzip app.zip -d /var/app/current
  fi

  cd /var/app/current

  if [ -f .docker/${APP_ENVIRONMENT}/bootstrap.sh ] ; then
    source .docker/${APP_ENVIRONMENT}/bootstrap.sh
  fi

  touch /tmp/supervisord-nginx.log
fi

exec /usr/sbin/nginx