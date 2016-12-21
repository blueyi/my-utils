#! /usr/bin/env python
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

call_cmd('sudo python common/installPack.py')
call_cmd('python common/createSoftLink.py')
call_cmd('python common/misc.py')
call_cmd('python common/vimPlugin.py')


