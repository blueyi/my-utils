#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2016 blueyi <blueyi@blueyi-ubuntu>
#
# Distributed under terms of the MIT license.

"""
Create soft link from file
"""

from common import *

welcomePrint('Create soft link from file')

link_file = curPath() + '/link.ini'

error_log_file = errLogFileName(__file__)
error_log = open(error_log_file, 'w')

# batch link some config file
def config_link(file_path):
    link_dict = {}
    with open(file_path, 'r') as text:
        for tline in text:
            if len(tline.strip()) != 0 and tline[0] != '#' and ('home' in tline or '~/' in tline):
                tline = tline.replace('~', userPath())
                tlink = tline.strip().split('#')[0].split()
                if len(tlink) > 1:
                    link_dict[tlink[0]] = tlink[1]
    for key, value in link_dict.items():
        if os.path.isfile(value):
            run_cmd('mv ' + value + ' ' + value + '_' + curTimeStr() + '.bak', error_log)
        print(value + ' -> ' + os.path.abspath(curPath() + '/../' + key))
        run_cmd(link_cmd(os.path.abspath(curPath() + '/../' + key), value), error_log)


config_link(link_file)

error_log.close()
if delBlankFile(error_log_file):
    welcomePrint('Create link success!')
else:
    welcomePrint('Some soft link be created failed!')
