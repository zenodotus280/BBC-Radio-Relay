#!/bin/bash
clear
set -eu
# housekeeping
# Check if script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Check if systemd is available
if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemd is not available. This script requires systemd as the init system."
    exit 1
fi

# Check if apt is the package manager
if ! command -v apt >/dev/null 2>&1; then
    echo "apt is not available. This script requires apt as the package manager."
    exit 1
fi

apt update

# Check if bash is installed
if ! command -v bash >/dev/null 2>&1; then
    echo "Bash is not installed. Please install bash before running this script."
    exit 1
fi

# Check if wget is available
if ! command -v wget >/dev/null 2>&1; then
    apt install -y wget
fi

# Check if github.com is reachable
if ! wget -q --spider https://github.com 2>/dev/null; then
    echo "Unable to reach github.com. Please check your internet connection."
    exit 1
fi

# Check for available disk space (25 GB)
required_disk_space=$((25 * 1024))  # 25 GB in MB
available_disk_space=$(df -m --output=avail / | awk 'NR==2 {print $1}')
if [ "$available_disk_space" -lt "$required_disk_space" ]; then
    echo "Insufficient disk space. At least 25 GB of free disk space will be required."
    exit 0
fi

# Optional: Check if iptables is available
if command -v iptables >/dev/null 2>&1; then

echo "iptables is available. Adding firewall rules..."

# Allow incoming traffic on ports 80 and 8080
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# Save iptables rules to persist across reboots
iptables-save > /etc/iptables/rules.v4

# For IPv6:
# ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT
# ip6tables -A INPUT -p tcp --dport 8080 -j ACCEPT
# ip6tables-save > /etc/iptables/rules.v6

else
    echo "iptables is not available. Skipping firewall rules..."
fi

cd /root

dialog --title "Welcome! Here be dragons..." --msgbox "This script can install or uninstall the service and most related packages. It will also edit cron jobs and do many other things. I don't really know what I'm doing so I would only run this in a Virtual Machine if I were you... Have fun!" 0 0; clear

MODE=$(dialog --title "Please choose the mode." --menu "Script Mode" 0 0 0 \
  1 "Install" \
  2 "Uninstall" \
  3>&1 1>&2 2>&3 3>&-); clear # open file descriptor, stdout to sterr, sterr to new file descriptor, then close file descriptor

if [ "$MODE" == "1" ]; then
    dialog --yesno "There are some copyright concerns with this project. You are running this service at your own risk -- do you agree?" 0 0 && clear || exit 0
VERSION=$(dialog --title "Please choose the version." --menu "Script Mode" 0 0 0 \
  1 "Stable" \
  2 "Testing" \
  3>&1 1>&2 2>&3 3>&-); clear # open file descriptor, stdout to sterr, sterr to new file descriptor, then close file descriptor
fi

# pathing and variables
BASE_FOLDER=/srv/bbc-rr
ICECAST_XML=/etc/icecast2/icecast.xml
KILL_FFMPEG=$BASE_FOLDER/cron-scripts/kill-ffmpeg
PURGE_OGG=$BASE_FOLDER/cron-scripts/purge-ogg
RESYNC=$BASE_FOLDER/cron-scripts/resync
DOWNLOADER=$BASE_FOLDER/run-scripts/downloader.sh
RESTART_SERVICE=$BASE_FOLDER/run-scripts/restart-service.sh
START_RADIO=$BASE_FOLDER/run-scripts/start_radio.sh
STD_PACKAGES="unattended-upgrades wget unzip dialog python3 pip"
XTR_PACKAGES="ffmpeg ices2 icecast2 at nginx"
STABLE_VERSION=1.1.1

# install/uninstall packages, files, and folders

