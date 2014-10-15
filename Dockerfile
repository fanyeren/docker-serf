# Creates a base ubuntu image with serf and dnsmasq
#
# it aims to create a dynamic cluster of docker containers
# each able to refer other by fully qulified domainnames
#
# this isn't trivial as docker has readonly /etc/hosts
#
# The docker images was directly taken from sequenceiq and converetd to ubuntu image
# because I wanted to create the cluster on ubuntu.

FROM ubuntu:trusty
MAINTAINER xiahoufeng

RUN echo "root:test123456" | chpasswd

ADD apt.conf /etc/apt/apt.conf
ADD proxy /etc/profile.d/proxy
ENV http_proxy http://m1-imci-dev00.m1:3128
ENV https_proxy https://m1-imci-dev00.m1:3128

ADD 0.6.3_linux_amd64.zip /tmp/serf.zip

ENV DEBIAN_FRONTEND noninteractive

# === Locale ===
RUN locale-gen  en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Add PostgreSQL's repository. It contains the most recent stable release of PostgreSQL, ``9.3``.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Update the Ubuntu and PostgreSQL repository indexes
RUN apt-get update

# === Postgresql ===
RUN apt-get -y -q install python-software-properties software-properties-common curl
RUN apt-get -y --force-yes -q install postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3

# Update template1 to enable UTF-8 and hstore
USER postgres
RUN    /etc/init.d/postgresql start && \
    psql -c "update pg_database set datistemplate=false where datname='template1';" && \
    psql -c 'drop database Template1;' && \
    psql -c "create database template1 with owner=postgres encoding='UTF-8' lc_collate='en_US.utf8' lc_ctype='en_US.utf8' template template0;" && \
    psql -c 'CREATE EXTENSION hstore;' -d template1

# Create a PostgreSQL role and db
RUN    /etc/init.d/postgresql start && \
    psql --command "CREATE ROLE jenkins LOGIN PASSWORD 'jenkins' SUPERUSER INHERIT CREATEDB NOCREATEROLE NOREPLICATION;" && \
    createdb -O jenkins jenkins_test && \
    createdb -O jenkins jenkins_production


# Adjust PostgreSQL configuration
RUN echo "local all  all  md5" > /etc/postgresql/9.3/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

USER root

# === RVM ===
#RUN curl -L https://get.rvm.io | bash -s stable
#ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#RUN /bin/bash -l -c rvm requirements
#RUN sed -i 's/builtin//' /usr/local/rvm/scripts/rvm
#RUN . /usr/local/rvm/scripts/rvm && rvm install ruby-2.0.0-p576
#RUN rvm all do gem install bundler

RUN apt-get install -y dnsmasq unzip curl libterm-readline-gnu-perl vim-tiny openssh-server perl

# dnsmasq configuration
ADD dnsmasq.conf /etc/dnsmasq.conf
ADD resolv.dnsmasq.conf /etc/resolv.dnsmasq.conf

# install serfdom.io
RUN unzip /tmp/serf.zip -d /bin

ENV SERF_CONFIG_DIR /etc/serf

# configure serf
ADD serf-config.json $SERF_CONFIG_DIR/serf-config.json

ADD event-router.sh $SERF_CONFIG_DIR/event-router.sh
RUN chmod +x  $SERF_CONFIG_DIR/event-router.sh

ADD handlers $SERF_CONFIG_DIR/handlers

ADD start-serf-agent.sh  $SERF_CONFIG_DIR/start-serf-agent.sh
RUN chmod +x  $SERF_CONFIG_DIR/start-serf-agent.sh

RUN service ssh start
RUN sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

ADD go.tar.gz /opt
ADD gowork.tar.gz /opt

ADD bashrc /root/bashrc
RUN cat /root/bashrc | tee -a /root/.bashrc
RUN rm /root/bashrc

EXPOSE 7373 7946 22

RUN apt-get clean
#CMD /etc/serf/start-serf-agent.sh
CMD /bin/bash
