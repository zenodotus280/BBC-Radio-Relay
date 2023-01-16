#!/bin/bash
clear
set -eu
# housekeeping
if [ "$(id -u)" -ne 0 ]
  then echo "Please run as root."
  exit
fi
cd /root
dialog --title "Welcome! Here be dragons..." --msgbox "This script can install or uninstall the service and most related packages. It will also edit cron jobs and do many other things. I don't really know what I'm doing so I would only run this in a Virtual Machine if I were you... Have fun!" 0 0; clear

VERSION=$(dialog --title "Please choose the version." --menu "Script Mode" 0 0 0 \
  1 "stable" \
  2 "testing" \
  3>&1 1>&2 2>&3 3>&-); clear # open file descriptor, stdout to sterr, sterr to new file descriptor, then close file descriptor

MODE=$(dialog --title "Please choose the mode." --menu "Script Mode" 0 0 0 \
  1 "install" \
  2 "uninstall" \
  3>&1 1>&2 2>&3 3>&-); clear # open file descriptor, stdout to sterr, sterr to new file descriptor, then close file descriptor
dialog --yesno "There are some copyright concerns with this project. You are running this service at your own risk -- do you agree?" 0 0 && clear || exit 0

# pathing and variables
BASE_FOLDER=/srv/bbc-rr
ICECAST_XML=/etc/icecast2/icecast.xml
KILL_FFMPEG=$BASE_FOLDER/cron-scripts/kill-ffmpeg
PURGE_OGG=$BASE_FOLDER/cron-scripts/purge-ogg
RESYNC=$BASE_FOLDER/cron-scripts/resync
DOWNLOADER=$BASE_FOLDER/run-scripts/downloader.sh
RESTART_SERVICE=$BASE_FOLDER/run-scripts/restart-service.sh
START_RADIO=$BASE_FOLDER/run-scripts/start_radio.sh
STD_PACKAGES=("wget" "unzip" "dialog" "python3")
XTR_PACKAGES=("ffmpeg" "ices2" "icecast2")

# install/uninstall packages, files, and folders

if [ "$MODE" == "install" ]; then
    # install all packages
    apt update
    apt install "${STD_PACKAGES[@]}" "${XTR_PACKAGES[@]}" -y
    # files and folders
    rm -rf /opt/BBC-Radio-Relay* & rm -rf /opt/bbc-radio-relay*
    if [ "$VERSION" == "testing" ]; then
    wget "https://github.com/zenodotus280/BBC-Radio-Relay/archive/refs/heads/testing.zip" -O /opt/bbc-radio-relay.zip
    elif [ "$VERSION" == "stable" ]; then
    unzip -d /opt /opt/bbc-radio-relay.zip
    mkdir -p $BASE_FOLDER/www
    cp -r /opt/BBC-Radio-Relay-testing/radio-relay/* $BASE_FOLDER
    cp -r /opt/BBC-Radio-Relay-testing/radio-player/* $BASE_FOLDER/www
    
elif [ "$MODE" == "uninstall" ]; then
    # stop services if running and remove uncommon packages
    systemctl stop icecast2
    ps axf | grep downloader | awk '{print "kill -9 " $1}' | sh
    ps axf | grep restart-service | awk '{print "kill -9 " $1}' | sh
    ps axf | grep ffmpeg | awk '{print "kill -9 " $1}' | sh
    ps axf | grep ices2 | awk '{print "kill -9 " $1}' | sh
    ps axf | grep icecast2 | awk '{print "kill -9 " $1}' | sh
    apt remove "${XTR_PACKAGES[@]}"
    
else
    echo "Invalid mode."
fi

# configure

if [ "$MODE" == "install" ]; then
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
    
elif [ "$MODE" == "uninstall" ]; then
    # remove as much of the installation as possible
    rm -rf /etc/icecast2 /var/log/ices $BASE_FOLDER 
    rm -rf /opt/BBC-Radio-Relay* & rm -rf /opt/bbc-radio-relay*
else
    echo "Invalid mode."
fi

# cronjobs

if [ "$MODE" == "install" ] || [ "$MODE" == "uninstall" ]; then
    # Backup the current crontab
    crontab -l > crontab.bak

    # The cron entries
    CRON=("0 */12 * * * sh $KILL_FFMPEG # keep file lengths under 12 hours" "0 */1 * * * sh $PURGE_OGG # clean up day-old audio files" "0 6 * * 1 apt upgrade -y; systemctl reboot # reboot at 6am weekly to remain in sync" "@reboot sh $RESYNC # bootstrap the relay on boot" "@reboot /etc/init.d/icecast2 start # redundant since service is already enabled during installation with systemd")

    # Escape the asterisks
    CRON=("${CRON[@]/\*/\*}")
else
    echo "Invalid mode."
fi

if [ "$MODE" == "install" ]; then
    # Add the lines to the crontab
    for line in "${CRON[@]}"; do
        if ! grep -q "$line" crontab.bak; then
            echo "$line" >> crontab.bak
        fi
    done
elif [ "$MODE" == "uninstall" ]; then
    # Remove the lines from the crontab
    for line in "${CRON[@]}"; do
        if grep -q "$line" crontab.bak; then
            sed -i "/${line}/d" crontab.bak
        else
            # Display a message box if the line was not found
            dialog --title "Line Not Found" --msgbox "The line: $line was not found in the crontab. \nIt may have been altered or removed manually." 0 0; clear
        fi
    done
else
    echo "Invalid mode."
fi

if [ "$MODE" == "install" ] || [ "$MODE" == "uninstall" ]; then
    # Install the modified crontab
    crontab crontab.bak

    # Remove the backup file
    rm crontab.bak
fi

# start
if [ "$MODE" == "install" ]; then
    #
    systemctl start icecast2 && systemctl enable icecast2
    dialog --yesno "By default a cron job is established @reboot to start the relay. Would you like to start the 'resync' script now? It will take approximately 30 seconds for the test streams to be available on port 8000." 6 50 && sh $RESYNC
elif [ "$MODE" == "uninstall" ]; then
    # Delete the script itself if it still exists
    rm -- "$0"
else
    echo "Invalid mode."
fi