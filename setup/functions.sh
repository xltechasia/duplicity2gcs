#  Common/Shared functions
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

function hide_output {
    # This function hides the output of a command unless the command fails
    # and returns a non-zero exit code.

    # Get a temporary file.
    OUTPUT=$(tempfile)

    # Execute command, redirecting stderr/stdout to the temporary file.
    $@ &> $OUTPUT

    # If the command failed, show the output that was captured in the temporary file.
    E=$?
    if [ $E != 0 ]; then
        # Something failed.
        echo
        echo FAILED: $@
        echo -----------------------------------------
        cat $OUTPUT
        echo -----------------------------------------
        exit $E
    fi

    # Remove temporary file.
    rm -f $OUTPUT
}

function apt_get_quiet {
    # Run apt-get in a totally non-interactive mode.
    #
    # Somehow all of these options are needed to get it to not ask the user
    # questions about a) whether to proceed (-y), b) package options (noninteractive),
    # and c) what to do about files changed locally (we don't cause that to happen but
    # some VM providers muck with their images; -o).
    #
    # Although we could pass -qq to apt-get to make output quieter, many packages write to stdout
    # and stderr things that aren't really important. Use our hide_output function to capture
    # all of that and only show it if there is a problem (i.e. if apt_get returns a failure exit status).
    DEBIAN_FRONTEND=noninteractive hide_output apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"
}

function apt_install {
    # Install a bunch of packages. We used to report which packages were already
    # installed and which needed installing, before just running an 'apt-get
    # install' for all of the packages.  Calling `dpkg` on each package is slow,
    # and doesn't affect what we actually do, except in the messages, so let's
    # not do that anymore.
    PACKAGES=$@
    apt_get_quiet install $PACKAGES
}

function apt_add_repository_to_unattended_upgrades {
    if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
        if ! grep -q "$1" /etc/apt/apt.conf.d/50unattended-upgrades; then
            sed -i "/Allowed-Origins/a \
        \"$1\";" /etc/apt/apt.conf.d/50unattended-upgrades
        fi
    fi
}

function get_default_hostname {
    # Guess the machine's hostname. It should be a fully qualified
    # domain name suitable for DNS. None of these calls may provide
    # the right value, but it's the best guess we can make.
    set -- $(hostname --fqdn      2>/dev/null ||
                 hostname --all-fqdns 2>/dev/null ||
                 hostname             2>/dev/null)
    printf '%s\n' "$1" # return this value
}

function get_publicip_from_web_service {
    # This seems to be the most reliable way to determine the
    # machine's public IP address: asking a very nice web API
    # for how they see us. Thanks go out to icanhazip.com.
    # See: https://major.io/icanhazip-com-faq/
    #
    # Pass '4' or '6' as an argument to this function to specify
    # what type of address to get (IPv4, IPv6).
    curl -$1 --fail --silent --max-time 15 icanhazip.com 2>/dev/null
}

