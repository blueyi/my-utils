#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2016 blueyi <blueyi@ubuntu>
#
# Distributed under terms of the MIT license.

"""
Execute command from file
"""

from common import *

misc_cmd_file = curPath() + '/' + 'misc.cmd'

error_log_file = errLogFileName(__file__)
error_log = open(error_log_file, 'w')

welcomePrint('misc.cmd')
with open(misc_cmd_file, 'r') as text:
    for tline in text:
        if len(tline.strip()) != 0 and tline[0] != '#':
            if '~/' in tline:
                tline = tline.replace('~', userPath())
            tcmd = tline.strip().split('#')[0]
            print(tcmd)
            run_cmd(tcmd, error_log)

error_log.close()
if delBlankFile(error_log_file):
    welcomePrint('misc.cmd config success!')
else:
    welcomePrint('misc.cmd config failed!')
