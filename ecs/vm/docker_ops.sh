#!/usr/bin/env bash

COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[0;33m"
COLOR_GREEN="\033[0;32m"
COLOR_RESET="\033[0m"

function docker_install()
{
    echo -e "$COLOR_GREEN about to install docker$COLOR_RESET"
    docker run -t -i -d --rm centos:latest /bin/bash
    docker inspect --format "{{ .State.Pid }}" 3cee91ac4582
    nsenter --mount --uts --ipc --net --pid --target 10290
    docker rm
    docker run -d -t -i  -P --name web -v /webapp centos:latest /bin/bash
    docker run -d -t -i --volumes-from web --name web1 centos:latest
    docker logs -f 61da5a7e026c
}

function docker_py()
{
    cd /usr/src
    wget 'https://pypi.python.org/packages/source/b/backports.ssl_match_hostname/backports.ssl_match_hostname-3.5.0.1.tar.gz'
    tar -zxvf backports.ssl_match_hostname-3.5.0.1.tar.gz
    cd backports.ssl_match_hostname-3.5.0.1
    python setup.py install
    cd ../
    wget 'https://pypi.python.org/packages/source/w/websocket-client/websocket_client-0.35.0.tar.gz'
    tar -zxvf websocket_client-0.35.0.tar.gz
    cd websocket_client-0.35.0
    python setup.py install
    cd ../
    git clone 'https://github.com/kennethreitz/requests.git'
    cd requests
    python setup.py install
    cd ../
    git clone https://github.com/docker/docker-py.git
    cd docker-py
    python setup.py install
    exec -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock -d &>> $logfile &
}
