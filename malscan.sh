#!/bin/bash
# -------------------------------------------------
#
# Package: Malscan
# Author: Josh Grancell <josh@joshgrancell.com>
# Description: Linux malware scanner for web servers
# Copyright: 2015-2016 Josh Grancell
# License: MIT License
# 
# -------------------------------------------------

VERSION="1.7.0-dev18"
DATE="June 08, 2016"

# -------------------------------------------------

## Loading the configuration file from the Malscan directory
source /etc/malscan.conf

## Setting up some default binary locations
FRESHCLAM_BINARY_LOCATION=$(which freshclam)
CLAMSCAN_BINARY_LOCATION=$(which clamscan)

## Setting up our logging information
LOGGING_DATE=$(date "+%F %H:%m")
TEMPLOG_DIRECTORY=$(mktemp -d)

## Getting the basic help information
function helper {

	## Help functionality
	echo -e "\033[34mMalscan version $VERSION released on $DATE\033[37m"
	echo "Usage: malscan [options] /path/to/scanned/directory"
	echo "       -c -- shows all configuration options and values"
	echo "       -s [option] [value] -- dupdates the value of a configuration option to a new value"
	echo "       -h  -- display this help text"
	echo "       -l  -- line scan mode"
	echo "       -m  -- MIME scan mode"
	echo "       -n  -- send email notification on detection"
	echo "       -q  -- quarantine any malicious files"
	#echo "       -s  -- basic malware scan"
	#echo "       -t  -- tripwire scan mode"
	echo "       -u  -- force-update of all signatures"
	echo "       -v  -- display core application and signature database version information"
	#echo "       -w  -- adds specified file tree to whitelist."
	echo "Use the command man malscan to view the manpage for more information."
	exit 0	

}

# -------------------------------------------------

## Checking to see if the user is running as root
if [[ "$EUID" != 0 ]]; then

	if ! whoami | id | grep -q "malscan"; then
		echo -e "\033[31mMalscan must be run as root, or by a user that is part of the malscan group.\033[37m"
		exit 1
	elif [[ $(whoami) == "malscan" ]]; then
		RUNNING_USER="malscan"
	else
		RUNNING_USER="non-root"
	fi
else 
	RUNNING_USER="root"
fi


# -------------------------------------------------

## Getting the total number of arguments that have been passed


## Parsing through the arguments
while getopts chlmn:qs::tuvw OPT; do
	case "$OPT" in
  		c) CONFIG=1;;
		h) HELP=1;;
		l) LENGTHSCAN=1;;
		m) MIMESCAN=1;;
		n) 
			NOTIFICATION=1
			NOTIFICATION_TARGET=$2
			;;
		q) QUARANTINE=1;;
		s) 
			SET_CONFIG=1
			SET_TARGET=$OPTARG
			SET_VALUE=$3
			;;
		t) TRIPWIRE=1;;
		u) UPDATER=1;;
		v) VERSION_SHOW=1;;
		w) WHITELIST=1;;
    	*) # getopts produces error
			helper
  	esac
done

# The easiest way to get rid of the processed options:
shift $((OPTIND-1))

# This will run all of the remaining arguments together with spaces between them:
TARGET="$1"

if [[ -f "$TARGET" || -d "$TARGET" ]]; then
	AVSCAN=1
fi

if [[ -n "$HELP" ]]; then
	helper
	exit 0
fi

