# HHVM (3.1.0 / "Kanye West"), Nginx, New Relic on Ubuntu 14.04 Trusty via Phusion cleaned Ubuntu
# DO NOT USE IN PRODUCTION - this is an experiment more than anything so far...
# Some ideas forked from Joostvanderlaan/dockerfiles and nikolaplejic/docker.hhvm on github.com mixing in some Phusion Ubuntu 14.04 and new relic
# Disabled supervisord stuff for now to see if its really necessary on Phusion

# Tweet me on http://twitter.com/ckortekaas if you're a twit like me
MAINTAINER Christiaan Kortekaas <mrangryfish@gmail.com>

# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
# Using 0.9.10 when Ubuntu 14.04 became base
FROM phusion/baseimage:0.9.10

# Set correct environment variables.
ENV HOME /root

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
ENTRYPOINT ["/sbin/my_init"]


#RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN echo "deb http://mirror.optus.net/ubuntu/ trusty main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get -y upgrade

# Keep upstart from complaining
#RUN dpkg-divert --local --rename --add /sbin/initctl
#RUN ln -sf /bin/true /sbin/initctl

# Otherwise you cannot add repositories
RUN apt-get install -y software-properties-common python-software-properties wget nano

# Add HHVM repository
RUN wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add -
RUN echo deb http://dl.hhvm.com/ubuntu trusty main | sudo tee /etc/apt/sources.list.d/hhvm.list
# for ubuntu 14.04
#RUN add-apt-repository -y ppa:mapnik/boost

# Add New Relic HHVM Extension and compile
RUN cd /usr/local/src
RUN wget http://download.newrelic.com/agent_sdk/nr_agent_sdk-v0.7.2.0-beta.x86_64.tar.gz
RUN tar xvzf nr_agent_sdk-v0.7.2.0-beta.x86_64.tar.gz
RUN cp nr_agent_sdk-v0.7.2.0-beta.x86_64/lib/* /usr/local/lib/
RUN cp nr_agent_sdk-v0.7.2.0-beta.x86_64/include/* /usr/local/include/

# Get all the compiler pre-reqs
RUN apt-get install -y --force-yes autoconf automake binutils-dev build-essential cmake git g++ \
  libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-regex-dev \
  libboost-system-dev libboost-thread-dev libbz2-dev libc-client-dev libssl-dev/trusty libldap2-dev \
  libc-client2007e-dev libcap-dev libcurl4-openssl-dev libdwarf-dev libelf-dev \
  libexpat-dev libgd2-xpm-dev libgoogle-glog-dev libgoogle-perftools-dev libicu-dev \
  libjemalloc-dev libmcrypt-dev libmemcached-dev libmysqlclient-dev libncurses-dev \
  libonig-dev libpcre3-dev libreadline-dev libtbb-dev libtool libxml2-dev zlib1g-dev \
  libevent-dev libmagickwand-dev libinotifytools0-dev libiconv-hook-dev libedit-dev \
  libiberty-dev libxslt1-dev ocaml-native-compilers \
  php5-imagick

# Clone hhvm and switch to release 3.1 to get the hphpize tool needed for new relic hhvm ext
RUN git clone https://github.com/facebook/hhvm.git
# Or for debug/dev use github ssh which is 3x faster speed, but you need the ssh keys setup
#RUN git clone git@github.com:facebook/hhvm.git
RUN cd hhvm
RUN git checkout -b HHVM-3.1.0
RUN rm -r third-party
RUN git submodule update --init --recursive
RUN cmake .
# make, and make install - we're just doing this for the hphpize which doesn't come in the apt package sadly so src is required
RUN make
RUN make install

# Clone the hhvm newrelic extension (non-official) which uses the agent sdk
RUN cd /usr/local/src
RUN git clone git@github.com:chregu/hhvm-newrelic-ext
RUN cd hhvm-newrelic-ext
RUN hphpize
RUN cmake .
RUN make


RUN export HPHP_HOME=/usr/share/hhvm-profile/

# add nginx repository
RUN add-apt-repository -y ppa:nginx/stable

# Run after setting repositories
RUN apt-get update -y

# Basic Requirements - Installing Nginx before HHVM allowed HHVM to detect Nginx and create the /etc/nginx/hhvm.conf file for you.
RUN apt-get -y install nginx hhvm python-setuptools curl git unzip

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

RUN mkdir /etc/service/nginx
ADD nginx.sh /etc/service/nginx/run

RUN mkdir /var/www
RUN chown -R www-data:www-data /var/www


# create a directory with a sample index.php file
RUN sudo mkdir -p /mnt/hhvm

# echo something for testing purposes, with hiphop it will only show text: Hiphop
RUN echo "<?php echo 'hello world'; ?>" > /mnt/hhvm/index.php

# For newer NGINX
ADD ./nginx-site.conf /etc/nginx/sites-enabled/default
#ADD ./supervisord.conf /etc/supervisord.conf
ADD ./config.hdf /mnt/hhvm/config.hdf

#Replace the licence key with the passed in env variable
RUN sed -i "s/ NEWRELIC_LICENSE_KEY = REPLACE_ME/ NEWRELIC_LICENSE_KEY = $NEWRELIC_KEY/g" /mnt/hhvm/config.hdf



RUN sudo /usr/share/hhvm/install_fastcgi.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# private expose
EXPOSE 80