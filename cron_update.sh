#!/bin/bash
# ClamAV Enhanced Scanner Daily Cron Updater
# Written by Josh Grancell

MAINDIR="/var/lib/clamav"
USER="clamav"

VERSION="1.2.0"
DATE="Feb 27 2015"
TEMP=$(mktemp -d)
cd "$TEMP"

wget -q https://www.rfxn.com/downloads/rfxn.hdb
wget -q https://www.rfxn.com/downloads/rfxn.ndb

cat rfxn.hdb > "$MAINDIR"/rfxn.hdb
cat rfxn.ndb > "$MAINDIR"/rfxn.ndb

DATE=$(date)

echo "$DATE" >> "$MAINDIR"/log/update.log

rm -rf "$TEMP"

chown "$USER":"$USER" "$MAINDIR" -R

exit 0
