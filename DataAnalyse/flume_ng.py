__author__ = 'xiaoyu'

import os
import re
import tempfile
import shutil
import sys

class RunConfig(object):

    def __init__(self, file_config):
        self.file_config = file_config

    def replace_file_content(self):
        file=tempfile.TemporaryFile()
        print "tempfile name is", "=>", file

        old_file = '/tmp/pom.xml'
        if os.path.exists(old_file):
            fopen = open(old_file, 'r')
        else:
            print "file %s not found" % old_file
            sys.exit()

        pattern = re.compile(r'''
        <hadoop.version>2.2.0</hadoop.version>
        <hbase.version>0.96.0-hadoop2</hbase.version>
        <hadoop.common.artifact.id>hadoop-common</hadoop.common.artifact.id>
        <thrift.version>0.8.0</thrift.version>''', re.IGNORECASE | re.MULTILINE)
        new_content, count = re.subn(pattern, '''
        <!--
        <hadoop.version>2.2.1</hadoop.version>
        <hbase.version>0.96.1-hadoop2</hbase.version>
        <hadoop.common.artifact.id>hadoop-common</hadoop.common.artifact.id>
        <thrift.version>0.7.0</thrift.version>
        -->
        ''', fopen.read())
        file.write(new_content)
        fopen.close()
        file.seek(0)

        tmp_file = file.read()
        print tmp_file
        file.close()
        exit()

        if os.path.exists(old_file):
            os.remove(old_file)
        writefile = open(old_file, 'w')
        writefile.write(tmp_file)

run_config = RunConfig('pom.xml')
run_config.replace_file_content()