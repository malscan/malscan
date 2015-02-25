#!/bin/bash
# Malscan - Enhanced ClamAV Scanning System
# Written by Josh Grancell

VERSION="1.3.1"
DATE="Feb 25 2015"

# Email Notification List
EMAIL="jgrancell@campbellmarketing.com"

# The local Malscan directory locations
MAINDIR="/var/lib/clamav"
LOGDIR="$MAINDIR/log"
QDIR="$MAINDIR/quarantine"

# The remote repository for signature reporting and quarantining -- this is in the format of an rsync call
REMOTE="jgrancell@192.168.25.20:/home/jgrancell/quarantine/$HOSTNAME/"

CLAMSCAN=$(which clamscan)

## Help!
if [[ $# -lt "1" || "$1" == "-h" || "$1" == "--help" ]]; then
	echo "Malscan version $VERSION compiled on $DATE"
	echo "Usage: malscan [-n|--notify] [options] /path/to/scanned/directory"
	echo "       -q|--quarantine  -- Quarantine a file"
	echo "       -m|--mime-check  -- Checks the extension to verify it matches the MIME"
	echo "       -r|--report      -- Report a file."
	echo "       -n|--notify      -- Send email notification. This flag cannot be used by itself, and must be followed by -r, -q, or -m."
	echo "       -h|--help        -- See this text"
	echo "       -v|--version     -- See version information"
	echo "Malscan is a robust file scanning toll that combines the"
	echo "ClamAV virus scanner with enhanced definition sets."
	exit 1
fi

## Version Information
if [[ "$1" == "-v" || "$1" == "--version" ]]; then
	echo "Malscan version $VERSION -- last update $DATE"
	exit 0
fi

## Email Notification Mode
if [[ "$1" == "-n" || "$1" == "--notify" ]]; then
	shift
	NOTIFY=1
fi

## Quarantine Mode
if [[ "$1" == "-q" || "$1" == "--quarantine" ]]; then
	shift
	QUARANTINE=1
fi

## MIME Type Matching Mode
if [[ "$1" == "-m" || "$1" == "--mime-check" ]]; then
	shift
	SCANLOG="$LOGDIR"/'mimecheck-'$(date +%F-%s)
	MIMECHECK=1
	TEMPLOG=$(mktemp)
	echo -n "Compiling a full list of potential files. "
	find "$1" -regextype posix-extended -regex '.*.(jpg|png|gif|swf|txt|pdf)' >>"$TEMPLOG"
	echo "Completed!"
	echo "Searching found files for any MIME mismatch against the given extensions."
	for FILE in $(cat "$TEMPLOG"); do
		if file "$FILE" | egrep -q '(jpg|png|gif|swf|txt|pdf).*?(PHP)'; then
			if  [ $(basename $FILE) != "license.txt" ]; then
				echo -e "\033[35mDETECTION: $FILE has been detected as a PHP file with a non-matching extension.\033[37m" | tee -a "$SCANLOG"
			fi
		fi
	done
	echo "See $SCANLOG for a full list of detected files."
fi

## Reporting Mode
if [[ "$1" == "-r"|| "$1" == "--report" ]]; then
	shift
	REPORT=1
	REPORTFILE="$LOGDIR"/report-"$HOSTNAME"-$(date +%s).log
	sigtool --md5 "$2" >> "$REPORTFILE"
	rsync -avzP "$REPORTFILE" -e ssh "$REMOTE"
	rm "$REPORTFILE"
	echo -e "\033[36mFile signatured generated and reported to Centauri for inclusion in the DB.\033[37m"
	exit 0
fi

## Running the actual scanning functionality.
if [[ -z "$REPORT" && -z "$MIMECHECK" ]]; then
	SCANLOG="$LOGDIR"/$(date +%F-%s)
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
			rsync -avzP "$QDIR"/ -e ssh "$REMOTE" >> /dev/null
			chmod 000 "$QDIR""$ABSPATH"
			echo -e "\033[36m$FILE quarantined and locked down in $QDIR and sent to Centauri.\033[37m" | tee -a "$LOGDIR"/quarantine.log
		done < <(grep -v "globals" "$SCANLOG" | cut -d: -f1)

		while read -r; do
			ABSPATH=$(readlink -f "$REPLY")
			DIR=$(dirname "$ABSPATH")
			FILE=$(basename "$ABSPATH")
			echo -e "\033[35m$FILE has been flagged as suspicious, but not quarantined.\033[37m" | tee -a "$LOGDIR"/quarantine.log
		done < <(grep -v "globals" "$SCANLOG" | cut -d: -f1)
	fi
fi

## Setting Up The Alert Email
if [ -s "$SCANLOG" -a -n "$NOTIFY" ]; then
	EMAIL_TMP=$(mktemp)
	{
	echo "To:$EMAIL"
	echo "From:automated-malscan-service@campbellmarketing.services"
	echo "Subject: Malware Detections: $HOSTNAME - $(date)" 
	echo "MIME-Version: 1.0"
	echo "Content-Type: text/html; charset="us-ascii" "
	echo "Content-Disposition: inline"
	echo "<!DOCTYPE html>"
	echo "<html> <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"	

	if [[ -n "$QUARANTINE" ]]; then
		echo "<body> Malicious and/or suspicious files have been quarantined on $HOSTNAME. Please see $LOGDIR/quarantine.log for further information. </body></html>"
	elif [[ -n "$MIMECHECK" ]]; then
		echo "<body> PHP files have been detected on $HOSTNAME that are using suspicious file extension types. Please see $SCANLOG for additional information, and investigate each file for whitelisting or quarantining. </body></html>"
	else
		echo "<body> Malicious and/or suspicious files have been identified on $HOSTNAME. Please see $SCANLOG for further information. </body></html>"
	fi
	} >> "$EMAIL_TMP"

	sendmail -i -t < "$EMAIL_TMP"
fi

exit 0

