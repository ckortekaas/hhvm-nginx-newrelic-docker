Overview
========
HHVM (3.7.0), Nginx, New Relic on Ubuntu 15.04 "Vivid"

Some ideas forked from Joostvanderlaan/dockerfiles and nikolaplejic/docker.hhvm on github.com mixing in some new relic using the @chregu hhvm extension build example

Status
======
This docker container is an experiment and will be refined.  Feel free to send me pull requests or code comments on github of course.


Configuration
=============
Run the container with dir and config.hdf in /var/app/current. Replace the NEWRELIC_LICENSE_KEY and NEWRELIC_APP_NAME with your own first.

If you want to run something more interesting than 'hello world', mount the /var/app/current dir with php content in /var/app/current/public.

If you want to setup your own nginx config, you can mount that too with -v to /etc/nginx/sites-enabled eg:

```
docker run -p 80:80 -t ckortekaas/hhvm-nginx-newrelic -v /path/to/the/host/machine/php-app-directory:/var/app/current/public :ro -v /path/to/the/host/machine/nginx-conf.d-directory:/etc/nginx/conf.d:ro
```
