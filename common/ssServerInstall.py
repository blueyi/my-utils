#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2016 blueyi <blueyi@ubuntu>
#
# Distributed under terms of the MIT license.

from common import *

"""
install shadowsocks python server
run by root
"""
# runAsRoot()

welcomePrint('Installing shadowsocks python server')

pri_conf = '../privacy/conf.ini'

conf = getKeyValue(pri_conf)

port = conf['sss_port']
passwd = conf['sss_passwd']
pass_method = conf['sss_pass_method']

error_log_file = errLogFileName(__file__)
print(error_log_file)
error_log = open(error_log_file, 'w')

# install pip
pip_install_cmd = 'sudo apt-get install -y python-pip'
run_cmd(pip_install_cmd, error_log, goOnRun=False)

# install shadowsocks
install_ssserver_cmd = 'sudo pip install shadowsocks'
run_cmd(install_ssserver_cmd, error_log, goOnRun=False)


# install supervisor
install_ssserver_cmd = 'sudo apt-get install -y supervisor'
run_cmd(install_ssserver_cmd, error_log, goOnRun=False)
run_cmd('systemctl enable supervisor', error_log, goOnRun=False)
run_cmd('systemctl start supervisor', error_log, goOnRun=False)

# add to supervisord
cmd = 'ssserver -p ' + str(port) + ' -k ' + passwd + ' -m ' + pass_method
cmdName = 'ssserver'
ats_cmd = 'sudo python addToSupervisord.py ' + cmdName + ' ' + '"' + cmd + '"'
run_cmd(ats_cmd, error_log, goOnRun=False)

error_log.close()
if delBlankFile(error_log_file):
    welcomePrint('shadowsocks install success!')
else:
    welcomePrint('shadowsocks install failed!')
