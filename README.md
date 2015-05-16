Overview
========
HHVM (3.7.0), Nginx, New Relic on Ubuntu 15.04 "Vivid"

Some ideas forked from Joostvanderlaan/dockerfiles and nikolaplejic/docker.hhvm on github.com mixing in some new relic using the @chregu hhvm extension build example

Status
======
This docker container is an experiment and will be refined.  Feel free to send me pull requests or code comments on github of course.


Configuration
=============
Run the container with dir and config.hdf in /mnt/hhvm. Replace the NEWRELIC_LICENSE_KEY and NEWRELIC_APP_NAME with your own first.

If you want to run something more interesting than 'hello world', mount the /mnt/hhvm dir with php content in /mnt/hhvm/public.

If you want to setup your own nginx config, you can mount that too with -v to /etc/nginx/sites-enabled eg:

```
docker run -t ckortekaas/hhvm-nginx-newrelic -v /path/to/the/host/machine/php-app-directory:/mnt/hhvm:ro -v /path/to/the/host/machine/nginx-sites-enabled-directory:/etc/nginx/sites-enabled:ro
```
