__author__ = 'xiaoyu'
# -*- coding: utf-8 -*-
#coding=utf-8

import csv
import sys


def csv_reader(filename):
    with open(filename, 'rb') as f:
        reader = csv.reader(f)
        try:
            for row in reader:
                print ','.join(row).decode('gb2312', 'ignore')
        except csv.Error as e:
            sys.exit('file %s, line %d: %s' % (filename, reader.line_num, e))


def csv_dictreader(filename):
    with open(filename, 'rb') as f:
        reader = csv.DictReader(f)
        try:
            for row in reader:
                col1 = row['类型'.decode('utf-8').encode('gb2312')]
                col2 = row['短信内容'.decode('utf-8').encode('gb2312')]
                print str(col1).decode('gb2312', 'ignore')
                print str(col2).decode('gb2312', 'ignore')
        except csv.Error as e:
            sys.exit('file %s, line %d: %s' % (filename, reader.line_num, e))


def csv_writer():
    with open('names.csv', 'w') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['患者编号'.decode('utf-8').encode('gb2312'), '疾病'.decode('utf-8').encode('gb2312')])


def csv_dictwriter():
    with open('names.csv', 'w') as csvfile:
        fieldnames = ['first_name', '第二个'.decode('utf-8').encode('gb2312')]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerow({'first_name': "测试".decode('utf-8').encode('gb2312'), '第二个'.decode('utf-8').encode('gb2312'): 'Spam'})

if __name__ == '__main__':
    filename1 = '/Users/xiaoyu/Downloads/360手机助手导出的短信.csv'
    #csv_reader(filename1)
    csv_dictreader(filename1)
    #csv_writer()
    #csv_dictwriter()