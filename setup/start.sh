#!/bin/bash
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

XLT_APPNAME="Duplicity2GCS"
XLT_APPCMD="duplicity2gcs"
XLT_APPFULLCMD="duplicity2gcs.py"
XLT_GITREPO="https://github.com/xltechasia/duplicity2gcs.git"
XLT_INSTALLDIR="/opt/duplicity2gcs"

source setup/functions.sh # load our functions

# Check system setup: Are we running as root? On Ubuntu 1{4,6}.04 on a
# machine with enough memory? Is /tmp mounted with exec.
# If not, this shows an error and exits.
source setup/preflight.sh

# Ensure Python reads/writes files in UTF-8. If the machine
# triggers some other locale in Python, like ASCII encoding,
# Python may not be able to read/write files. This is also
# in the management daemon startup script and the cron script.

if [ -z `locale -a | grep en_US.utf8` ]; then
    # Generate locale if not exists
    hide_output locale-gen en_US.UTF-8
fi

export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8

# Fix so line drawing characters are shown correctly in Putty on Windows. See #744.
export NCURSES_NO_UTF8_ACS=1

# Recall the last settings used if we're running this a second time.
if [ -f /etc/$XLT_APPCMD.conf ]; then
    # Run any system migrations before proceeding. Since this is a second run,
    # we assume we have Python already installed.
    #setup/migrate.py --migrate || exit 1

    # Load the old .conf file to get existing configuration options loaded
    # into variables with a DEFAULT_ prefix.
    cat /etc/$XLT_APPCMD.conf | sed s/^/DEFAULT_/ > /tmp/$XLT_APPCMD.prev.conf
    source /tmp/$XLT_APPCMD.prev.conf
    rm -f /tmp/$XLT_APPCMD.prev.conf
else
    FIRST_TIME_SETUP=1
fi

# Put a start script in a global location. We tell the user to run $XLT_APPCMD
# in the first dialog prompt, so we should do this before that starts.
cat > /usr/local/bin/$XLT_APPCMD << EOF;
#!/bin/bash
cd "`pwd`"
$XLT_INSTALLDIR/$XLT_APPCMDFULL
EOF
chmod +x /usr/local/bin/$XLT_APPCMD

# Ask the user for key initial config questions
#source setup/questions.sh

# Save the global options in /etc/$XLT_APPCMD.conf so that standalone
# tools know where to look for data.
#cat > /etc/$XLT_APPCMD.conf << EOF;
#GCS_PROJECT=$GCS_PROJECT
#GCS_LOCATION=$GCS_LOCATION
#GCS_BUCKET=$GCS_BUCKET
#GCS_STORAGE_TYPE=$GCS_STORAGE_TYPE
#MIAB_CONF_LOCATION=$MIAB_CONF_LOCATION
#MIAB_KEY=$MIAB_KEY
#KEY_FILE=$KEY_FILE
#ARCHIVE_CACHE=$ARCHIVE_CACHE
#SERVICES=$SERVICES
#PRE_DUPLICITY_CMD=$PRE_DUPLICITY_CMD
#SOURCE=$SOURCE
#EXCLUDE_DIR=$EXCLUDE_DIR
#POST_DUPLICITY_CMD=$POST_DUPLICITY_CMD
#BACKUP_CYCLE=$BACKUP_CYCLE
#BACKUP_RETENTION=$BACKUP_RETENTION
#EOF

# Start service configuration.
source setup/system.sh
#source setup/gcs.sh

# Done.
echo
echo "-----------------------------------------------"
echo
echo Your $XLT_APPNAME is configured.
echo
