#!/bin/bash
# ClamAV Enhanced Scanner Daily Cron Updater
# Written by Josh Grancell

VERSION="1.4.0"
DATE="Mar 16 2015"

source conf.malscan

TEMP=$(mktemp -d)
cd "$TEMP"

wget -q https://www.rfxn.com/downloads/rfxn.hdb
wget -q https://www.rfxn.com/downloads/rfxn.ndb
wget -q https://www.joshgrancell.com/custom.hdb
wget -q https://www.joshgrancell.com/custom.ndb

cat rfxn.hdb > "$MAINDIR"/rfxn.hdb
cat rfxn.ndb > "$MAINDIR"/rfxn.ndb
cat custom.hdb > "$MAINDIR"/custom.hdb
cat custom.ndb > "$MAINDIR"/custom.ndb

DATE=$(date)

if [[ ! -d "$MAINDIR"/log ]]; then
	mkdir "$MAINDIR"/log
fi

if [[ ! -d "$MAINDIR"/quarantine ]]; then
	mkdir "$MAINDIR"/quarantine
fi

if [[ ! -h "$MALSCAN_BINARY_LOCATION" ]]; then
	ln -s "$MAINDIR"/malscan.sh $MALSCAN_BINARY_LOCATION
fi


echo "$DATE" >> "$MAINDIR"/log/update.log

rm -rf "$TEMP"

chown "$USER":"$USER" "$MAINDIR" -R

exit 0
