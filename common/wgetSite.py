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
http://www.labnol.org/software/wget-command-examples/28750/
"""

proxy = False
proxy_site = '127.0.0.1:1081'
url_file = curPath() + '/url.txt'
down_dir = '~/Downloads'
exclude_directories = '/_sources'

welcomePrint('Make a mirror site by wget, powered by blueyi')

wget_cmd = 'wget --mirror --page-requisites --adjust-extension ' + \
    '--convert-links --execute robots=off --continue --no-parent ' + \
    '--exclude-directories ' + exclude_directories + ' '
# --mirror: turn on recursion to get whole site, equivalent -r -N -l inf --no-remove-listing
# --page-requisites: download all prerequisties(supporting media, css etc..)
# --adjust-extension: adds proper extension to downloaded files
# --convert-links: convert links for offline viewing
# --execute robots=off: ignore site robots.txt to force downloaded
# --wait=30: be gentle, wait between fetch requests
# --user-agent=Mozilla: fake the user Agent

if proxy :
    wget_cmd = wget_cmd + ' -e use_proxy=yes -e https_proxy=' + proxy_site + ' '

if len(down_dir) != 0 :
    wget_cmd = wget_cmd + ' -P ' + down_dir + ' '

with open(url_file, 'r') as text:
    for tline in text:
        if len(tline.strip()) != 0 and tline.strip()[0] != '#' and 'http' in tline:
            tline = tline.strip().split('#')[0]
            if 'https' == tline[0:5] :
                wget_cmd = wget_cmd + ' --no-check-certificate '
            welcomePrint('Downloading ' + tline)
            call_cmd(wget_cmd + tline)

welcomePrint('All site download success!')
