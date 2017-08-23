#!/usr/bin/python3
############################################################
# Duplicity2GCS
#
# Copyright 2017,  XLTech
#
# This is the entry point for configuring the system.
############################################################
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
############################################################
# This script/code, or part thereof, are copied/modified from
# the Mail-In-A-Box project (https://mailinabox.email)
############################################################
# Description
#
# Script to initiate Google Cloud Storage and manage/wrap
# duplicity for backups to GSC on Ubuntu 14.04.x/16.04.x
############################################################
# Known Bugs/Limitations/Work-Arounds
#
# Untested on Debian and other deriviatives - YMMV
############################################################
# To Do/Future Plans/Hopes
#  - Support Mail-In-A-Box, WordPress, Nextcloud if/where needed
#  - ZFS Support
############################################################
# History
# v 0.10    Matthew A Snell <astro7467@xltech.co>
#           Initial Version
############################################################

import argparse
import re
import collections
import os, os.path
import shutil
import glob
import datetime
import sys
import dateutil.parser, dateutil.relativedelta, dateutil.tz
import rtyaml

from exclusiveprocess import Lock
from configparser import ConfigParser


# Globals
duplicity2gcs_conf  = "/etc/duplicity2gcs.conf"

def load_environment():
    # Load default settings from /etc/duplicity2gcs.conf.
    return load_env_vars_from_file(duplicity2gcs_conf)

def load_env_vars_from_file(fn):
    # Load settings from a KEY=VALUE file.
    env = collections.OrderedDict()
    for line in open(fn): env.setdefault(*line.strip().split("=", 1))
    return env

def save_environment(env):
    with open("/etc/mailinabox.conf", "w") as f:
        for k, v in env.items():
            f.write("%s=%s\n" % (k, v))

def shell(method, cmd_args, env={}, capture_stderr=False, return_bytes=False, trap=False, input=None):
    # A safe way to execute processes.
    # Some processes like apt-get require being given a sane PATH.
    import subprocess

    env.update({ "PATH": "/sbin:/bin:/usr/sbin:/usr/bin" })
    kwargs = {
        'env': env,
        'stderr': None if not capture_stderr else subprocess.STDOUT,
    }
    if method == "check_output" and input is not None:
        kwargs['input'] = input

    if not trap:
        ret = getattr(subprocess, method)(cmd_args, **kwargs)
    else:
        try:
            ret = getattr(subprocess, method)(cmd_args, **kwargs)
            code = 0
        except subprocess.CalledProcessError as e:
            ret = e.output
            code = e.returncode
    if not return_bytes and isinstance(ret, bytes): ret = ret.decode("utf8")
    if not trap:
        return ret
    else:
        return code, ret

def create_syslog_handler():
    import logging.handlers
    handler = logging.handlers.SysLogHandler(address='/dev/log')
    handler.setLevel(logging.WARNING)
    return handler

def du(path):
    # Computes the size of all files in the path, like the `du` command.
    # Based on http://stackoverflow.com/a/17936789. Takes into account
    # soft and hard links.
    total_size = 0
    seen = set()
    for dirpath, dirnames, filenames in os.walk(path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            try:
                stat = os.lstat(fp)
            except OSError:
                continue
            if stat.st_ino in seen:
                continue
            seen.add(stat.st_ino)
            total_size += stat.st_size
    return total_size

def wait_for_service(port, public, env, timeout):
    # Block until a service on a given port (bound privately or publicly)
    # is taking connections, with a maximum timeout.
    import socket, time
    start = time.perf_counter()
    while True:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout/3)
        try:
            s.connect(("127.0.0.1" if not public else env['PUBLIC_IP'], port))
            return True
        except OSError:
            if time.perf_counter() > start+timeout:
                return False
        time.sleep(min(timeout/4, 1))

def fix_boto():
    # Google Compute Engine instances install some Python-2-only boto plugins that
    # conflict with boto running under Python 3. Disable boto's default configuration
    # file prior to importing boto so that GCE's plugin is not loaded:
    import os
    os.environ["BOTO_CONFIG"] = "/etc/boto3.cfg"

def main():
    # Nothing here yet

# Standard boilerplate to call the main() function.
if __name__ == '__main__':
  main()
