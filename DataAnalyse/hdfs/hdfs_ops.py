# -*- coding: utf-8 -*-
import subprocess
import sys
import datetime

def hdfs_putfile():
    webid="web1"
    currdate=datetime.datetime.now().strftime('%Y%m%d')
    logspath="./access.log"
    logname="access.log."+webid
    try:
        subprocess.Popen(["/usr/local/hadoop/bin/hdfs", "dfs", "-mkdir", "hdfs://vm:8020/user/root/website.com/"+currdate], stdout=subprocess.PIPE)
    except Exception,e:
       pass
    putinfo=subprocess.Popen(["/usr/local/hadoop/bin/hdfs", "dfs", "-put", logspath, "hdfs://vm:8020/user/root/website.com/"+currdate+"/"+logname], stdout=subprocess.PIPE)
    for line in putinfo.stdout:
        print line