## Defining the update function
function updater {

	if [[ $RUNNING_USER != "root" ]]; then
		echo ""
		echo -e "\033[31m  * Update: The updater is not able to update all signature databases while running as a non-root user."
		echo -e "\033[31m  * Update: Speak with your Systems Administrator to ensure updates are being run regularly by root.\033[37m"
	else

		cd "$TEMPLOG_DIRECTORY"
	
		echo ""
		echo -e "\033[37m  * Update: Downloading the latest Malscan malware definitions."
	
		wget -q https://www.rfxn.com/downloads/rfxn.hdb
		wget -q https://www.rfxn.com/downloads/rfxn.ndb
	
		SIGNATURE_CHANGE=0
	
		for DATABASE in rfxn.hdb rfxn.ndb; do
			NEWDB_COUNT=$(wc -l "$DATABASE" | awk '{print $1}')
	
			if [[ -f "$SIGNATURES_DIRECTORY/$DATABASE" ]]; then
				OLDDB_COUNT=$(wc -l "$SIGNATURES_DIRECTORY/$DATABASE" | awk '{print $1}')
			else
				OLDDB_COUNT=0
			fi
	
			if [[ "$NEWDB_COUNT" != "$OLDDB" ]]; then
				DIFFERENCE=$((NEWDB_COUNT - OLDDB_COUNT))
				SIGNATURE_CHANGE=$((SIGNATURE_CHANGE + DIFFERENCE))
			fi
		done
	
		cat rfxn.hdb > "$SIGNATURES_DIRECTORY/rfxn.hdb"
		cat rfxn.ndb > "$SIGNATURES_DIRECTORY/rfxn.ndb"
		chown malscan:malscan "$SIGNATURES_DIRECTORY/rfxn.hdb"
		chown malscan:malscan "$SIGNATURES_DIRECTORY/rfxn.ndb"	
	
		if [[ -s "$SIGNATURES_DIRECTORY/rfxn.hdb" && -s "$SIGNATURES_DIRECTORY/rfxn.ndb" ]]; then
	
			if [[ "$SIGNATURE_CHANGE" -gt 0 ]]; then
				echo -e "\033[32m  - Update: Malscan signatures updated. $SIGNATURE_CHANGE new signatures added to database.\033[37m"
			else
				echo -e "\033[32m  - Update: No new Malscan signatures avaiable.\033[37m"
			fi
	
		else
	
			echo -e "\033[31m  - Update: Malscan signatures have failed to update correctly. Please try again later."
	
		fi

		echo ""
		echo -e "\033[37m  - Update: Updating ClamAV definitions. This can take a long time."
		"$FRESHCLAM_BINARY_LOCATION" --datadir="$SIGNATURES_DIRECTORY" >> /dev/null 2>&1
		echo -e "\033[32m  - Update: ClamAV malware definitions have been updated.\033[37m"
		echo ""
	
	
		echo "$LOGGING_DATE - Update completed. $SIGNATURE_CHANGE malscan signatures added. ClamAV databases updated." >> "$LOGGING_DIRECTORY/update.log"
	
		rm -f "$TEMPLOG_DIRECTORY/rfxn*"
	
	
		echo -e "\033[32m  * Update: Malscan signatures updated.\033[37m"

	fi

	exit 0
}

## Defining the function that lets you view config options
function config_view {

	## Displaying all of our configuration options
	echo ""
	echo "Application Configuration Settings"
	echo "APPLICATION_DIRECTORY - $APPLICATION_DIRECTORY"
	echo "CONFIGURATION_FILE    - $CONFIGURATION_FILE"
	echo "SIGNATURES_DIRECTORY  - $SIGNATURES_DIRECTORY"
	echo "LOGGING_DIRECTORY     - $LOGGING_DIRECTORY"
	echo "QUARANTINE_DIRECTORY  - $QUARANTINE_DIRECTORY"
	echo ""
	echo "Notification Settings"
	echo "EMAIL_NOTIFICATIONS    - $EMAIL_NOTIFICATIONS"
	echo "NOTIFICATION_ADDRESSES - $NOTIFICATION_ADDRESSES"
	echo "MALSCAN_SENDER_ADDRESS - $MALSCAN_SENDER_ADDRESS"
	echo ""
	echo "Scanning Settings"
	echo "STRING_LENGTH_MINIMUM - $STRING_LENGTH_MINIMUM"

}

function config_set {

	if [[ "$SET_TARGET" != "" && "$SET_VALUE" != "" ]]; then

		sed -i "s|^$SET_TARGET.*$|$SET_TARGET=\"$SET_VALUE\"|m" "$CONFIGURATION_FILE"

		echo " * Configuration: $SET_TARGET has been updated to $SET_VALUE"

	else

		echo ""
		echo "  * Configuration: When setting a new configuration value, you must specify the config and the value."
		echo "  * Configuration: Example: malscan -s NOTIFICATION_ADDRESSES jgrancell@malscan.org,admin@malscan.org,jgrancell@joshgrancell.com"

	fi

}

