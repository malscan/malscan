#!/bin/bash
# Malscan - Enhanced ClamAV Scanning System
# Written by Josh Grancell

VERSION="1.5.0"
DATE="June 01 2015"

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

####################
## DOING THE WORK ##
####################

## Parsing through the arguments
if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
	## Help functionality
	echo "Malscan version $VERSION compiled on $DATE"
	echo "Configuration options can be found in conf.malscan"
	echo "Usage: malscan [options] /path/to/scanned/directory"
	echo "       -s  -- Scan the specified file or directory"
	echo "       -q  -- Quarantine a file"
	echo "       -m  -- Checks the extension to verify it matches the MIME"
	echo "       -l  -- Checks files for lines over a certain length"
	echo "       -r  -- Report a file."
	echo "       -n  -- Send email notification."
	echo "       -h  -- Display this help text"
	echo "       -v  -- Display version information"
	echo "       -w  -- Adds specified file tree to whitelist."
	echo "       -t  -- Runs a tripwire scan for any files that have been modified."
	echo "Malscan is a robust file scanning toll that combines the"
	echo "ClamAV virus scanner with enhanced definition sets."
	exit 1	
elif [[ $# == 1 ]]; then
	if [[ "$1" == "-v" ]]; then
		echo "Malscan version $VERSION -- last update $DATE"
		exit 0
	elif [[ -f "$1" || -d "$1" ]]; then
		AVSCAN=1
		TARGET="$1"
	else
		## Help functionality
	        echo "Malscan version $VERSION compiled on $DATE"
	        echo "Configuration options can be found in conf.malscan"
	        echo "Usage: malscan [options] /path/to/scanned/directory"
	        echo "       -s  -- Scan the specified file or directory"
	        echo "       -q  -- Quarantine a file"
	        echo "       -m  -- Checks the extension to verify it matches the MIME"
	        echo "       -l  -- Checks files for lines over a certain length"
	        echo "       -r  -- Report a file."
	        echo "       -n  -- Send email notification."
	        echo "       -h  -- Display this help text"
	        echo "       -v  -- Display version information"
	        echo "       -w  -- Adds specified file tree to whitelist."
		echo "       -t  -- Runs a tripwire scan for any files that have been modified."
	        echo "Malscan is a robust file scanning toll that combines the"
	        echo "ClamAV virus scanner with enhanced definition sets."
		exit 1	
	fi
elif [[ $# -eq 2 ]]; then
	## Setting the scanning target
	TARGET="$2"

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
	echo "Usage: malscan [options] /path/to/scanned/directory"
	echo "       -q|--quarantine  -- Quarantine a file"
	echo "       -m|--mime-check  -- Checks the extension to verify it matches the MIME"
	echo "       -l|--line-length -- Checks files for lines over a certain length"
	echo "       -r|--report      -- Report a file."
	echo "       -n|--notify      -- Send email notification. This flag cannot be used by itself, and must be followed by -r, -q, or -m."
	echo "       -h|--help        -- See this text"
	echo "       -v|--version     -- See version information"
	echo "Malscan is a robust file scanning toll that combines the"
	echo "ClamAV virus scanner with enhanced definition sets."
	exit 1
fi

## Defining the lengthscan function
function lengthscan {
	#Creating the logging directories
	LENGTHLOG="$LOGGING_DIRECTORY"/"length-scan-$(date +%F-%s)"
	TEMPLOG=$(mktemp)	

	# Building the whitelist
	LENGTH_IGNORE=${LENGTH_WHITELIST//,/ -not -name }

	echo -e "\033[33mScanning $TARGET for files with strings longer than $LENGTH_MINIMUM characters... \033[37m"

	while IFS= read -r FILE
	do
		SIZE=$(wc -L "$FILE" | awk '{$1}')
		if [[ "$SIZE" -ge "$LENGTH_MIMIMUM" ]]; then
            echo -ne "\033[35m"
            echo "DETECTION: $FILE has been detected with a line length of $SIZE." | tee -a "$LENGTHLOG"
            echo -ne "\033[37m"
        fi
    done < <(find "$TARGET" -type f -not -name "$LENGTH_IGNORE" -print0)		

	# Checking to see if we have hits.
	if [[ -f "$LENGTHLOG" ]]; then
		# Notifying of detections
		echo -e "\033[31mSee $LENGTHLOG for a full list of detected files.\033[37m"

		# If remote logging is enabled, reporting this to our remote SSH server
		if [[ "$REMOTE_LOGGING_ENABLED" == 1 ]]; then
			rsync -avzP "$REPORTFILE" -e ssh "$REMOTE_SSH:$REMOTE_LOGGING"/"$HOSTNAME"/
		fi

		DETECTION=1
	else
		# No detections
		echo -ne "\033[32m"
		echo "No suspicious files detected." | tee -a "$LENGTHLOG"
		echo -ne "\033[37m"
		DETECTION=0
	fi
}

## Defining the whitelist function
function whitelist {
	# Identifying the whitelist.db
	WHITELIST_DB="$MALSCAN_DIRECTORY/whitelist.db"
	TEMPLOG=$(mktemp)	

	echo -e "\033[33mGenerating a list of files to whitelist."
	find "$TARGET" -type f >> "$TEMPLOG"
	echo -e "Creating file whitelist signatures...\033[32m"

	while IFS= read -r FILE; do
		SHA256=$(sha256sum "$FILE" | awk '{print $1}')
		if grep -qs "$FILE:" "$WHITELIST_DB"; then
			OLDHASH=$(grep "$FILE:" "$WHITELIST_DB" | cut -d: -f2)
			HASH_LINE=$(grep -nr "$FILE:" "$WHITELIST_DB")

			if [[ "$OLDHASH" != "$SHA256" ]]; then
				echo -e "\033[33mThe file at $FILE has been previously whitelisted, however the signature has changed."
				echo -ne "Would you like to overwrite the previous signature? [y/N] \033[37m"
				read -u 3 OVERWRITE

				if [[ "$OVERWRITE" == "y" || "$OVERWRITE" == "Y" || "$OVERWRITE" == "yes" ]]; then
					sed -i "${HASH_LINE}s/$OLDHASH/$NEWHASH/" "$WHITELIST_DB"
					echo -e "\033[32mWhitelist signature updated for $FILE\033[37m"
				else
					echo -e "\033[31mNew signature skipped. The old signature has been retained. Please investigate this file change.\033[37m"
				fi
			fi

		else		
			echo "$FILE:$SHA256" >> "$WHITELIST_DB"
		fi
			
	done 3<&0 <"$TEMPLOG"
	
	rm "$TEMPLOG"

	echo -e "Whitelist updated completed!\033[37m"
}

function tripwire {
	WHITELIST_DB="$MALSCAN_DIRECTORY/whitelist.db"
	TEMPLOG=$(mktemp)
	TRIPWIRE_LOG="$LOGGING_DIRECTORY/tripwire-$(date +%F-%s)"

	echo -e "\033[33mCompiling list of all files."
	find "$TARGET" -type f >> "$TEMPLOG"
	echo -e "Identifying any changed files...\033[37m"

	while IFS= read -r FILE; do
		if grep -qs "$FILE:" "$WHITELIST_DB"; then
			WHITELISTED_HASH=$(grep "$FILE:" "$WHITELIST_DB" | cut -d: -f2)
			CURRENT_HASH=$(sha256sum "$FILE"| awk '{print $1}')

			if [[ "$WHITELISTED_HASH" != "$CURRENT_HASH" ]]; then
				echo -ne "\033[35m"
				echo -n "DETECTION: $FILE has been modified since being whitelisted." | tee -a "$TRIPWIRE_LOG"
				echo -e "\033[37m"
			fi
		else
			echo -ne "\033[35m"
			echo -n "DETECTION: $FILE is not found in the whitelist, and may be newly created." | tee -a "$TRIPWIRE_LOG"
			echo -e "\033[37m"	
		fi
	done 3<&0 <"$TEMPLOG"

        # Checking to see if we have hits.
        if [[ -f "$TRIPWIRE_LOG" ]]; then
                # Notifying of detections
                echo -e "\033[31mSee $TRIPWIRE_LOG for a full list of detected files.\033[37m"

                # If remote logging is enabled, reporting this to our remote SSH server
                if [[ "$REMOTE_LOGGING_ENABLED" == 1 ]]; then
                        rsync -avzP "$TRIPWIRE_LOG" -e ssh "$REMOTE_SSH:$REMOTE_LOGGING"/"$HOSTNAME"/
                fi

                DETECTION=1
        else
                # No detections
                echo -ne "\033[32m"
                echo "No suspicious files detected." | tee -a "$TRIPWIRE_LOG"
                echo -ne "\033[37m"
                DETECTION=0
        fi


	rm "$TEMPLOG"
	echo "Scan completed."
}

## Defining the mimescan function
function mimescan {
	# Creating the logging directories
	MIMELOG="$LOGGING_DIRECTORY"/"mimecheck-$(date +%F-%s)"
	TEMPLOG=$(mktemp)

	# SEDing the whitelist into something we can use with find
	MIME_IGNORE=${MIME_WHITELIST//,/ -not -name }

	echo -ne "\033[33mCompiling a full list of potential files...\033[37m "
	find "$TARGET" -not -name "$MIME_IGNORE" -regextype posix-extended -regex '.*.(jpg|png|gif|swf|txt|pdf|js|css|html|htm|xml)' >>"$TEMPLOG"
	echo -e "\033[32mCompleted!\033[37m"
	echo -e "\033[33mSearching found files for any MIME mismatch against the given extensions.\033[37m "

	# Working through the temporary file list to match files with mimetypes.
	while IFS= read -r FILE; do
        if file "$FILE" | egrep -q '(jpg|png|gif|swf|txt|pdf|js|css|html|htm|xml).*?(PHP)'; then
            echo -ne "\033[35m"
            echo "DETECTION: $FILE has been detected as a PHP file with a non-matching extension." | tee -a "$MIMELOG"
            echo -ne "\033[37m"
        fi
	done < <(cat "$TEMPLOG")

	# Checking to see if we have hits.
	if [[ -f "$MIMELOG" ]]; then
		# Notifying of detections
		echo -e "\033[31mSee $MIMELOG for a full list of detected files.\033[37m"

		# If remote logging is enabled, reporting this to our remote SSH server
		if [[ "$REMOTE_LOGGING_ENABLED" == 1 ]]; then
			rsync -avzP "$REPORTFILE" -e ssh "$REMOTE_SSH:$REMOTE_LOGGING"/"$HOSTNAME"/
		fi

		DETECTION=1
	else
		# No detections
		echo -ne "\033[32m"
		echo  "No suspicious files detected." | tee -a "$MIMELOG"
		echo -ne "\033[37m"
		DETECTION=0
	fi

	rm -f "$TEMPLOG"
}

## Defining the scanning function
function avscan {

	echo -ne "\033[33mBeginning malware scan of $TARGET...\033[37m "

	# Setting up the whitelist
	AVSCAN_IGNORE=${AVSCAN_WHITELIST//,/ --exclude=}

	# Creating the scan log file for this scan
	SCANLOG="$LOGGING_DIRECTORY"/$(date +%F-%s)

	# Outputting the scanning information to stdout as well as the log file
	echo -ne "\033[31m"
	echo "--exclude=$AVSCAN_IGNORE" | xargs "$CLAMSCAN_BINARY_LOCATION" -d "$MALSCAN_DIRECTORY"/rfxn.hdb -d "$MALSCAN_DIRECTORY"/rfxn.ndb -d "$MALSCAN_DIRECTORY"/custom.hdb -d "$MALSCAN_DIRECTORY"/custom.ndb -d "$CLAMAV_DIRECTORY"/ -i -r --no-summary "$TARGET" | tee -a "$SCANLOG"
	echo -ne "\033[37m"

	## If no files were found, we will add a note into the scanlog accordingly.
	if [[ ! -s "$SCANLOG" ]]; then
		echo -ne "\033[32m"
		echo "Malware scan completed. No malicious files found." | tee -a "$SCANLOG"
		echo -ne "\033[37m"
		DETECTION=0
	else
		echo -e "\033[31mSee $SCANLOG for a full list of detected files.\033[37m"
	fi

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
		echo -e "\033[36m$FILE quarantined and locked down in $QUARANTINE_PATH.\033[37m" | tee -a "$LOGGING_DIRECTORY"/quarantine.log
	done < <(cat "$SCANLOG" | cut -d: -f1)
}

function notification {
	if [[ "$DETECTION" == 1 ]]; then
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

if [[ -n "$NOTIFICATION" ]]; then
	notification
fi

# Cleaning up by chowning everything ot the clam user
chown -R "$MALSCAN_USER":"$MALSCAN_USER" "$MALSCAN_DIRECTORY"

exit 0