if [ "$MODE" == "1" ]; then
    # install all packages
    apt update
    apt upgrade -yq
    for package in "${STD_PACKAGES[@]}"; do
        apt install $package -y
    done
    for package in "${XTR_PACKAGES[@]}"; do
        apt install $package -y
    done
    pip install jinja2
    # files and folders
    rm -rf /opt/BBC-Radio-Relay* & rm -rf /opt/bbc-radio-relay*
    mkdir -pv $BASE_FOLDER/www/stations
    mkdir -pv $BASE_FOLDER/www/media # in anticipation of downloader script

    if [ "$VERSION" == "1" ]; then
        wget "https://github.com/zenodotus280/BBC-Radio-Relay/archive/refs/tags/v${STABLE_VERSION}.zip" -O /opt/bbc-radio-relay.zip
        unzip -d /opt /opt/bbc-radio-relay.zip
        cp -r /opt/BBC-Radio-Relay-${STABLE_VERSION}/radio-relay/* $BASE_FOLDER
        cp -r /opt/BBC-Radio-Relay-${STABLE_VERSION}/radio-player/* $BASE_FOLDER/www

    elif [ "$VERSION" == "2" ]; then
        wget "https://github.com/zenodotus280/BBC-Radio-Relay/archive/refs/heads/main.zip" -O /opt/bbc-radio-relay.zip
        unzip -d /opt /opt/bbc-radio-relay.zip
        cp -r /opt/BBC-Radio-Relay-testing/radio-relay/* $BASE_FOLDER
        cp -r /opt/BBC-Radio-Relay-testing/radio-player/* $BASE_FOLDER/www
        cp -r /opt/BBC-Radio-Relay-testing/config $BASE_FOLDER
    fi

    mv $BASE_FOLDER/config/nginx-default.conf /etc/nginx/sites-available/default
    cd $BASE_FOLDER/www
    python3 $BASE_FOLDER/www/generate.py
    cd /root

elif [ "$MODE" == "2" ]; then
    # stop services if running and remove uncommon packages
    systemctl stop icecast2
    systemctl stop nginx
    ps axf | grep downloader | awk '{print "kill -9 " $1}' | sh || true
    ps axf | grep restart-service | awk '{print "kill -9 " $1}' | sh || true
    ps axf | grep ffmpeg | awk '{print "kill -9 " $1}' | sh || true
    ps axf | grep ices2 | awk '{print "kill -9 " $1}' | sh || true
    ps axf | grep icecast2 | awk '{print "kill -9 " $1}' | sh || true
    ps axf | grep bbc-rr | awk '{print "kill -9 " $1}' | sh || true
    ps axf | grep "sleep.*[3-9][6-9][0-9]\{2\}$\|sleep.*[4-9][0-9]\{3\}$\|sleep.*[1-9][0-9]\{4,\}$" | awk '{print "kill -9 " $1}' | sh || true
    for package in "${XTR_PACKAGES[@]}"; do
        apt purge $package -y
        apt autoremove
        apt autoclean
    done
    
else
    echo "Invalid mode."
fi

# configure

if [ "$MODE" == "1" ]; then
    # set passwords and configure icecast2 
    PASSWORD=$(head -c 32 /dev/random | base64 | tr -dc 'a-zA-Z0-9')
    sed -i "s/hackme/$PASSWORD/g" $ICECAST_XML $START_RADIO
    sed -i "/sources/s/2/100/" $ICECAST_XML
    mkdir -p /var/log/ices
    echo "ENABLE=true" >> /etc/default/icecast2
    # set permissions and configure BASE_FOLDER
    chmod -R 774 $BASE_FOLDER
    chmod +X $BASE_FOLDER
    chmod -R +wx $KILL_FFMPEG $PURGE_OGG $RESYNC $DOWNLOADER $RESTART_SERVICE $START_RADIO
    sed -i 's|BASE_FOLDER=|BASE_FOLDER='"$BASE_FOLDER"'|' $KILL_FFMPEG $PURGE_OGG $RESYNC $DOWNLOADER $RESTART_SERVICE $START_RADIO
    chown -R root:www-data $BASE_FOLDER/www # for NGINX permissions
    chmod -R 0755 $BASE_FOLDER/www # for NGINX permissions

elif [ "$MODE" == "2" ]; then
    # remove as much of the installation as possible
    rm -rf /etc/icecast2 /var/log/ices /var/log/icecast2 $BASE_FOLDER 
    rm -rf /opt/BBC-Radio-Relay* & rm -rf /opt/bbc-radio-relay*
else
    echo "Invalid mode."
fi

# cronjobs

if [ "$MODE" == "1" ] || [ "$MODE" == "2" ]; then
    # initialise and backup the current crontab
    echo "###" | crontab -
    crontab -l > crontab.bak

    # The cron entries
        #kill_ffmpeg: keep file lengths under 12 hours
        #purge_ogg:   clean up day-old audio files
        #             reboot at 6am weekly to remain in sync
        #resync:      bootstrap the relay on boot
        #             currently redundant since service is already enabled during installation with systemd
    CRON=("0 */12 * * * sh $KILL_FFMPEG" "0 */1 * * * sh $PURGE_OGG" "0 6 * * 1 apt upgrade -y; systemctl reboot" "@reboot sh $RESYNC" "@reboot /etc/init.d/icecast2 start")

    # Escape the asterisks
    CRON=("${CRON[@]/\*/\*}")
else
    echo "Invalid mode."
fi

if [ "$MODE" == "1" ]; then
    # Add the lines to the crontab
    for line in "${CRON[@]}"; do
        if ! grep -q "$line" crontab.bak; then
            echo "$line" >> crontab.bak
        fi
    done
elif [ "$MODE" == "2" ]; then
    # Remove the lines from the crontab
    for line in "${CRON[@]}"; do
        if grep -q "$line" crontab.bak; then
            sed -i "/${line}/d" crontab.bak || dialog --title "Line Not Found" --msgbox "The line: $line was not found in the crontab. \nIt may have been altered or removed manually." 0 0
        fi
    sed -i "/###/d" crontab.bak
    done
else
    echo "Invalid mode."
fi

if [ "$MODE" == "1" ] || [ "$MODE" == "2" ]; then
    # Install the modified crontab
    crontab crontab.bak

    # Remove the backup file
    rm crontab.bak
fi

# start
if [ "$MODE" == "1" ]; then
    #
    systemctl start icecast2 && systemctl enable icecast2
    bash $RESYNC
    systemctl reload nginx && systemctl start nginx
    dialog --title "WebUI Test" --msgbox "The WebUI will be available 8 hours after starting the streams by default. To verify that the WebUI will function as expected, go to port 80 on one of the follow IP addresses: \n\n$(hostname -I)" 0 0
    dialog --yesno "It will take approximately 30 seconds for the test streams to be available on port 8000. The test streams will be disabled after rebooting. \n\n$(hostname -I)\n\nSelect 'Yes' whn you've finished testing ports 80 and 8080 in order to reboot. " 0 0 && sed -i 's/startCustomstream $2 #user-defined/#&/' $START_RADIO && reboot || exit 0
elif [ "$MODE" == "2" ]; then
    # Delete the script itself if it still exists
    dialog --yesno "Select 'Yes' to delete this script." 0 0 && rm -- "$0" || exit 0
else
    echo "Invalid mode."
fi