function get_default_privateip {
    # Return the IP address of the network interface connected
    # to the Internet.
    #
    # Pass '4' or '6' as an argument to this function to specify
    # what type of address to get (IPv4, IPv6).
    #
    # We used to use `hostname -I` and then filter for either
    # IPv4 or IPv6 addresses. However if there are multiple
    # network interfaces on the machine, not all may be for
    # reaching the Internet.
    #
    # Instead use `ip route get` which asks the kernel to use
    # the system's routes to select which interface would be
    # used to reach a public address. We'll use 8.8.8.8 as
    # the destination. It happens to be Google Public DNS, but
    # no connection is made. We're just seeing how the box
    # would connect to it. There many be multiple IP addresses
    # assigned to an interface. `ip route get` reports the
    # preferred. That's good enough for us. See issue #121.
    #
    # With IPv6, the best route may be via an interface that
    # only has a link-local address (fe80::*). These addresses
    # are only unique to an interface and so need an explicit
    # interface specification in order to use them with bind().
    # In these cases, we append "%interface" to the address.
    # See the Notes section in the man page for getaddrinfo and
    # https://discourse.mailinabox.email/t/update-broke-mailinabox/34/9.
    #
    # Also see ae67409603c49b7fa73c227449264ddd10aae6a9 and
    # issue #3 for why/how we originally added IPv6.

    target=8.8.8.8

    # For the IPv6 route, use the corresponding IPv6 address
    # of Google Public DNS. Again, it doesn't matter so long
    # as it's an address on the public Internet.
    if [ "$1" == "6" ]; then target=2001:4860:4860::8888; fi

    # Get the route information.
    route=$(ip -$1 -o route get $target | grep -v unreachable)

    # Parse the address out of the route information.
    address=$(echo $route | sed "s/.* src \([^ ]*\).*/\1/")

    if [[ "$1" == "6" && $address == fe80:* ]]; then
        # For IPv6 link-local addresses, parse the interface out
        # of the route information and append it with a '%'.
        interface=$(echo $route | sed "s/.* dev \([^ ]*\).*/\1/")
        address=$address%$interface
    fi

    echo $address
}

function ufw_allow {
    if [ -z "$DISABLE_FIREWALL" ]; then
        # ufw has completely unhelpful output
        ufw allow $1 > /dev/null;
    fi
}

function restart_service {
    if [[ `systemctl` =~ -\.mount ]]; then # Assume we are using systemd
        hide_output systemctl restart $1
    else
        hide_output service $1 restart
     fi
}

## Dialog Functions ##
function message_box {
    dialog --title "$1" --msgbox "$2" 0 0
}

function input_box {
    # input_box "title" "prompt" "defaultvalue" VARIABLE
    # The user's input will be stored in the variable VARIABLE.
    # The exit code from dialog will be stored in VARIABLE_EXITCODE.
    declare -n result=$4
    declare -n result_code=$4_EXITCODE
    result=$(dialog --stdout --title "$1" --inputbox "$2" 0 0 "$3")
    result_code=$?
}

function input_menu {
    # input_menu "title" "prompt" "tag item tag item" VARIABLE
    # The user's input will be stored in the variable VARIABLE.
    # The exit code from dialog will be stored in VARIABLE_EXITCODE.
    declare -n result=$4
    declare -n result_code=$4_EXITCODE
    local IFS=^$'\n'
    result=$(dialog --stdout --title "$1" --menu "$2" 0 0 0 $3)
    result_code=$?
}

function wget_verify {
    # Downloads a file from the web and checks that it matches
    # a provided hash. If the comparison fails, exit immediately.
    URL=$1
    HASH=$2
    DEST=$3
    CHECKSUM="$HASH  $DEST"
    rm -f $DEST
    wget -q -O $DEST $URL || exit 1
    if ! echo "$CHECKSUM" | sha1sum --check --strict > /dev/null; then
        echo "------------------------------------------------------------"
        echo "Download of $URL did not match expected checksum."
        echo "Found:"
        sha1sum $DEST
        echo
        echo "Expected:"
        echo "$CHECKSUM"
        rm -f $DEST
        exit 1
    fi
}

function git_clone {
    # Clones a git repository, checks out a particular commit or tag,
    # and moves the repository (or a subdirectory in it) to some path.
    # We use separate clone and checkout because -b only supports tags
    # and branches, but we sometimes want to reference a commit hash
    # directly when the repo doesn't provide a tag.
    REPO=$1
    TREEISH=$2
    SUBDIR=$3
    TARGETPATH=$4
    TMPPATH=/tmp/git-clone-$$
    rm -rf $TMPPATH $TARGETPATH
    git clone -q $REPO $TMPPATH || exit 1
    (cd $TMPPATH; git checkout -q $TREEISH;) || exit 1
    mv $TMPPATH/$SUBDIR $TARGETPATH
    rm -rf $TMPPATH
}
