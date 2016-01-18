__author__ = 'xiaoyu'
# -*- coding: utf-8 -*-
#coding=utf-8

import os


def file_walkdir():
    s = os.sep
    root = "/tmp" + s + "" + s
    for rt, dirs, files in os.walk(root):
        for f in files:
            pname = os.path.split(os.path.join(rt,f))
            fname = os.path.splitext(f)
            print pname,fname


def file_listdir():
    s = os.sep
    root = "/tmp" + s + "" + s
    for i in os.listdir(root):
        if os.path.isfile(os.path.join(root, i)):
            print i

if __name__ == '__main__':
    file_listdir()
    file_walkdir()