## Defining the lengthscan function
function lengthscan {	

	# Building the whitelist - temporarily disabled
	## LENGTH_IGNORE=${LENGTH_WHITELIST//,/ -not -name }

	echo ""
	echo -e "  * \033[33mString Length Scan: Beginning scan.\033[37m"
	echo -e "  - \033[37mString Length Scan: Searching for strings longer than $LENGTH_MINIMUM characters.\033[37m"

	while IFS= read -r FILE
	do
		SIZE=$(wc -L "$FILE" | awk '{$1}')
		DETECTION_COUNT=0
		if [[ "$SIZE" -ge "$LENGTH_MIMIMUM" ]]; then
			LENGTHSCAN_DETECTION=1
            echo -ne "\033[35m"
            echo "  - DETECTION: $FILE has been detected with a line length of $SIZE." | tee -a "$LOGGING_DIRECTORY/detect-$LOGGING_DATE.log"
            echo -ne "\033[37m"

            DETECTION_COUNT="$DETECTION_COUNT"+1
        fi
    ##done < <(find "$TARGET" -type f -not -name "$LENGTH_IGNORE" -print0)		
	done < <(find "$TARGET" -type f -print0)		

	# Checking to see if we have hits.
	if [[ -n "$LENGTHSCAN_DETECTION" ]]; then
		# Notifying of detections
		echo -e "  * \033[31mString Length Scan: Completed. See $LOGGING_DIRECTORY/detection-$LOGGING_DATE.log for a full list of detected files.\033[37m"
		echo ""

		DETECTION_STRING=1
	else
		# No detections
		echo -ne "\033[32m"
		echo "  * String Length Scan: Completed. No suspicious files detected."
		echo -ne "\033[37m"
		echo ""
		DETECTION_STRING=0
	fi

	if [[ "$DETECTION_STRING" == 1 ]]; then

		echo "$LOGGING_DATE - String Scan - $DETECTION_COUNT suspcicious files detected. See $LOGGING_DIRECTORY/detection-$LOGGING_DATE.log for more information." >> "$LOGGING_DIRECTORY/scan.log"

	else 

		echo "$LOGGING_DATE - String Scan - No suspcious files detected." >> "$LOGGING_DIRECTORY/scan.log"

	fi
}

## Defining the whitelist function
function whitelist {
	# Identifying the whitelist.db
	echo ""
	WHITELIST_DB="$MALSCAN_DIRECTORY/whitelist.db"
	TEMPLOG=$(mktemp)	
	echo -e "\033[33mWhitelist: Beginning whitelist process.\033[37m"
	echo "Whitelist: Generating file list."
	find "$TARGET" -type f >> "$TEMPLOG"
	echo "Whitelist: Creating file whitelist signatures."

	while IFS= read -r FILE; do
		SHA256=$(sha256sum "$FILE" | awk '{print $1}')
		if grep -qs "$FILE:" "$WHITELIST_DB"; then
			OLDHASH=$(grep "$FILE:" "$WHITELIST_DB" | cut -d: -f2)
			HASH_LINE=$(grep -nr "$FILE:" "$WHITELIST_DB" | cut -d: -f1)

			if [[ "$OLDHASH" != "$SHA256" ]]; then
				echo -e "\033[35mWhitelist: The file at $FILE has been previously whitelisted, however the signature has changed.\033[37m"
				echo -ne "\033[35mWhitelist: Would you like to overwrite the previous signature? [y/N] \033[37m"
				read -u 3 OVERWRITE

				if [[ "$OVERWRITE" == "y" || "$OVERWRITE" == "Y" || "$OVERWRITE" == "yes" ]]; then
					sed -i "${HASH_LINE}s/$OLDHASH/$SHA256/" "$WHITELIST_DB"
					echo -e "\033[32mWhitelist: Sgnature updated for $FILE\033[37m"
				else
					echo -e "\033[31mWhitelist: New signature skipped. The old signature has been retained. Please investigate this file change.\033[37m"
				fi
			fi

		else		
			echo "$FILE:$SHA256" >> "$WHITELIST_DB"
		fi
			
	done 3<&0 <"$TEMPLOG"
	
	rm "$TEMPLOG"

	echo -e "\033[32mWhitelist: Complete.\033[37m"
}

