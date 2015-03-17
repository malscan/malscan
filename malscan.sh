
#!/bin/bash
# Malscan - Enhanced ClamAV Scanning System
# Written by Josh Grancell

VERSION="1.4.0"
DATE="Mar 16 2015"

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
		echo "Usage: malscan [options] /path/to/scanned/directory/or/file"
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
	LENGTHLOG="$LOGDIR"/'length-scan-'$(date +%F-%s)
	TEMPLOG=$(mktemp)	

	# Building the whitelist
	LENGTH_IGNORE=${LENGTH_WHITELIST//,/ -not -name }

	echo -e "\033[32mScanning $TARGET for files with strings longer than $LENGTH_MINIMUM characters: \033[37m"

	while IFS= read -r FILE
	do
		SIZE=$(wc -L "$FILE" | awk '{$1}')
		if [[ "$SIZE" -ge "$LENGTH_MIMIMUM" ]]; then
            echo -ne "\033[35m"
            echo "DETECTION: $FILE has been detected with a line length of $SIZE." | tee -a "$LENGTHLOG"
            echo -ne "\033[37m"
        fi
    done <   <(find "$TARGET" -type f -not -name "$LENGTH_IGNORE" -print0)		

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

## Defining the mimescan function
function mimescan {
	# Creating the logging directories
	MIMELOG="$LOGDIR"/'mimecheck-'$(date +%F-%s)
	TEMPLOG=$(mktemp)

	# Sed'ing the whitelist into something we can use with find
	MIME_IGNORE=${MIME_WHITELIST//,/ -not -name }

	echo -ne "\033[32mCompiling a full list of potential files... "
	find "$TARGET" -not -name $MIME_IGNORE -regextype posix-extended -regex '.*.(jpg|png|gif|swf|txt|pdf)' >>"$TEMPLOG"
	echo "Completed!"
	echo -e "Searching found files for any MIME mismatch against the given extensions.\033[37m"	

	# Working through the temporary file list to match files with mimetypes.
	while IFS= read -r FILE; do

                if file "$FILE" | egrep -q '(jpg|png|gif|swf|txt|pdf).*?(PHP)'; then
                        if  [ "$(basename $FILE)" != "license.txt" ]; then
                                echo -ne "\033[35m"
                                echo "DETECTION: $FILE has been detected as a PHP file with a non-matching extension." | tee -a "$MIMELOG"
                                echo -ne "\033[37m"
                        fi
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
		echo "No suspicious files detected." | tee -a "$MIMELOG"
		echo -ne "\033[37m"
		DETECTION=0
	fi
}

## Defining the scanning function
function avscan {

	CLAMSCAN=$(which clamscan)

	# Setting up the whitelist
	AVSCAN_IGNORE=${AVSCAN_WHITELIST//,/--exclude}

	# Creating the scan log file for this scan
	SCANLOG="$LOGDIR"/$(date +%F-%s)

	# Outputting the scanning information to stdout as well as the log file
	echo -ne "\033[31m"
	"$CLAMSCAN" -d "$MAINDIR"/rfxn.hdb -d "$MAINDIR"/rfxn.ndb -d "$MAINDIR"/custom.hdb -d "$MAINDIR"/custom.ndb -i -r --no-summary --exclude="$AVSCAN_IGNORE" "$TARGET" | tee -a "$SCANLOG"
	echo -ne "\033[37m"

	## If no files were found, we'll add a note into the scanlog accordingly.
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
			mkdir -p "$QDIR"/"$DIR"
			mv "$ABSPATH" "$QDIR""$ABSPATH"

			# If remote quarantine is set up, copying these files to the remote quarantine server
			if [[ "$REMOTE_QUARANTINE_ENABLED" == 1 ]]; then
				rsync -avzP "$QDIR"/ -e ssh "$REMOTE_SSH:$REMOTE_QUARANTINE" >> /dev/null
			fi

			# Setting the files to 000 permissions so they cannot be accessed
			chmod 000 "$QDIR""$ABSPATH"
			echo -e "\033[36m$FILE quarantined and locked down in $QDIR and sent to Centauri.\033[37m" | tee -a "$LOGDIR"/quarantine.log
		done < <(cat"$SCANLOG" | cut -d: -f1)
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
			echo "Malicious and/or suspicious files have been quarantined on $HOSTNAME. Please see $LOGDIR/quarantine.log for further information.<br />"
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
	REPORTFILE="$LOGDIR"/report-"$HOSTNAME"-$(date +%s).log

	# Generating the malware signature
	sigtool --md5 "$TARGET" >> "$REPORTFILE"

	# If remote logging is enabled, reporting this to our remote SSH server
	if [[ "$REMOTE_LOGGING_ENABLED" == 1 ]]; then
		rsync -avzP "$REPORTFILE" -e ssh "$REMOTE_SSH:$REMOTE_LOGGING"/"$HOSTNAME"/
	fi

	echo -e "\033[36mFile signatured generated and reported to Centauri for inclusion in the DB.\033[37m"
	exit 0
}


# Executing the Functions
if [[ -n "$REPORT" ]]; then
	report
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
chown -R "$USER":"$USER" "$MAINDIR"

exit 0
