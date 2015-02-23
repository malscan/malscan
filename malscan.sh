#!/bin/bash
# Malscan - Enhanced ClamAV Scanning System 
# Written by Josh Grancell

VERSION="1.2.1"
DATE="Feb 23 2015"

MAINDIR="/var/lib/clamav"
LOGDIR="$MAINDIR/log"
QDIR="$MAINDIR/quarantine"

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

SCANLOG=$LOGDIR/$(date +%F-%s)

echo -ne "\033[31m"
"$CLAMSCAN" -d "$MAINDIR"/rfxn.hdb -d "$MAINDIR"/rfxn.ndb -d "$MAINDIR"/custom.hdb -d "$MAINDIR"/custom.ndb -i -r --no-summary --exclude='quarantine' "$1" | tee "$SCANLOG"
echo -ne "\033[37m"

if [[ -n "$QUARANTINE" ]]; then
	while read -r; do
		ABSPATH=$(readlink -f "$REPLY")
		DIR=$(dirname "$ABSPATH")
		FILE=$(basename "$ABSPATH")
		mkdir -p "$QDIR"/"$DIR"
		mv "$ABSPATH" "$QDIR""$ABSPATH"
		rsync -avzP "$QDIR"/ -e ssh /home/jgrancell/quarantine/"$HOSTNAME"/
		chmod 000 "$QDIR""$ABSPATH"
		echo -e "\033[36m$FILE quarantined in $QDIR" >> $LOGDIR/quarantine.log
	done < <(grep -v "globals" "$SCANLOG" | cut -d: -f1)

	while read -r; do
		ABSPATH=$(readlink -f "$REPLY")
		DIR=$(dirname "$ABSPATH")
		FILE=$(basename "$ABSPATH")
		echo -e "\033[35m$FILE has been flagged as suspicious, but not quarantined." >> $LOGDIR/quarantine.log
	done < <(grep "globals" "$SCANLOG" | cut -d: -f1)
fi

## Setting Up The Alert Email
if [ -s "$SCANLOG" ]; then
	EMAIL_TMP=$(mktemp)
	{
	echo "To:jgrancell@campbellmarketing.com"
	echo "From:automated-malscan-service@campbellmarketing.services"
	echo "Subject: Malware Detections: $HOSTNAME - $(date)" 
	echo "MIME-Version: 1.0"
	echo "Content-Type: text/html; charset="us-ascii" "
	echo "Content-Disposition: inline"
	echo "<!DOCTYPE html>"
	echo "<html> <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"	
	echo "<body> Malicious and/or suspicious files have been identified on $HOSTNAME. Please see $SCANLOG for further information. </body></html>"
	} >> "$EMAIL_TMP"

	sendmail -i -t < "$EMAIL_TMP"
fi

exit 0