function tripwire {
	WHITELIST_DB="$MALSCAN_DIRECTORY/whitelist.db"
	TEMPLOG=$(mktemp)
	TRIPWIRE_LOG="$LOGGING_DIRECTORY/scan-results-$LOGGING_DATE"

	echo ""
	echo -e "  * \033[33mTripwire: Beginning scan.\033[37m"
	echo "  - Tripwire: Compiling a full file list for $TARGET."
	find "$TARGET" -type f >> "$TEMPLOG"
	echo "  - Tripwire: Identifying any changed files."

	while IFS= read -r FILE; do
		if grep -qs "$FILE:" "$WHITELIST_DB"; then
			WHITELISTED_HASH=$(grep "$FILE:" "$WHITELIST_DB" | cut -d: -f2)
			CURRENT_HASH=$(sha256sum "$FILE"| awk '{print $1}')

			if [[ "$WHITELISTED_HASH" != "$CURRENT_HASH" ]]; then
				TRIPWIRE_DETECTION=1
				echo -ne "\033[35m"
				echo -n "  - DETECTION: $FILE has been modified since being whitelisted." | tee -a "$TRIPWIRE_LOG"
				echo -e "\033[37m"
			fi
		else
			TRIPWIRE_DETECTION=1
			echo -ne "\033[35m"
			echo -n "  - DETECTION: $FILE is not found in the whitelist, and may be newly created." | tee -a "$TRIPWIRE_LOG"
			echo -e "\033[37m"	
		fi
	done 3<&0 <"$TEMPLOG"

        # Checking to see if we have hits.
        if [[ -n "$TRIPWIRE_DETECTION" ]]; then
                # Notifying of detections
                echo -e "  * \033[31mTripwire: Completed. See $TRIPWIRE_LOG for a full list of detected files.\033[37m"
                echo ""

                DETECTION=1
        else
                # No detections
                echo -ne "\033[32m"
                echo "  * Tripwire: Completed. No suspicious files detected." | tee -a "$TRIPWIRE_LOG"
                echo ""
                echo -ne "\033[37m"
        fi


	rm "$TEMPLOG"
}

## Defining the mimescan function
function mimescan {
	# Creating the logging directories

  	#WHITELIST_FILE=(mktemp)
    #echo "$MIME_WHITELIST" > "$WHITELIST_FILE"
    #sed -i 's/,/ /g' "$WHITELIST_FILE"

    #MIME_IGNORE_LIST=""

    #for IGNORE in $(cat "$WHITELIST_FILE" ); do
    #        MIME_IGNORE_LIST="$MIME_IGNORE_LIST -not -name $IGNORE"
    #done

    echo ""
    echo -e "  * \033[33mMIME Scan: Beginning scan.\033[37m"
    echo -e "  - MIME Scan: Compiling a full file list for $TARGET.\033[37m "
    # find "$TARGET" $MIME_IGNORE_LIST -regextype posix-extended -regex '.*.(jpg|png|gif|swf|txt|pdf|js|css|html|htm|xml)' >>"$TEMPLOG"
    find "$TARGET" -regextype posix-extended -regex '.*.(jpg|png|gif|swf|txt|pdf|js|css|html|htm|xml)' >>"$TEMPLOG_DIRECTORY/mime.log"
    echo -e "  - MIME Scan: Searching file list for MIME mismatches.\033[37m "    

    DETECTION_COUNT=0

	# Working through the temporary file list to match files with mimetypes.
	while IFS= read -r FILE; do
        if file "$FILE" | egrep -q '(jpg|png|gif|swf|txt|pdf|js|css|html|htm|xml).*?(PHP)'; then
        	MIME_DETECTION=1
            echo -ne "\033[35m"
            echo "  - DETECTION: $FILE has been detected as a PHP file with a non-matching extension." | tee -a "$LOGGING_DIRECTORY/detection-$LOGGING_DATE.log"
            echo -ne "\033[37m"
            DETECTION_COUNT=$DETECTION_COUNT+1
        fi
	done < <(cat "$TEMPLOG_DIRECTORY/mime.log")

	# Checking to see if we have hits.
	if [[ -n "$MIME_DETECTION" ]]; then
		# Notifying of detections
		echo -e "  * \033[31mMIME Scan: Completed. See $MIMELOG for a full list of detected files.\033[37m"
		echo ""

		DETECTION_MIME=1
	else
		# No detections
		echo -ne "\033[32m"
		echo  "  * MIME Scan: Completed. No suspicious files detected."
		echo -ne "\033[37m"
		echo ""
		DETECTION_MIME=0
	fi

	if [[ "$DETECTION_MIME" == 1 ]]; then

		echo "$LOGGING_DATE - MIME Scan - $DETECTION_COUNT suspcicious files detected. See $LOGGING_DIRECTORY/detection-$LOGGING_DATE.log for more information." >> "$LOGGING_DIRECTORY/scan.log"

	else

		echo "$LOGGING_DATE - MIME Scan - No suspcious files detected." >> "$LOGGING_DIRECTORY/scan.log"

	fi

	#rm -f "$WHITELIST_FILE"
}

