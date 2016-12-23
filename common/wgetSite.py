#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2016  <@BLUEYI-PC>
#
# Distributed under terms of the MIT license.

from common import *

"""
make a mirror site from url
wget --no-check-certificate -r -p -np -k   https://developer.android.com/studio/intro/ -e use_proxy=yes -e https_proxy=127.0.0.1:1081
"""


https = True
proxy = False
proxy_site = '127.0.0.1:1081'
url_file = 'url.txt'
down_dir = '~/Downloads/cmake_tutorial'

error_log_file = errLogFileName(__file__)
error_log = open(error_log_file, 'w')

welcomePrint('Make a mirror site by wget, powered by blueyi')

wget_cmd = 'wget -r -p -np -k '

if https :
    wget_cmd = wget_cmd + ' --no-check-certificate '

if proxy :
    wget_cmd = wget_cmd + ' -e use_proxy=yes -e https_proxy=' + proxy_site + ' '

if len(down_dir) != 0 :
    wget_cmd = wget_cmd + ' -P ' + down_dir + ' '

with open(url_file, 'r') as text:
    for tline in text:
        if len(tline.strip()) != 0 and tline.strip()[0] != '#' and 'http' in tline:
            tline = tline.strip().split('#')[0]
            welcomePrint('Downloading ' + tline)
            run_cmd(wget_cmd + tline, error_log)


error_log.close()
if delBlankFile(error_log_file):
    welcomePrint('All site download success!')
else:
    welcomePrint('Some site download failed!')

