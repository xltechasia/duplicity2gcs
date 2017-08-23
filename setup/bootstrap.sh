#!/bin/bash
############################################################
# This script is intended to be run like this:
#
#   curl <replace with github raw url> | sudo bash
#
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

XLT_APPNAME="Duplicity2GCS"
XLT_APPCMD="duplicity2gcs"
XLT_APPFULLCMD="duplicity2gcs.py"
XLT_GITREPO="https://github.com/xltechasia/duplicity2gcs.git"
XLT_INSTALLDIR="/opt/duplicity2gcs"

# Are we running as root?
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Did you leave out sudo?"
    exit
fi

# Clone the duplicity2gcs repository if it doesn't exist.
if [ ! -d "$XLT_INSTALLDIR/.git" ]; then
    if [ ! -f /usr/bin/git ]; then
        echo "Installing git . . ."
        apt-get -q -q update
        DEBIAN_FRONTEND=noninteractive apt-get -q -q install -y git < /dev/null
        echo
    fi

    echo "Downloading $XLT_APPNAME . . ."
    git clone "$XLT_GITREPO" "$XLT_INSTALLDIR" < /dev/null 2> /dev/null
    echo
fi

# Change directory to it.
cd "$XLT_INSTALLDIR"

# Start setup script.
setup/start.sh