## Defining the scanning function
function avscan {

	echo ""
	echo -e "  \033[33m* Malware Scan: Beginning scan of $TARGET...\033[37m "

	# Setting up the whitelist
	#AVSCAN_IGNORE=${AVSCAN_WHITELIST//,/ --exclude=}

	# Creating the scan log file for this scan
	AV_DETECTION_TEMPLOG="$TEMPLOG_DIRECTORY/avscan.log"

	# Outputting the scanning information to stdout as well as the log file
	echo -ne "\033[31m"
	# echo "--exclude=$AVSCAN_IGNORE" | xargs "$CLAMSCAN_BINARY_LOCATION" -d "$SIGNATURES_DIRECTORY"/ -i -r --no-summary "$TARGET" >> "$AV_DETECTION_TEMPLOG"
	echo "" | xargs "$CLAMSCAN_BINARY_LOCATION" -d "$SIGNATURES_DIRECTORY"/ -i -r --no-summary "$TARGET" >> "$AV_DETECTION_TEMPLOG"
	echo -ne "\033[37m"

	DETECTION_COUNT=0

	## If no files were found, we will add a note into the scanlog accordingly.
	if [[ ! -s "$AV_DETECTION_TEMPLOG" ]]; then
		echo -ne "\033[32m"
		echo "  * Malware Scan: Completed. No malicious files found."
		echo -ne "\033[37m"
		DETECTION_AV=0
	else
		cat "$AV_DETECTION_TEMPLOG" >> "$LOGGING_DIRECTORY/detection-$LOGGING_DATE.log"

		while IFS= read -r FILE; do
            echo -ne "\033[31m"
            echo "  - DETECTION: $FILE "
		done < <(cat "$AV_DETECTION_TEMPLOG")
		DETECTION_AV=1
		DETECTION_COUNT="$DETECTION_COUNT"+1

		echo -e "  * \033[31mMalware Scan: $DETECTION_COUNT malicious files detected. See $LOGGING_DIRECTORY/detection-$LOGGING_DATE.log for a full list of detected files.\033[37m"

	fi

	if [[ "$DETECTION_AV" == 1 ]]; then

		echo "$LOGGING_DATE - Malware Scan - $DETECTION_COUNT malicious files detected. See $LOGGING_DIRECTORY/detection-$LOGGING_DATE.log for more information." >> "$LOGGING_DIRECTORY/scan.log"

	else

		echo "$LOGGING_DATE - Malware Scan - No malicious files detected." >> "$LOGGING_DIRECTORY/scan.log"

	fi

}

## Defining the quarantine function
function quarantine {
	## This logic actively quarantines files that are not on our whitelist

	QUARANTINE_COUNT=0
	while read -r; do
		ABSPATH=$(readlink -f "$REPLY")
		
		## Setting the detection variable to 1, which allows us to parse the correct notification
		if [[ -f "$ABSPATH" ]]; then
			QUARANTINE_COUNT="$QUARANTINE_COUNT"+1
		fi
		
		# Building the file structure for quarantine
		DIR=$(dirname "$ABSPATH")
		FILE=$(basename "$ABSPATH")
		mkdir -p "$QUARANTINE_DIRECTORY/$LOGGING_DATE/$DIR"
		mv "$ABSPATH" "$QUARANTINE_DIRECTORY/$LOGGING_DATE/$ABSPATH"

		# Setting the files to 000 permissions so they cannot be accessed
		chmod 600 "$QUARANTINE_PATH""$ABSPATH"
		echo -e "  - \033[36m$FILE quarantined and locked down in $QUARANTINE_DIRECTORY/$LOGGING_DATE.\033[37m" | tee -a "$LOGGING_DIRECTORY/quarantine-$LOGGING_DATE"
	done < <("$AV_DETECTION_TEMPLOG" | cut -d: -f1)

	echo "$LOGGING_DATE - Quarantine - $QUARANTINE_COUNT malicious files quarantined. See $LOGGING_DIRECTORY/quarantine-$LOGGING_DATE.log for Quarantine information, and $LOGGING_DIRECTORY/detection-$LOGGING_DATE.log for malware detection information." >> "$LOGGING_DIRECTORY/scan.log"
}

