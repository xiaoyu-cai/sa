# -*- coding: utf-8 -*-

# Scrapy settings for TTJJ project
#
# For simplicity, this file contains only the most important settings by
# default. All the other settings are documented here:
#
#     http://doc.scrapy.org/en/latest/topics/settings.html
#

BOT_NAME = 'TTJJ'

SPIDER_MODULES = ['TTJJ.spiders']
NEWSPIDER_MODULE = 'TTJJ.spiders'
download_delay=1
ITEM_PIPELINES={'TTJJ.pipelines.TtjjPipeline':300}
COOKIES_ENABLED=False
# Crawl responsibly by identifying yourself (and your website) on the user-agent
#USER_AGENT = 'TTJJ (+http://www.yourdomain.com)'
#取消默认的useragent,使用新的useragent
DOWNLOADER_MIDDLEWARES = {
        'scrapy.contrib.downloadermiddleware.useragent.UserAgentMiddleware' : None,
        'TTJJ.spiders.UserAgentMiddle.UserAgentMiddle':400
    }