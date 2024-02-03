#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2016 blueyi <blueyi@ubuntu>
#
# Distributed under terms of the MIT license.

"""
Execute script from common to initial linux system
"""

import sys
sys.path.append('common')
from common import *

if os.geteuid == 0:
    print('Do Not Run As Root!!!')
    sys.exit(1)

call_cmd('sudo python3 common/installPack.py')
call_cmd('python3 common/createSoftLink.py')
call_cmd('python3 common/misc.py')
# call_cmd('python common/vimPlugin.py -ycm')


