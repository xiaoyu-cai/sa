#!/usr/bin/env bash

function config_epel()
{
    [ -f /etc/yum.repos.d/epel.repo ] && epel_exist=1 || epel_exist=0
    if [ $epel_exist = 1 ]; then
        echo "epel exist"
        exit
    fi
    wget 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm'
    rpm -ivh epel-release-latest-6.noarch.rpm
    sed -i 's/#baseurl=http:\/\/download.fedoraproject.org\/pub\/epel\/6\/$basearch/baseurl=http:\/\/download.fedoraproject.org\/pub\/epel\/6\/$basearch/g' /etc/yum.repos.d/epel.repo
    sed -i 's/mirrorlist=https:\/\/mirrors.fedoraproject.org\/metalink?repo=epel-6&arch=$basearch/#mirrorlist=https:\/\/mirrors.fedoraproject.org\/metalink?repo=epel-6&arch=$basearch/g' /etc/yum.repos.d/epel.repo
}

