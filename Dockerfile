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
ADD 0.6.3_linux_amd64.zip /tmp/serf.zip

ENV DEBIAN_FRONTEND noninteractive

# === Locale ===
RUN locale-gen  en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN apt-get update
RUN apt-get install -y dnsmasq unzip curl libterm-readline-gnu-perl vim-nox openssh-server

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

EXPOSE 7373 7946 22

RUN apt-get clean
#CMD /etc/serf/start-serf-agent.sh
CMD /bin/bash
