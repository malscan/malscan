#!/bin/bash
# ClamAV Enhanced Scanner Daily Cron Updater
# Written by Josh Grancell
# Since: 1.0

## Identifying where we're running the script from
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

## Loading the configuration file from the Malscan directory
source /"$DIR"/"conf.malscan"

TEMP=$(mktemp -d)
cd "$TEMP"

echo "Downloading the latest supplimental malware definitions."

wget -q https://www.rfxn.com/downloads/rfxn.hdb
wget -q https://www.rfxn.com/downloads/rfxn.ndb
wget -q https://repo.joshgrancell.com/custom.hdb
wget -q https://repo.joshgrancell.com/custom.ndb

cat rfxn.hdb > "$MALSCAN_DIRECTORY"/rfxn.hdb
cat rfxn.ndb > "$MALSCAN_DIRECTORY"/rfxn.ndb
cat custom.hdb > "$MALSCAN_DIRECTORY"/custom.hdb
cat custom.ndb > "$MALSCAN_DIRECTORY"/custom.ndb

echo "Running the freshclam updater."
"$FRESHCLAM_BINARY_LOCATION"

DATE=$(date)

if [[ ! -d "$MALSCAN_DIRECTORY"/log ]]; then
	mkdir "$MALSCAN_DIRECTORY"/log
fi

if [[ ! -d "$MALSCAN_DIRECTORY"/quarantine ]]; then
	mkdir "$MALSCAN_DIRECTORY"/quarantine
fi

if [[ ! -h "$MALSCAN_BINARY_LOCATION" ]]; then
	ln -s "$MALSCAN_DIRECTORY"/malscan.sh $MALSCAN_BINARY_LOCATION
fi

echo "Cleaning up..."

echo "$DATE" >> "$MALSCAN_DIRECTORY"/log/update.log

rm -rf "$TEMP"

chown "$MALSCAN_USER":"$MALSCAN_USER" "$MALSCAN_DIRECTORY" -R

exit 0
