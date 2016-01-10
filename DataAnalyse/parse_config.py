import tempfile
import os
import sys
import re


class ParseConfig(object):

    def __init__(self):
        pass

    def parse_config(self):
        file=tempfile.TemporaryFile()
        print "tempfile name is", "=>", file

        old_file = 'slow.log'
        if os.path.exists(old_file):
            fopen1 = open(old_file, 'r')
        else:
            print "file %s not found" % old_file
            sys.exit()
        text = fopen1.read()
        print text
#         pattern = re.compile(r'''
# # Query_time:\s+(.*)\s+Lock_time:\s+(.*)\s+Rows_sent:\s+(.*)\s+Rows_examined:\s+(.*)
# SET timestamp=(.*);
# ([\s\S]*?)
# # User@Host: (.*)
# ''', re.IGNORECASE | re.MULTILINE)
        pattern = re.compile(r'''# Query_time:\s+(.*)\s+Lock_time:\s+(.*)\s+Rows_sent:\s+(.*)\s+Rows_examined:\s+(.*)
SET timestamp=(.*);
([\s\S]*?)
# User@Host: ecstore\[ecstore\] @  \[(.*)\]  Id:\s+(\d+)''', re.IGNORECASE | re.MULTILINE)
        matchs = re.findall(pattern, text)
        for match in matchs:
            print match[0], match[1], match[2], match[3]
            print match[5]

if __name__ == '__main__':
    pc = ParseConfig()
    pc.parse_config()