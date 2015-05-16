# HHVM (3.7.0 / ""), Nginx, New Relic on Ubuntu 15.04
# DO NOT USE IN PRODUCTION - this is an experiment more than anything so far...
# Some ideas forked from Joostvanderlaan/dockerfiles and nikolaplejic/docker.hhvm on github.com mixing in some new relic

FROM ubuntu:15.04

# Tweet me on http://twitter.com/ckortekaas if you're a twit like me
MAINTAINER Christiaan Kortekaas <mrangryfish@gmail.com>

# Set correct environment variables.
ENV HOME /root

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
#RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
#ENTRYPOINT ["/sbin/my_init"]


#RUN echo "deb http://archive.ubuntu.com/ubuntu vivid main universe" > /etc/apt/sources.list
RUN echo "deb http://mirror.optus.net/ubuntu/ vivid main universe" > /etc/apt/sources.list
#RUN echo "deb http://mirror.aarnet.edu.au/ubuntu/ vivid main universe" > /etc/apt/sources.list
RUN apt-get update -y

# Otherwise you cannot add repositories
RUN apt-get install -y software-properties-common wget nano git

# Add HHVM repository
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449
RUN add-apt-repository 'deb http://dl.hhvm.com/ubuntu vivid main'

# Add New Relic HHVM Extension and compile
RUN cd /usr/local/src; wget http://download.newrelic.com/agent_sdk/nr_agent_sdk-v0.16.1.0-beta.x86_64.tar.gz
RUN cd /usr/local/src; tar xvzf /usr/local/src/nr_agent_sdk-v0.16.1.0-beta.x86_64.tar.gz
RUN cp /usr/local/src/nr_agent_sdk-v0.16.1.0-beta.x86_64/lib/* /usr/local/lib/
RUN cp /usr/local/src/nr_agent_sdk-v0.16.1.0-beta.x86_64/include/* /usr/local/include/

# add nginx repository
RUN add-apt-repository -y ppa:nginx/stable

# Run after setting repositories
RUN apt-get update -y

# Basic Requirements - Installing Nginx before HHVM allowed HHVM to detect Nginx and create the /etc/nginx/hhvm.conf file for you.
RUN apt-get -y install nginx python-setuptools curl unzip

RUN apt-get install -y aptitude
RUN aptitude install -y -f hhvm-dev hhvm

# Clone the hhvm newrelic extension (non-official) which uses the agent sdk
RUN git clone https://github.com/ckortekaas/hhvm-newrelic-ext.git /usr/local/src/hhvm-newrelic-ext
#RUN git clone https://github.com/chregu/hhvm-newrelic-ext.git /usr/local/src/hhvm-newrelic-ext
RUN cd  /usr/local/src/hhvm-newrelic-ext && hphpize && cmake . && make && make install

#ADD ./hhvm.conf /etc/nginx/hhvm.conf

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
#RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# create a directory with a sample index.php file
RUN mkdir -p /mnt/hhvm/public
RUN chown -R www-data:www-data /mnt/hhvm/public

# echo something for testing purposes, with hiphop it will only show text: Hiphop
RUN echo "<?php echo 'hello world'; ?>" > /mnt/hhvm/public/index.php

# For newer NGINX
ADD ./nginx-site.conf /etc/nginx/sites-enabled/default
#ADD ./supervisord.conf /etc/supervisord.conf
ADD ./config.hdf /mnt/hhvm/config.hdf

# Clean up APT when done.
#RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Testing/debug tools - enable when developing/testing the container build
#apt-get -y install mlocate lynx; updatedb

# private expose
EXPOSE 80