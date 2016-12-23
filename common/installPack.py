#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2016 blueyi <blueyi@ubuntu>
#
# Distributed under terms of the MIT license.

"""
Install package list from file
"""

from common import *

runAsRoot()

welcomePrint('Installing software from file')

apt_list = ['ubuntu', 'debian', 'linuxmint']
rpm_list = ['fedora', 'centos']
sys_distribution = platform.linux_distribution()[0].lower()
# print(sys_distribution)

error_log_file = errLogFileName(__file__)
error_log = open(error_log_file, 'w')

install_cmd = None
dis_cmd = None
soft_list_file = None
if is_list_in_str(apt_list, sys_distribution):
    install_cmd = 'apt-get install '
    dis_cmd = 'apt'
    soft_list_file = 'deb_app_list.ini'
    run_cmd('apt-get update -y', error_log)
elif is_list_in_str(rpm_list, sys_distribution):
    install_cmd = 'yum install '
    dis_cmd = 'yum'
    soft_list_file = 'rpm_app_list.ini'
    run_cmd('yum update -y', error_log)
else:
    print('Your distribution is not in supported list')
    sys.exit(1)

soft_list_file = curPath() + '/' + soft_list_file

# query package of soft from system
def package_query_cmd(soft):
    package_query_str = ''
    if dis_cmd == 'apt':
        package_query_str = "dpkg --get-selections | grep '\\b" + soft + "\\s*install'"
    elif dis_cmd == 'yum':
        package_query_str = "rpm -qa | grep '\\b" + soft + "'"
    return package_query_str


def depend_install(soft):
    toutput = run_cmd_reout(package_query_cmd(soft), error_log)
    if soft in toutput.__str__():
        print(soft + ' -- You have installed!')
        return 1
    print('---Installing ' + soft + ' ---')
    return run_cmd(install_cmd + ' ' +  soft + ' -y', error_log)


soft_list = []
old_installed_list = []
failed_list = []
with open(soft_list_file, 'r') as text:
    for tline in text:
        if tline[0] != '#' and len(tline.strip()) != 0:
            soft_list.append(tline.strip().split('#')[0])

welcomePrint('You have ' + len(soft_list).__str__()  + ' softwares need to be installed')

for app in soft_list:
    dep_code = depend_install(app)
    if dep_code == 1:
        old_installed_list.append(app)
    elif dep_code == -1:
        failed_list.append(app)

error_log.close()
if delBlankFile(error_log_file):
    welcomePrint('All package Install Success!\n   ' + str(len(old_installed_list)) + '/' + str(len(soft_list)) + ' packages already have been installed')
else:
    welcomePrint('Some package Install Failed!\n   ' + 'Install Failed:' + str(failed_list))
