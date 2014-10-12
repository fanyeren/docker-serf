# Creates a base ubuntu image with serf and dnsmasq
#
# it aims to create a dynamic cluster of docker containers
# each able to refer other by fully qulified domainnames
#
# this isn't trivial as docker has readonly /etc/hosts
#
# The docker images was directly taken from sequenceiq and converetd to ubuntu image
# because I wanted to create the cluster on ubuntu.

FROM ubuntu:saucy
MAINTAINER xiahoufeng

RUN mkdir /root/.ssh
RUN echo "root:test123456" | chpasswd
RUN echo "ssh-dss AAAAB3NzaC1kc3MAAACBAMaoqeNdzAvgcr6yZukMjNAwg8CatRvlHNqDp3TBW1qZY67b6aAW0td2z5WE/v5DoPO2Ulv9QEUzzGERsVs0OTM53vRzNWZ8iRDQiQbxmogG13kpKYTnw4y7y7LP8kH2EV+QXYOOkWLntXfmQZoozN8CXEz+u/1U8DPTWHeGczJfAAAAFQCvaW+m+e9oCcN8guSJNFC5tFWOqwAAAIA9Si/6BiW+b1wJpaK7YIg1X0DkxdOI/vAy0w1hap1ckm52EbcKjQUSkR+pHrkAeTq2La6/qSGAuQKR6pd5Fhy4eOcDK0IM2j0Aysss/7lKW/NHF68VMLMJyzBG2W2u77RJXiqCfo2V6kMS3fwJUb2iDwXVCnK03uPIGl5fzgoK6gAAAIEAmwwMdJKeJn4sYuKaEO/0cqTILcQkY57K6hZrFkxPZ74YbNujryN3XWUn7kpmN0pPATI4L8FTCmeupxmFKYWw3TiWySU3LB7pZReNkukXt7p1ImEwUVTHvk86lGxDTjQfn/AroZTrYt3UbpTUu0T6PYWc4XchsDUReIe3FAnYrCk= root@centos6-dev00.baidu.com" >> /root/.ssh/authorized_keys


ADD apt.conf /etc/apt/apt.conf
ADD proxy /etc/profile.d/proxy
ADD 0.6.3_linux_amd64.zip /tmp/serf.zip

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

EXPOSE 7373 7946 2222

CMD /etc/serf/start-serf-agent.sh
