#!/bin/bash
# Malscan - Enhanced ClamAV Scanning System
# Written by Josh Grancell

VERSION="1.6.0"
DATE="November 16 2015"

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
LOGGING_DIRECTORY="$MALSCAN_DIRECTORY/log"

LOGGING_DATE=$(date +%F-%s)

####################
## DOING THE WORK ##
####################

## Parsing through the arguments
if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
	## Help functionality
	echo "Malscan version $VERSION compiled on $DATE"
	echo "Configuration options can be found in conf.malscan"
	echo "Usage: malscan [options] /path/to/scanned/directory"
	echo "       -h  -- Display this help text"
	echo "       -l  -- Checks files for lines over a certain length"
	echo "       -m  -- Checks the extension to verify it matches the MIME"
	echo "       -n  -- Send email notification."
	echo "       -q  -- Quarantine a file"
	echo "       -r  -- Report a file."
	echo "       -s  -- Scan the specified file or directory"
	echo "       -t  -- Runs a tripwire scan for any files that have been modified."
	echo "       -u  -- Updates all signatures and the core application"
	echo "       -v  -- Display version information"
	echo "       -w  -- Adds specified file tree to whitelist."
	echo "Malscan is a robust file scanning tool that combines the"
	echo "ClamAV virus scanner with enhanced definition sets."
	exit 1	
