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

echo -e "\033[33mUpdate: Downloading the latest Malscan malware definitions."

wget -q https://www.rfxn.com/downloads/rfxn.hdb
wget -q https://www.rfxn.com/downloads/rfxn.ndb
wget -q https://repo.joshgrancell.com/custom.hdb
wget -q https://repo.joshgrancell.com/custom.ndb

cat rfxn.hdb > "$MALSCAN_DIRECTORY"/rfxn.hdb
cat rfxn.ndb > "$MALSCAN_DIRECTORY"/rfxn.ndb
cat custom.hdb > "$MALSCAN_DIRECTORY"/custom.hdb
cat custom.ndb > "$MALSCAN_DIRECTORY"/custom.ndb

if [[ -s "$MALSCAN_DIRECTORY/rfxn.hdb" && -s "$MALSCAN_DIRECTORY/rfxn.ndb" && -s "$MALSCAN_DIRECTORY/custom.ndb" && -s "$MALSCAN_DIRECTORY/custom.hdb" ]]; then
	echo -e "\033[32mUpdate: Malscan signatures updated successfully."
	MALSCAN_SUCCESS=1
else
	echo -e "\033[31mUpdate: Malscan signatures have failed to update correctly. Please try again later."
	MALSCAN_SUCCESS=0
fi

echo -e "\033[33mUpdate: Updating ClamAV definitions. This can take a long time."
"$FRESHCLAM_BINARY_LOCATION" >> /dev/null
echo -e "\033[32mUpdate: ClamAV malware definitions have been updated!\033[37m"

DATE=$(date)

echo "$DATE" >> "$MALSCAN_DIRECTORY"/log/update.log

rm -rf "$TEMP"

chown "$MALSCAN_USER":"$MALSCAN_USER" "$MALSCAN_DIRECTORY" -R

echo -e "\033[32mUpdate: Malscan full update complete.\033[37m"
exit 0
