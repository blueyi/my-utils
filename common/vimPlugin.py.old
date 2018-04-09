#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2016 blueyi <blueyi@ubuntu>
#
# Distributed under terms of the MIT license.

"""
Create batch soft link from file
"""

from common import *

welcomePrint('Installing vim Plugin')

isInstallYCM = False
if len(sys.argv) > 1 and sys.argv[1] == '-ycm':
    isInstallYCM = True

error_log_file = errLogFileName(__file__)
error_log = open(error_log_file, 'w')

vimrc = os.path.abspath(curPath() + '/../' + 'config/_vimrc')
plugin_list = []

if isInstallYCM:
    plugin_list.append('Valloric/YouCompleteMe.git')

# get plugin list from vimrc
with open(vimrc, 'r') as text:
    for tline in text:
        tline = tline.lstrip()
        if len(tline.strip()) != 0 and tline[:6] == 'Plugin' and 'YouCompleteMe' not in tline:
            plugin = tline[tline.find("'") + 1 : tline.rfind("'")]
            plugin_list.append(plugin)

# print(plugin_list)

# clone url to dir
def gitClone(turl, tdir):
    if not os.path.exists(tdir):
        git_cmd = 'git clone ' + turl + ' ' + tdir
        run_cmd(git_cmd, error_log)
        return 0
    else:
        print('git clone error, destination has existed: ' + tdir)
        return 1


# vim config
#vim的备份文件夹
if not os.path.exists(userPath() + '/.vimbak'):
    run_cmd('mkdir -p ~/.vimbak', error_log)

# vim bundle文件夹
if not os.path.exists(userPath() + '/.vim/bundle'):
    run_cmd('mkdir -p ~/.vim/bundle', error_log)

welcomePrint(str(plugin_list))

old_plugin = []
failed_plugin = []
# install vim plugin
for plugin in plugin_list:
    plu_url = 'https://github.com/' + plugin
    plu_dir = userPath() + '/.vim/bundle/'
    if plugin[len(plugin) - 4 : ] == '.git':
        plu_dir = plu_dir + plugin[plugin.rfind('/') + 1 : len(plugin) - 4]
    else:
        plu_dir = plu_dir + plugin[plugin.rfind('/') + 1 :]
    git_code = gitClone(plu_url, plu_dir)
    os.chdir(plu_dir)
    run_cmd('git submodule update --init --recursive', error_log)
    os.chdir(curPath())
    if git_code == -1:
        failed_plugin.append(plugin)
    elif git_code == 1:
        old_plugin.append(plugin)

# ---Youcompleteme install---
def installYCM():
    welcomePrint('Configing Youcompleteme')
    ycm = userPath() + '/' + '.vim/bundle/YouCompleteMe'
    os.chdir(ycm)
    run_cmd('git submodule update --init --recursive', error_log)
    ycm_code = run_cmd('./install.py --clang-completer', error_log)
    os.chdir(curPath())
    if ycm_code == 0:
        return 0
    elif ycm_code == -1:
        return -1
    else:
        return ycm_code

if isInstallYCM:
    code = installYCM()
    if code == -1:
        failed_plugin.append('Youcompleteme')
        welcomePrint('Config Youcompleteme failed!')
    else:
        welcomePrint('Config Youcompleteme success!')

welcomePrint(str(plugin_list))

error_log.close()
if delBlankFile(error_log_file):
    welcomePrint('vim plugin install success!\n   ' + str(len(plugin_list) - len(old_plugin) - len(failed_plugin)) + '/' + str(len(plugin_list)) + ' already have been installed!')
else:
    welcomePrint('some vim plugin install failed!\n   Failed:' + str(failed_plugin))
