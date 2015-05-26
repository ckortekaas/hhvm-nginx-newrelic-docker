# HHVM (3.7.0 / ""), Nginx, New Relic on Ubuntu 15.04
# DO NOT USE IN PRODUCTION - this is an experiment more than anything so far...
# Some ideas forked from Joostvanderlaan/dockerfiles and nikolaplejic/docker.hhvm on github.com mixing in some new relic

FROM ubuntu:15.04

# Tweet me on http://twitter.com/ckortekaas if you're a twit like me
MAINTAINER Christiaan Kortekaas <mrangryfish@gmail.com>

# Set correct environment variables.
ENV HOME /root

#Development/tweaking helpers
#RUN echo "deb http://archive.ubuntu.com/ubuntu vivid main universe" > /etc/apt/sources.list
#RUN echo "deb http://mirror.aarnet.edu.au/ubuntu/ vivid main universe" > /etc/apt/sources.list
#apt-get install -y nano
#RUN git clone https://github.com/chregu/hhvm-newrelic-ext.git /usr/local/src/hhvm-newrelic-ext
#RUN echo "daemon off;" >> /etc/nginx/nginx.conf
# Testing/debug tools - enable when developing/testing the container build
#RUN apt-get -y install vim mlocate lynx; updatedb


# Add New Relic HHVM Extension and compile
# Basic Requirements - Installing Nginx before HHVM allowed HHVM to detect Nginx and create the /etc/nginx/hhvm.conf file for you.
# Clone the hhvm newrelic extension (non-official) which uses the agent sdk
# nginx config
# create a directory with a sample index.php file
# echo something for testing purposes, with hiphop it will only show text: Hiphop
# Clean up APT when done.

RUN echo "deb http://mirror.optus.net/ubuntu/ vivid main universe" > /etc/apt/sources.list && \
  apt-get update -y && \
  apt-get install -y software-properties-common wget git aptitude supervisor && \
  apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449 && \
  add-apt-repository -y 'deb http://dl.hhvm.com/ubuntu vivid main' && \
  add-apt-repository -y ppa:nginx/stable && \
  apt-get update -y && \
  cd /usr/local/src; wget http://download.newrelic.com/agent_sdk/nr_agent_sdk-v0.16.1.0-beta.x86_64.tar.gz && \
  cd /usr/local/src; tar xvzf /usr/local/src/nr_agent_sdk-v0.16.1.0-beta.x86_64.tar.gz && \
  cp /usr/local/src/nr_agent_sdk-v0.16.1.0-beta.x86_64/lib/* /usr/local/lib/ && \
  cp /usr/local/src/nr_agent_sdk-v0.16.1.0-beta.x86_64/include/* /usr/local/include/ && \
  apt-get -y install nginx python-setuptools curl unzip && \
  aptitude install -y -f hhvm-dev hhvm && \
  git clone https://github.com/chregu/hhvm-newrelic-ext.git /usr/local/src/hhvm-newrelic-ext && \
  cd  /usr/local/src/hhvm-newrelic-ext && hphpize && cmake . && make && make install && \
  sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
  sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
  mkdir -p /var/app/current/public && \
  chown -R www-data:www-data /var/app/current/public && \
  echo "<?php echo 'hello world'; ?>" > /var/app/current/public/index.php && \
  apt-get purge -y wget git hhvm-dev aptitude && \
  apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  rm -rf /usr/local/src/nr_agent_sdk-v0.16.1.0-beta.x86_64

# For newer NGINX
COPY /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY /etc/nginx/conf.d/* /etc/nginx/conf.d/
COPY /opt/hhvm/config.hdf /opt/hhvm/config.hdf

COPY opt/* /opt/
RUN chmod +x /opt/hhvm.sh && chmod +x /opt/nginx.sh && chmod +x /opt/newrelic.sh

COPY etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

#TODO: add papertrail support and doco

# private expose
EXPOSE 80