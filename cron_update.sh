#!/bin/bash
# ClamAV Enhanced Scanner Daily Cron Updater
# Written by Josh Grancell

VERSION="1.1.1"
DATE="Feb 18 2015"
TEMP=$(mktemp -d)
cd "$TEMP"

wget -q https://www.rfxn.com/downloads/rfxn.hdb
wget -q https://www.rfxn.com/downloads/rfxn.ndb
wget -q https://www.rfxn.com/downloads/hex.dat
wget -q https://www.rfxn.com/downloads/md5.dat

cat rfxn.hdb > /usr/local/share/clamav/rfxn.hdb
cat rfxn.ndb > /usr/local/share/clamav/rfxn.ndb
cat hex.dat > /usr/local/share/clamav/hex.dat
cat md5.dat > /usr/local/share/clamav/md5.dat

DATE=$(date)

echo "$DATE" >> /usr/local/share/clamav/log/update.log

rm -rf "$TEMP"

chown clam:clam /usr/local/share/clamav -R

exit 0
