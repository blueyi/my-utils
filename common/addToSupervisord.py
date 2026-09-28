#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2016 blueyi <blueyi@blueyi-ubuntu>
#
# Distributed under terms of the MIT license.

"""
Add a program to supervisord (legacy helper).

Deprecated for bootstrap: prefer systemd --user or a user-level process manager.
Writes under /etc/supervisor/conf.d/ may still need an elevated shell; this script
no longer forces root execution and defaults program user to the current account.
"""

from __future__ import print_function

import getpass
import os
import sys

from common import *

welcomePrint('Add cmd to supervisor')

cmdName = ''
cmd = ''
cmd = cmd + ' > /dev/null 2>&1 & '

if len(sys.argv) >= 3:
    cmdName = sys.argv[1]
    cmd = sys.argv[2]
elif len(cmdName) == 0 or len(cmd) == 0:
    while len(cmdName) == 0 or len(cmd) == 0:
        cmdName = raw_input('Enter the name you want to use:\n')
        cmd = raw_input('Enter your command:\n')

error_log_file = errLogFileName(__file__)
error_log = open(error_log_file, 'w')

# Prefer current user; override with SUPERVISOR_PROGRAM_USER=root only when intentional.
_program_user = os.environ.get('SUPERVISOR_PROGRAM_USER') or getpass.getuser()


def addToSupervisord(cmdName, cmd):
    ubuntu_su_conf_path = '/etc/supervisor/conf.d/'
    log_dir = '/var/log/supervisor/'
    if not os.path.exists(ubuntu_su_conf_path):
        run_cmd('mkdir -p ' + ubuntu_su_conf_path, error_log)

    if not os.path.exists(log_dir):
        run_cmd('mkdir -p ' + log_dir, error_log)

    configFileOpened = open(ubuntu_su_conf_path + cmdName + '.conf', 'w')
    config_content = ''
    if '/' in cmd[:cmd.find(' ')]:
        config_content = '[program:' + cmdName + ']' + '\n' + \
                'command = ' + cmd + '\n' + \
                'directory = ' + cmd[:cmd.rfind('/')+1] + '\n' + \
                'user = ' + _program_user + '\n' + \
                'autostart = true' + '\n' + \
                'autorestart = true' + '\n' + \
                'stdout_logfile = ' + log_dir + cmdName + '.log' + '\n' + \
                'stderr_logfile = ' + log_dir + cmdName + '_err.log' + '\n'
    else:
        config_content = '[program:' + cmdName + ']' + '\n' + \
                'command = ' + cmd + '\n' + \
                'user = ' + _program_user + '\n' + \
                'autostart = true' + '\n' + \
                'autorestart = true' + '\n' + \
                'stdout_logfile = ' + log_dir + cmdName + '.log' + '\n' + \
                'stderr_logfile = ' + log_dir + cmdName + '_err.log' + '\n'

    configFileOpened.write(config_content)
    configFileOpened.close()
    run_cmd('systemctl enable supervisor', error_log, goOnRun=False)
    run_cmd('systemctl start supervisor', error_log, goOnRun=False)
    run_cmd('supervisorctl reload', error_log, goOnRun=False)

addToSupervisord(cmdName, cmd)

error_log.close()
if delBlankFile(error_log_file):
    welcomePrint('Add cmd to supervisor success!')
else:
    welcomePrint('Add cmd to supervisor failed!')