elif [[ $# == 1 ]]; then
	if [[ "$1" == "-v" ]]; then
		echo "Malscan version $VERSION -- last update $DATE"
		exit 0
	elif [[ "$1" = "-u" ]]; then
		UPDATER=1
	elif [[ -f "$1" || -d "$1" ]]; then
		AVSCAN=1
		TARGET="$1"
	else
		## Help functionality
		echo "Malscan version $VERSION compiled on $DATE"
		echo "Configuration options can be found in conf.malscan"
		echo "Usage: malscan [options] /path/to/scanned/directory"
		echo "       -h  -- Display this help text"
		echo "       -l  -- Checks files for lines over a certain length"
		echo "       -m  -- Checks the extension to verify it matches the MIME"
		echo "       -n  -- Send email notification."
		echo "       -q  -- Quarantine a file"
		echo "       -r  -- Report a file."
		echo "       -s  -- Scan the specified file or directory"
		echo "       -t  -- Runs a tripwire scan for any files that have been modified."
		echo "       -u  -- Updates all signatures and the core application"
		echo "       -v  -- Display version information"
		echo "       -w  -- Adds specified file tree to whitelist."
		echo "Malscan is a robust file scanning tool that combines the"
		echo "ClamAV virus scanner with enhanced definition sets."
		exit 1	
	fi
elif [[ $# -eq 2 ]]; then
	## Setting the scanning target
	TARGET="$2"

	## Enabling Update
	if [[ "$1" =~ u ]]; then
		UPDATER=1
	fi

	## Enabling Quarantine
	if [[ "$1" =~ q ]]; then
		QUARANTINE=1
	fi

	# Enabling mime-type scanning
	if [[ "$1" =~ m ]]; then
		MIMESCAN=1
	fi

	# Enabling line length scanning
	if [[ "$1" =~ l ]]; then
		LENGTHSCAN=1
	fi

	# Enabling signature reporting
	if [[ "$1" =~ r ]]; then
		REPORT=1
	fi

	# Enabling email notification
	if [[ "$1" =~ n ]]; then
		NOTIFICATION=1
	fi

	# Enabling full scan
	if [[ "$1" =~ s ]]; then
		AVSCAN=1
	fi

	# Enabling whitelisting
	if [[ "$1" =~ w ]]; then
		WHITELIST=1
	fi

	if [[ "$1" =~ t ]]; then
		TRIPWIRE=1
	fi

elif [[ -d "$1" || -f "$1" ]]; then
	AVSCAN=1
else
	## Help functionality
	echo "Malscan version $VERSION compiled on $DATE"
	echo "Configuration options can be found in conf.malscan"
	echo "Usage: malscan [options] /path/to/scanned/directory"
	echo "       -h  -- Display this help text"
	echo "       -l  -- Checks files for lines over a certain length"
	echo "       -m  -- Checks the extension to verify it matches the MIME"
	echo "       -n  -- Send email notification."
	echo "       -q  -- Quarantine a file"
	echo "       -r  -- Report a file."
	echo "       -s  -- Scan the specified file or directory"
	echo "       -t  -- Runs a tripwire scan for any files that have been modified."
	echo "       -u  -- Updates all signatures and the core application"
	echo "       -v  -- Display version information"
	echo "       -w  -- Adds specified file tree to whitelist."
	echo "Malscan is a robust file scanning tool that combines the"
	echo "ClamAV virus scanner with enhanced definition sets."
	exit 1	
fi

## Defining the update function
function updater {
	TEMPLOG=$(mktemp)
	UPDATELOG="$LOGGING_DIRECTORY"/"update-$(date +%F-%s)"

	touch "$UPDATELOG"

	echo -e "Update: Running core application update."

	STARTING_DIRECTORY=$(pwd)

	ORIGINAL_SHA256=$(sha256sum "$MALSCAN_DIRECTORY/malscan.sh" | awk '{print $1}')
	cd "$MALSCAN_DIRECTORY"
	git fetch --quiet >> /dev/null
	git pull origin master --quiet >> /dev/null

	NEW_MALSCAN_VERSION=$(grep "VERSION=" malscan.sh | cut -d \" -f2 | head -1)
	NEW_SHA256=$(sha256sum "$MALSCAN_DIRECTORY/malscan.sh" | awk '{print $1}')

	if [[ "$NEW_MALSCAN_VERSION" == "$VERSION" && "$NEW_SHA256" == "$ORIGINAL_SHA256" ]]; then
		echo -e "\033[32mUpdate: No Malscan application update required. Current version is $VERSION\033[37m"
	else
		echo -e "\033[32mUpdate: Core application updated. New Malscan version is $NEW_MALSCAN_VERSION\033[37m"
	fi

	echo ""

	./update.sh

	exit 0
}

## Defining the lengthscan function
function lengthscan {
	#Creating the logging directories
	LENGTHLOG="$LOGGING_DIRECTORY"/"scan-results-$LOGGING_DATE"
	TEMPLOG=$(mktemp)	

	# Building the whitelist
	LENGTH_IGNORE=${LENGTH_WHITELIST//,/ -not -name }

	echo -e "  * \033[33mString Length Scan: Beginning scan.\033[37m"
	echo -e "  - \033[37mString Length Scan: Searching for strings longer than $LENGTH_MINIMUM characters.\033[37m"

	while IFS= read -r FILE
	do
		SIZE=$(wc -L "$FILE" | awk '{$1}')
		if [[ "$SIZE" -ge "$LENGTH_MIMIMUM" ]]; then
			LENGTHSCAN_DETECTION=1
            echo -ne "\033[35m"
            echo "  - DETECTION: $FILE has been detected with a line length of $SIZE." | tee -a "$LENGTHLOG"
            echo -ne "\033[37m"
        fi
    done < <(find "$TARGET" -type f -not -name "$LENGTH_IGNORE" -print0)		

	# Checking to see if we have hits.
	if [[ -n "$LENGTHSCAN_DETECTION" ]]; then
		# Notifying of detections
		echo -e "  * \033[31mString Length Scan: Completed. See $LENGTHLOG for a full list of detected files.\033[37m"
		echo ""

		# If remote logging is enabled, reporting this to our remote SSH server
		if [[ "$REMOTE_LOGGING_ENABLED" == 1 ]]; then
			rsync -avzP "$REPORTFILE" -e ssh "$REMOTE_SSH:$REMOTE_LOGGING"/"$HOSTNAME"/
		fi

		DETECTION=1
	else
		# No detections
		echo -ne "\033[32m"
		echo "  * String Length Scan: Completed. No suspicious files detected." | tee -a "$LENGTHLOG"
		echo -ne "\033[37m"
		echo ""
		DETECTION=0
	fi
}

## Defining the whitelist function
function whitelist {
	# Identifying the whitelist.db
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

                # If remote logging is enabled, reporting this to our remote SSH server
                if [[ "$REMOTE_LOGGING_ENABLED" == 1 ]]; then
                        rsync -avzP "$TRIPWIRE_LOG" -e ssh "$REMOTE_SSH:$REMOTE_LOGGING"/"$HOSTNAME"/
                fi

                DETECTION=1
        else
                # No detections
                echo -ne "\033[32m"
                echo "  * Tripwire: Completed. No suspicious files detected." | tee -a "$TRIPWIRE_LOG"
                echo ""
                echo -ne "\033[37m"
                DETECTION=0
        fi


	rm "$TEMPLOG"
}

## Defining the mimescan function
function mimescan {
	# Creating the logging directories
	MIMELOG="$LOGGING_DIRECTORY"/"scan-results-$LOGGING_DATE"
	TEMPLOG=$(mktemp)

  	WHITELIST_FILE=(mktemp)
    echo "$MIME_WHITELIST" > "$WHITELIST_FILE"
    sed -i 's/,/ /g' "$WHITELIST_FILE"

    MIME_IGNORE_LIST=""

    for IGNORE in $(cat "$WHITELIST_FILE" ); do
            MIME_IGNORE_LIST="$MIME_IGNORE_LIST -not -name $IGNORE"
    done

    echo -e "  * \033[33mMIME Scan: Beginning scan.\033[37m"
    echo -e "  - MIME Scan: Compiling a full file list for $TARGET.\033[37m "
    find "$TARGET" $MIME_IGNORE_LIST -regextype posix-extended -regex '.*.(jpg|png|gif|swf|txt|pdf|js|css|html|htm|xml)' >>"$TEMPLOG"
    echo -e "  - MIME Scan: Searching file list for MIME mismatches.\033[37m "    


	# Working through the temporary file list to match files with mimetypes.
	while IFS= read -r FILE; do
        if file "$FILE" | egrep -q '(jpg|png|gif|swf|txt|pdf|js|css|html|htm|xml).*?(PHP)'; then
        	MIME_DETECTION=1
            echo -ne "\033[35m"
            echo "  - DETECTION: $FILE has been detected as a PHP file with a non-matching extension." | tee -a "$MIMELOG"
            echo -ne "\033[37m"
        fi
	done < <(cat "$TEMPLOG")

	# Checking to see if we have hits.
	if [[ -n "$MIME_DETECTION" ]]; then
		# Notifying of detections
		echo -e "  * \033[31mMIME Scan: Completed. See $MIMELOG for a full list of detected files.\033[37m"
		echo ""

		# If remote logging is enabled, reporting this to our remote SSH server
		if [[ "$REMOTE_LOGGING_ENABLED" == 1 ]]; then
			rsync -avzP "$REPORTFILE" -e ssh "$REMOTE_SSH:$REMOTE_LOGGING"/"$HOSTNAME"/
		fi

		DETECTION=1
	else
		# No detections
		echo -ne "\033[32m"
		echo  "  * MIME Scan: Completed. No suspicious files detected." | tee -a "$MIMELOG"
		echo -ne "\033[37m"
		echo ""
		DETECTION=0
	fi

	rm -f "$TEMPLOG"
	rm -f "$WHITELIST_FILE"
}

## Defining the scanning function
function avscan {

	echo -e "  * \033[33mMalware Scan: Beginning scan of $TARGET...\033[37m "

	# Setting up the whitelist
	AVSCAN_IGNORE=${AVSCAN_WHITELIST//,/ --exclude=}

	# Creating the scan log file for this scan
	SCANLOG="$LOGGING_DIRECTORY"/"scan-results-$LOGGING_DATE"
	DETECTLOG=$(mktemp)

	# Outputting the scanning information to stdout as well as the log file
	echo -ne "\033[31m"
	echo "--exclude=$AVSCAN_IGNORE" | xargs "$CLAMSCAN_BINARY_LOCATION" -d "$MALSCAN_DIRECTORY"/rfxn.hdb -d "$MALSCAN_DIRECTORY"/rfxn.ndb -d "$MALSCAN_DIRECTORY"/custom.hdb -d "$MALSCAN_DIRECTORY"/custom.ndb -d "$CLAMAV_DIRECTORY"/ -i -r --no-summary "$TARGET" >> "$DETECTLOG"
	echo -ne "\033[37m"

	## If no files were found, we will add a note into the scanlog accordingly.
	if [[ ! -s "$DETECTLOG" ]]; then
		echo -ne "\033[32m"
		echo "  * Malware Scan: Completed. No malicious files found." | tee -a "$SCANLOG"
		echo -ne "\033[37m"
		DETECTION=0
	else
		cat "$DETECTLOG" >> "$SCANLOG"

		while IFS= read -r FILE; do
            echo -ne "\033[31m"
            echo "  - DETECTION: $FILE "
		done < <(cat "$DETECTLOG")

		echo -e "  * \033[31mMalware Scan: Malicious files detected. See $SCANLOG for a full list of detected files.\033[37m"

	fi

	rm "$DETECTLOG"

}

## Defining the quarantine function
function quarantine {
	## This logic actively quarantines files that are not on our whitelist
	while read -r; do
		ABSPATH=$(readlink -f "$REPLY")
		
		## Setting the detection variable to 1, which allows us to parse the correct notification
		if [[ -f "$ABSPATH" ]]; then
			DETECTION=1
		fi
		
		# Building the file structure for quarantine
		DIR=$(dirname "$ABSPATH")
		FILE=$(basename "$ABSPATH")
		mkdir -p "$QUARANTINE_PATH"/"$DIR"
		mv "$ABSPATH" "$QUARANTINE_PATH""$ABSPATH"

		# If remote quarantine is set up, copying these files to the remote quarantine server
		if [[ "$REMOTE_QUARANTINE_ENABLED" == 1 ]]; then
			rsync -avzP "$QUARANTINE_PATH"/ -e ssh "$REMOTE_SSH:$REMOTE_QUARANTINE" >> /dev/null
		fi

		# Setting the files to 000 permissions so they cannot be accessed
		chmod 000 "$QUARANTINE_PATH""$ABSPATH"
		echo -e "  - \033[36m$FILE quarantined and locked down in $QUARANTINE_PATH.\033[37m" | tee -a "$LOGGING_DIRECTORY"/"scan-results-$LOGGING_DATE"
	done < <(cat "$SCANLOG" | cut -d: -f1)
}

function notification {
	if [[ "$DETECTION" == 1 ]]; then
		EMAIL_TMP=$(mktemp)
		{
		echo "To:$EMAIL"
		echo "From:$SENDER"
		echo "Subject: Malware Detections: $HOSTNAME - $(date)" 
		echo "MIME-Version: 1.0"
		echo "Content-Type: text/html; charset="us-ascii" "
		echo "Content-Disposition: inline"
		echo "<!DOCTYPE html>"
		echo "<html> <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"	
		echo "<body>"

		if [[ -n "$QUARANTINE" && -n "$AVSCAN" ]]; then
			echo "Malicious and/or suspicious files have been quarantined on $HOSTNAME. Please see $LOGGING_DIRECTORY/quarantine.log for further information.<br />"
		elif [[ -n "$AVSCAN" ]]; then
			echo "Malicious and/or suspicious files have been identified on $HOSTNAME but HAVE NOT been quarantined. Please see $SCANLOG for further information.<br />"
		fi

		if [[ -n "$MIMECHECK" ]]; then
			echo "PHP files have been detected on $HOSTNAME that are using suspicious file extension types. Please see $MIMELOG for additional information, and investigate each file for whitelisting or quarantining.<br />"
		fi

		if [[ -n "$LENGTHSCAN" ]]; then
			echo "Files have been detected that exceed the line length threshold, and may be suspicious. Please see $LENGTHLOG for additional information, and investigate each file for whitelisting or quarantining.<br />"
		fi
		} >> "$EMAIL_TMP"

		sendmail -i -t < "$EMAIL_TMP"	
	fi
}

function report {
	# Creating the report file name
	REPORTFILE="$LOGGING_DIRECTORY"/report-"$HOSTNAME"-$(date +%s).log

	# Generating the malware signature
	sigtool --md5 "$TARGET" >> "$REPORTFILE"

	# If remote logging is enabled, reporting this to our remote SSH server
	if [[ "$REMOTE_LOGGING_ENABLED" == 1 ]]; then
		rsync -avzP "$REPORTFILE" -e ssh "$REMOTE_SSH:$REMOTE_LOGGING"/"$HOSTNAME"/
	fi

	echo -e "\033[36mFile signatured generated and reported to the Malscan central repository for inclusion in the Malscan signature database.\033[37m"
	exit 0
}

echo -e "\033[34mMalscan Version: $VERSION | Signatures last updated: $(tail -1 $LOGGING_DIRECTORY/update.log)\033[37m"
echo ""

# Executing the Functions
if [[ -n "$REPORT" ]]; then
	report
fi

if [[ -n "$WHITELIST" ]]; then
	whitelist
fi

if [[ -n "$TRIPWIRE" ]]; then
	tripwire
fi

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

if [[ -n "$NOTIFICATION" ]]; then
	notification
fi

# Cleaning up by chowning everything to the clam user
chown -R "$MALSCAN_USER":"$MALSCAN_USER" "$MALSCAN_DIRECTORY"

exit 0
