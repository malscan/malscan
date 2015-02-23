#!/bin/bash
# Malscan - Enhanced ClamAV Scanning System 
# Written by Josh Grancell

VERSION="1.2.0"
DATE="Feb 23 2015"

MAINDIR="/usr/local/share/clamav"

LOGDIR="$MAINDIR/log"
DETECTIONLOG="$LOGDIR/detection.log"
QDIR="$MAINDIR/quarantine"
TEMPDIR=$(mktemp -d)
TEMPLOG="$TEMPDIR/malscan.log"
CLAMSCAN=$(which clamscan)

if [[ $# -lt "1" || "$1" == "-h" || "$1" == "--version" ]]; then
	echo "Malscan version $VERSION compiled on $DATE"
	echo "Usage: malscan [options] /path/to/scanned/directory"
	echo "       -q|--quarantine  -- Quarantine a file"
	echo "       -r|--report      -- Report a file."
	echo "       -h|--help        -- See this text"
	echo "       -v|--version     -- See version information"
	echo "Malscan is a robust file scanning toll that combines the"
	echo "ClamAV virus scanner with enhanced definition sets."
	exit 1
fi

if [[ "$1" == "-v" || "$1" == "--version" ]]; then
	echo "Malscan version $VERSION -- compiled on $DATE"
	exit 0
fi

if [[ "$1" == -q || "$1" == "--quarantine" ]]; then
	shift
	QUARANTINE=1
fi

if [[ "$1" == "-r"|| "$1" == "--report" ]]; then
	sigtool --md5 "$2" >> "$MAINDIR"/custom.hdb
fi

echo -ne "\033[31m"
"$CLAMSCAN" -d "$MAINDIR"/rfxn.hdb -d "$MAINDIR"/rfxn.ndb -d "$MAINDIR"/custom.hdb -d "$MAINDIR"/custom.ndb -i -r --no-summary --exclude='quarantine' "$1" | tee "$TEMPLOG"
echo -ne "\033[37m"

echo "$DATE" >> /usr/local/share/clamav/log/scan.log

if [[ -n "$QUARANTINE" ]]; then
	while read -r; do
		ABSPATH=$(readlink -f "$REPLY")
		DIR=$(dirname "$ABSPATH")
		FILE=$(basename "$ABSPATH")
		mkdir -p "$QDIR"/"$DIR"
		mv "$ABSPATH" "$QDIR""$ABSPATH"
		rsync -avzP "$QDIR"/ -e ssh /home/jgrancell/quarantine/"$HOSTNAME"/
		chmod 000 "$QDIR""$ABSPATH"
		echo -e "\033[36m$FILE quarantined in $QDIR"
	done < <(grep -v "globals" "$TEMPLOG" | cut -d: -f1)

	while read -r; do
		ABSPATH=$(readlink -f "$REPLY")
		DIR=$(dirname "$ABSPATH")
		FILE=$(basename "$ABSPATH")
		echo -e "\033[35m$FILE has been flagged as suspicious, but not quarantined." >> $DETECTIONLOG
	done < <(grep "globals" "$TEMPLOG" | cut -d: -f1)
fi

## Setting Up The Alert Email
if [ -f "$TEMPLOG" ]; then
	EMAIL_TMP=$(mktemp)
	{
	echo "To:jgrancell@campbellmarketing.com"
	echo "From:automated-malscan-service@campbellmarketing.services"
	echo "Subject: $HOSTNAME Malware Scanner Test 4"
	echo "MIME-Version: 1.0"
	echo "Content-Type: text/html; charset="us-ascii" "
	echo "Content-Disposition: inline"
	echo "<!DOCTYPE html>"
	echo "<html> <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"
	echo "<body>$(cat $TEMPLOG) </body></html>" 
	} >> $EMAIL_TMP



	sendmail -i -t < $EMAIL_TMP
fi

rm -rf "$TEMPLOG"

exit 0
