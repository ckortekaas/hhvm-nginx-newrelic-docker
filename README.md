Overview
========
HHVM (3.7.1), Nginx, New Relic on Ubuntu 15.04 "Vivid"

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

The following environment variables can be used to configure the container:

    APP_ENVIRONMENT           The application environment (e.g. production, development..).
    AWS_S3_OBJECT             If set, should be an S3 location of a zip file 
                              containing the code to deploy to this instance.
    AWS_DEFAULT_REGION        The region of the S3 bucket.
    AWS_ACCESS_KEY_ID         The AWS access key ID for accessing the S3 bucket.
    AWS_SECRET_ACCESS_KEY     The AWS secret access key for accessing the S3 bucket.
    
    NEWRELIC_INSTALL_KEY      The New Relic installation key