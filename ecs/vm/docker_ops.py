__author__ = 'xiaoyu'
# -*- coding: utf-8 -*-
#coding=utf-8

import docker


def docker_create():
    c = docker.Client(base_url='tcp://192.168.1.22:2375', version='1.14', timeout=10)
    r=c.create_container(image="yorko/webserver:v1", stdin_open=True, tty=True,
                   command="/usr/bin/supervisord -c /etc/supervisord.conf", volumes=['/data'], ports=[80, 22],
                   name="webserver11")
# 通过create_container方法创建容器，指定"yorko/webserver:v1"镜像名称，使用supervisord接管进程服务，挂载主宿机/data作为数据卷，容器监听80与22端口，容器的名称为webserver11
    print str(r)

def docker_start():
    c = docker.Client(base_url='tcp://192.168.1.22:2375',version='1.14',timeout=10)
    r=c.start(container='webserver11', binds={'/data':{'bind': '/data','ro': False}}, port_bindings={80:80,22:2022}, lxc_conf=None,
              publish_all_ports=True, links=None, privileged=False,
              dns=None, dns_search=None, volumes_from=None, network_mode=None,
              restart_policy=None, cap_add=None, cap_drop=None)
#通过start方法启动容器，指定数据卷的挂载关系及权限，以及端口与主宿机的映射关系等
    print str(r)