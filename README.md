Overview
========
HHVM (3.1.0 / "Kanye West"), Nginx, New Relic on Ubuntu 14.04 Trusty via Phusion cleaned Ubuntu

DO NOT USE IN PRODUCTION - this is an experiment more than anything so far...

Some ideas forked from Joostvanderlaan/dockerfiles and nikolaplejic/docker.hhvm on github.com mixing in some Phusion Ubuntu 14.04 and new relic

Disabled supervisord stuff for now to see if its really necessary on Phusion.

Status
======
This docker is in early alpha testing. It's not 'done' yet. Feel free to send me pull requests or code comments on github of course.


Configuration
=============
Run the container with the new relic licence key passed as an environment variable eg

```docker run -i -t -e NEWRELIC_KEY=YOUR_KEY_HERE ckortekaas/hhvm-nginx-newrelic 
```
