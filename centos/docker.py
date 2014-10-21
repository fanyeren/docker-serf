import docker

c = docker.Client(base_url='tcp://10.81.23.22:2375',version='1.14',timeout=10)
c.create_container(image="yorko/webserver:v1",stdin_open=True,tty=True,command="/usr/bin/supervisord -c /etc/supervisord.conf",volumes=['/data'],ports=[80,22],name="webserver11")

print str(r)

c = docker.Client(base_url='tcp://10.81.23.22:2375',version='1.14',timeout=10)
r=c.start(container='webserver11', binds={'/data':{'bind': '/data','ro': False}}, port_bindings={80:80,22:2022}, lxc_conf=None, publish_all_ports=True, links=None, privileged=False, dns=None, dns_search=None, volumes_from=None, network_mode=None, restart_policy=None, cap_add=None, cap_drop=None)

print str(r)
