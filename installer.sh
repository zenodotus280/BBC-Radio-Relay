#!/bin/sh

# housekeeping
if [ "$(id -u)" -ne 0 ]
  then echo "Please run as root."
  exit
fi

# pathing
BASE_FOLDER=/srv/bbc-rr
ICECAST_XML=/etc/icecast2/icecast.xml
KILL_FFMPEG=$BASE_FOLDER/cron-scripts/kill-ffmpeg
PURGE_OGG=$BASE_FOLDER/cron-scripts/purge-ogg
RESYNC=$BASE_FOLDER/cron-scripts/resync
DOWNLOADER=$BASE_FOLDER/run-scripts/downloader.sh
RESTART_SERVICE=$BASE_FOLDER/run-scripts/restart-service.sh
START_RADIO=$BASE_FOLDER/run-scripts/start_radio.sh

# install
apt update && apt install wget unzip dialog python3 at ffmpeg ices2 icecast2 -y

wget "https://github.com/zenodotus280/BBC-Radio-Relay/archive/refs/heads/main.zip" -O /opt/bbc-radio-relay.zip
unzip -d /opt /opt/bbc-radio-relay.zip
mkdir -p $BASE_FOLDER/www
cp -r /opt/BBC-Radio-Relay-main/radio-relay/* $BASE_FOLDER
cp -r /opt/BBC-Radio-Relay-main/radio-player/* $BASE_FOLDER/www

# configure
PASSWORD=$(head -c 32 /dev/random | base64 | tr -dc 'a-zA-Z0-9')
sed -i "s/hackme/$PASSWORD/g" $ICECAST_XML $START_RADIO
sed -i "/sources/s/2/100/" $ICECAST_XML
mkdir -p /var/log/ices
echo "ENABLE=true" >> /etc/default/icecast2

chmod -R 774 $BASE_FOLDER
chmod +X $BASE_FOLDER
chmod -R +wx $KILL_FFMPEG $PURGE_OGG $RESYNC $DOWNLOADER $RESTART_SERVICE $START_RADIO
sed -i 's|BASE_FOLDER=|BASE_FOLDER='"$BASE_FOLDER"'|' $KILL_FFMPEG $PURGE_OGG $RESYNC $DOWNLOADER $RESTART_SERVICE $START_RADIO

# keep file length under 4 hours, clear day-old files, and restart all weekly
echo "0 */12 * * * sh $BASE_FOLDER/cron-scripts/kill-ffmpeg
0 */1 * * * sh $BASE_FOLDER/cron-scripts/purge-ogg
0 6 * * 1 apt upgrade -y; systemctl reboot
@reboot sh $BASE_FOLDER/cron-scripts/resync
@reboot /etc/init.d/icecast2 start" | crontab -

# start
systemctl start icecast2 && systemctl enable icecast2
dialog --yesno "By default a cron job is established @reboot to start the relay. Start it now too? " 6 50 && sh $RESYNC