function notification {
	if [[ "$DETECTION_STRING" == 1 || "$DETECTION_MIME" = 1 || "$DETECTION_AV" == 1 ]]; then

		EMAIL_TMP="$TEMPLOG_DIRECTORY/email.tmp"
		{
		echo "To:$NOTIFICATION_ADDRESSES"
		echo "From:$MALSCAN_SENDER_ADDRESS"
		echo "Subject: Malware Detection: $HOSTNAME - $(date)" 
		echo "MIME-Version: 1.0"
		echo "Content-Type: text/html; charset=us-ascii"
		echo "Content-Disposition: inline"
		echo "<!DOCTYPE html>"
		echo "<html> <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"	
		echo "<body>"

		if [[ -n "$QUARANTINE" && -n "$AVSCAN" ]]; then
			echo "Malicious and/or suspicious files have been quarantined on $HOSTNAME. Please see $LOGGING_DIRECTORY/quarantine-$LOGGING_DATE.log and $LOGGING_DIRECTORY/detection-$LOGGING_DATE.log for further information.<br />"
		elif [[ -n "$AVSCAN" ]]; then
			echo "Malicious and/or suspicious files have been identified on $HOSTNAME but HAVE NOT been quarantined.<br />"
			echo "<br />"
			echo "The detected malicious or suspicious files are:<br />"

			while IFS='' read -r line || [[ -n "$line" ]]; do
				echo "$line <br />"
			done < "$AV_DETECTION_TEMPLOG"

			echo "<br />"
			echo "Please see $LOGGING_DIRECTORY/detection-$LOGGING_DATE.log for any additional details.<br />"
		fi

		if [[ -n "$MIMECHECK" ]]; then
			echo "Files have been detected on $HOSTNAME that are using suspicious file extension types. Please see $LOGGING_DIRECTORY/detection-$LOGGING_DATE.log for additional information, and investigate each file for whitelisting or quarantining.<br />"
		fi

		if [[ -n "$LENGTHSCAN" ]]; then
			echo "Files have been detected that exceed the line length threshold, and may be suspicious. Please see $LOGGING_DIRECTORY/detection-$LOGGING_DATE.log for additional information, and investigate each file for whitelisting or quarantining.<br />"
		fi
		} >> "$EMAIL_TMP"

		sendmail -f "Malscan AntiMalware Scanner" -f "$MALSCAN_SENDER_ADDRESS" -i -t < "$EMAIL_TMP"

		echo ""
		echo -e "  \033[33m* Notification: Successfully sent notification to $NOTIFICATION_ADDRESSES\033[37m"
		echo ""
	fi
}

#function report {
#	# Creating the report file name
#	REPORTFILE="$LOGGING_DIRECTORY"/report-"$HOSTNAME"-$(date +%s).log

	# Generating the malware signature
#	sigtool --md5 "$TARGET" >> "$REPORTFILE"

	# If remote logging is enabled, reporting this to our remote SSH server
#	if [[ "$REMOTE_LOGGING_ENABLED" == 1 ]]; then
#		rsync -avzP "$REPORTFILE" -e ssh "$REMOTE_SSH:$REMOTE_LOGGING"/"$HOSTNAME"/
#	fi

#	echo -e "\033[36mFile signatured generated and reported to the Malscan central repository for inclusion in the Malscan signature database.\033[37m"
#	exit 0
#}

# -------------------------------------------------

## Checking to see when the last update was
if [[ -f "$LOGGING_DIRECTORY/update.log" ]]; then
	LAST_UPDATE_TIME=$(tail -1 "$LOGGING_DIRECTORY"/update.log | awk '{print $1 " " $2}')
else
	LAST_UPDATE_TIME="Never"
fi

echo -e "\033[34mMalscan Version: $VERSION | Signatures last updated: $LAST_UPDATE_TIME\033[37m"

if [[ -n "$VERSION_SHOW" ]]; then
	exit 0
fi

if [[ -n "$CONFIG" ]]; then
	config_view
	exit 0
fi

if [[ -n "$SET_CONFIG" ]]; then
	config_set
	exit 0
fi

#if [[ -n "$REPORT" ]]; then
#	report
#fi

#if [[ -n "$WHITELIST" ]]; then
#	whitelist
#fi
#
#if [[ -n "$TRIPWIRE" ]]; then
#	tripwire
#fi

if [[ -n "$MIMESCAN" ]]; then
	mimescan
fi

if [[ -n "$LENGTHSCAN" ]]; then
	lengthscan
fi

if [[ -n "$AVSCAN" ]]; then
	avscan
	if [[ -n "$QUARANTINE" ]]; then
		quarantine
	fi
fi

if [[ -n "$UPDATER" ]]; then
	updater
fi

if [[ -n "$NOTIFICATION" && -n "$DETECTION" ]]; then
	notification
fi

# -------------------------------------------------

## Removing our temp logging directory
rm -rf "$TEMPLOG_DIRECTORY"

echo ""

exit 0
