__author__ = 'xiaoyu'
# -*- coding: utf-8 -*-
import urllib2
import urllib
import StringIO
import gzip


class myhttp(object):
    def __init__(self):
        '''
        '''

    #发普通的Post请求   ，可模拟浏览器，可一定程度防止被spam
    def http_post(self,_url,_params,_headers):
        request = urllib2.Request(
                              url = _url,
                              data = urllib.urlencode(_params),
                              headers=_headers
                              )
        response = urllib2.urlopen(request)
        if response.info().get('Content-Encoding') == 'gzip':
            buf = StringIO.StringIO(response.read())
            f = gzip.GzipFile(fileobj=buf)
            data = f.read()
        else:
            data = response.read()
        return data

    #发普通的get请求
    def http_get(self,_url):
        req = urllib2.Request(url=_url,)
        response = urllib2.urlopen(req)
        if response.info().get('Content-Encoding') == 'gzip':
            buf = StringIO.StringIO(response.read())
            f = gzip.GzipFile(fileobj=buf)
            data = f.read()
        else:
            data = response.read()
        return data
    #获取headers内容，模拟浏览器,主要是防止产品对于前段接口referer和host过滤的安全阻止
    def get_headers_(self,host,referer,content_type,Accept):
        headers = {
               "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
               "Referer": referer,
               "Accept-Language": "zh-CN,zh;q=0.8",
               "Content-Type": content_type,
               "Accept-Encoding": "gzip,deflate,sdch",
               "User-Agent": "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.94 Safari/537.36",
               "Host": host,
               "Connection": "Keep-Alive",
               "Cache-Control": "no-cache"
                }
        return headers


if __name__ == '__main__':
    mh = myhttp()
    data = mh.http_get('http://www.baidu.com')
    print(data)