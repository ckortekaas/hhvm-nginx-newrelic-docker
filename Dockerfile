# HHVM (3.1.0 / "Kanye West"), Nginx, New Relic on Ubuntu 14.04 Trusty via Phusion cleaned Ubuntu
# DO NOT USE IN PRODUCTION - this is an experiment more than anything so far...
# Some ideas forked from Joostvanderlaan/dockerfiles and nikolaplejic/docker.hhvm on github.com mixing in some Phusion Ubuntu 14.04 and new relic
# Disabled supervisord stuff for now to see if its really necessary on Phusion

# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
# Using 0.9.11 when Ubuntu 14.04 became base and docker-bash was added
FROM phusion/baseimage:0.9.11

# Tweet me on http://twitter.com/ckortekaas if you're a twit like me
MAINTAINER Christiaan Kortekaas <mrangryfish@gmail.com>

# Set correct environment variables.
ENV HOME /root

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
#RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
ENTRYPOINT ["/sbin/my_init"]


RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
#RUN echo "deb http://mirror.optus.net/ubuntu/ trusty main universe" > /etc/apt/sources.list
#RUN echo "deb http://mirror.aarnet.edu.au/ubuntu/ trusty main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get -y upgrade

# Keep upstart from complaining
#RUN dpkg-divert --local --rename --add /sbin/initctl
#RUN ln -sf /bin/true /sbin/initctl

# Otherwise you cannot add repositories
RUN apt-get install -y software-properties-common wget nano

# Add HHVM repository
RUN wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add -
RUN echo deb http://dl.hhvm.com/ubuntu trusty main | sudo tee /etc/apt/sources.list.d/hhvm.list
# for ubuntu 14.04
#RUN add-apt-repository -y ppa:mapnik/boost

# Add New Relic HHVM Extension and compile
RUN cd /usr/local/src; wget http://download.newrelic.com/agent_sdk/nr_agent_sdk-v0.8.0.0-beta.x86_64.tar.gz
RUN cd /usr/local/src; tar xvzf /usr/local/src/nr_agent_sdk-v0.8.0.0-beta.x86_64.tar.gz
# Even though the version is 0.8, the dir is 0.7.2 o_0 @ new relic
RUN cp /usr/local/src/nr_agent_sdk-v0.7.2.0-beta.x86_64/lib/* /usr/local/lib/
RUN cp /usr/local/src/nr_agent_sdk-v0.7.2.0-beta.x86_64/include/* /usr/local/include/

# Get all the compiler pre-reqs
RUN apt-get install -y --force-yes autoconf automake binutils-dev build-essential cmake git g++ \
  libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-regex-dev \
  libboost-system-dev libboost-thread-dev libbz2-dev libc-client-dev libssl-dev/trusty libldap2-dev \
  libc-client2007e-dev libcap-dev libcurl4-openssl-dev libdwarf-dev libelf-dev \
  libexpat-dev libgd2-xpm-dev libgoogle-glog-dev libgoogle-perftools-dev libicu-dev \
  libjemalloc-dev libmcrypt-dev libmemcached-dev libmysqlclient-dev libncurses-dev \
  libonig-dev libpcre3-dev libreadline-dev libtbb-dev libtool libxml2-dev zlib1g-dev \
  libevent-dev libmagickwand-dev libinotifytools0-dev libiconv-hook-dev libedit-dev \
  libiberty-dev libxslt1-dev ocaml-native-compilers librtmp-dev libmagickcore-dev libgnutls-dev/trusty librsvg2-dev/trusty \
  php5-imagick gir1.2-rsvg-2.0 gir1.2-freedesktop/trusty

# add nginx repository
RUN add-apt-repository -y ppa:nginx/stable

# Run after setting repositories
RUN apt-get update -y

# Basic Requirements - Installing Nginx before HHVM allowed HHVM to detect Nginx and create the /etc/nginx/hhvm.conf file for you.
RUN apt-get -y install nginx python-setuptools curl unzip

# Clone hhvm and switch to release 3.1 to get the hphpize tool needed for new relic hhvm ext
RUN cd /usr/local/src
RUN git clone https://github.com/facebook/hhvm.git /usr/local/src/hhvm
# Or for debug/dev use github ssh which is 3x faster speed, but you need the ssh keys setup
#RUN git clone git@github.com:facebook/hhvm.git
RUN cd /usr/local/src/hhvm; git checkout -b HHVM-3.1.0; rm -r third-party; git submodule update --init --recursive
RUN cd /usr/local/src/hhvm; cmake .
RUN cd /usr/local/src/hhvm; make; make install

RUN mv /usr/local/lib/libnewrelic*.so /usr/lib/
RUN mv /usr/local/include/newrelic*.h /usr/include/

# Clone the hhvm newrelic extension (non-official) which uses the agent sdk
RUN git clone https://github.com/chregu/hhvm-newrelic-ext.git /usr/local/src/hhvm-newrelic-ext
#RUN git clone git@github.com:chregu/hhvm-newrelic-ext
RUN cd  /usr/local/src/hhvm-newrelic-ext; hphpize; cmake .; make

#Now that we've built the new relic extension using the full hhvm, we can remove it and install the apt package for it instead
RUN cd  /usr/local/src/hhvm; xargs rm < install_manifest.txt
RUN apt-get update -y; apt-get install hhvm

RUN export HPHP_HOME=/usr/share/hhvm-profile/

RUN chmod +x /usr/share/hhvm/install_fastcgi.sh
RUN /usr/share/hhvm/install_fastcgi.sh

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# create a directory with a sample index.php file
RUN mkdir -p /mnt/hhvm
RUN chown -R www-data:www-data /mnt/hhvm

# echo something for testing purposes, with hiphop it will only show text: Hiphop
RUN echo "<?php echo 'hello world'; ?>" > /mnt/hhvm/index.php

# For newer NGINX
ADD ./nginx-site.conf /etc/nginx/sites-enabled/default
#ADD ./supervisord.conf /etc/supervisord.conf
ADD ./config.hdf /mnt/hhvm/config.hdf

RUN mkdir /etc/service/hhvm
ADD hhvm.sh /etc/service/hhvm/run
RUN chmod +x /etc/service/hhvm/run

RUN mkdir /etc/service/nginx
ADD nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

# Clean up APT when done.
#RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# private expose
EXPOSE 80