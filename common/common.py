#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2016 blueyi <blueyi@blueyi-ubuntu>
#
# Distributed under terms of the MIT license.

import subprocess
import sys
import os
import platform
import time

"""
Some common function and const value
"""

itoa = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k']

# path
# user path
def userPath():
    return os.path.expanduser('~')

# script path
def curPath():
    return os.path.split(os.path.realpath(__file__))[0]

# current time str
def curTimeStr():
    return time.strftime('%Y%m%d%H%M%S')

# print some important string
def welcomePrint(msg):
    print('*' * 70)
    print('   <<< ' + msg + ' >>>')
    print('*' * 70)

# print to stdout and file
def printToFile(msg, file_opened):
    print('<<< ' + msg + ' >>> run failed!')
    file_opened.write(str(msg) + '\n')

# error log file name
def errLogFileName(file):
    return file.replace('.', '_') + '_' + curTimeStr() + '.log'

# run an shell command in subprocess
def run_cmd(tcall_cmd, errOpened, goOnRun = True, isOutPut = True, isReturnCode = False):
    p = subprocess.Popen(tcall_cmd, shell=True, stdout=subprocess.PIPE, executable='/bin/bash')
    toutput = p.communicate()[0]
    if p.returncode != 0:
        printToFile(tcall_cmd, errOpened)
        if not goOnRun :
            sys.exit(1)
    if isOutPut :
        print(toutput)
    if isReturnCode :
        return p.returncode
    else :
        return toutput

def run_cmd(tcall_cmd, goOnRun = True, isOutPut = True, isReturnCode = False):
    p = subprocess.Popen(tcall_cmd, shell=True, stdout=subprocess.PIPE, executable='/bin/bash')
    toutput = p.communicate()[0]
    if p.returncode != 0:
        print(tcall_cmd)
        if not goOnRun :
            sys.exit(1)
    if isOutPut :
        print(toutput)
    if isReturnCode :
        return p.returncode
    else :
        return toutput

# delete itselft
def delSelf():
    run_cmd('rm -f ' + sys.argv[0])

# if no error log, then delete error log file
def delBlankFile(error_log_file):
    no_error = True
    with open(error_log_file, 'r') as err:
        for line in err:
            if len(line.strip()) != 0:
                no_error = False
                break
    if no_error:
        run_cmd('rm -f ' + error_log_file)
        return True
    return False

# is run by root
def runAsRoot():
    if os.geteuid() != 0:
        print('Please run the script by "root"!')
        sys.exit(1)

# create soft link
def link_cmd(sor, dest):
    cmd = 'ln -s -f '
    cmd = cmd + sor + ' ' + dest
    return cmd

# is tlist has anything string in tstr
def is_list_in_str(tlist, tstr):
    for item in tlist:
        if item in tstr:
            return True
    return False


