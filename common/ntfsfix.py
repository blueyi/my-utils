#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2017 blueyi <blueyi@blueyi-mint>
#
# Distributed under terms of the MIT license.

"""
call ntfsfix to fix ntfs partion
"""

from common import runAsRoot, call_cmd, welcomePrint

runAsRoot()

sd_list = ['sda5', 'sda6', 'sda7']

for dev in sd_list:
    fix_cmd = 'sudo ntfsfix /dev/' + dev
    call_cmd(fix_cmd)

welcomePrint(str(sd_list))
