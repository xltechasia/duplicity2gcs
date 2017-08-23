# Check baseline system config
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

# Are we running as root?
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please re-run like this:"
    echo
    echo "sudo $0"
    echo
    exit
fi

# Check that we are running on Ubuntu 14.04/16.04 LTS (or 1{4,6}.04.xx).
case "`lsb_release -d | sed 's/.*:\s*//' | sed 's/1\([46]\)\.04\.[0-9]/1\1.04/' `" in
    "Ubuntu 14.04 LTS" | "Ubuntu 16.04 LTS")
        echo
        ;;
    *)
        echo "$XLT_APPNAME has been tested & developed on Ubuntu 14.04/16.04 LTS. You are running:"
        echo
        lsb_release -d | sed 's/.*:\s*//'
        echo
        echo "Please be aware this software will/may fail for your configuration"
        echo "You are responsible for ensuring it works reliabily to your expectations"
        echo
esac

# TODO: Validate if we need this
# Check that tempfs is mounted with exec
MOUNTED_TMP_AS_NO_EXEC=$(grep "/tmp.*noexec" /proc/mounts)
if [ -n "$MOUNTED_TMP_AS_NO_EXEC" ]; then
    echo "$XLT_APPNAME has to have exec rights on /tmp, please mount /tmp with exec"
    exit
fi

# Check that no .wgetrc exists
if [ -e ~/.wgetrc ]; then
    echo "$XLT_APPNAME expects no overrides to wget defaults, ~/.wgetrc exists"
    exit
fi

# Check that we are running on x86_64 or i686, any other architecture is unsupported and
# will/may fail later in the setup.
ARCHITECTURE=$(uname -m)
if [ "$ARCHITECTURE" != "x86_64" ] && [ "$ARCHITECTURE" != "i686" ]; then
        echo "$XLT_APPNAME only supports x86_64 or i686 and may not work on any other architecture, like ARM."
        echo "Your architecture is $ARCHITECTURE"
fi
