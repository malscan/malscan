#!/bin/bash
# Malscan installer - Authored by Josh Grancell
# Version 1.5.0 - Updated 5/26/2015

clear

## Checking to see if we're on CentOS/RHEL
if [[ -f "/etc/redhat-release" ]]; then

	## Getting the OS Distro type - cPanel is treated as a separate distro
	if [[ -d /usr/local/cpanel ]]; then
		DISTRO="cPanel"
    elif grep -qs "CentOS" /etc/redhat-release; then
    	DISTRO="CentOS"
    elif grep -qs "RedHat" /etc/redhat-release; then
    	DISTRO="RHEL"
    fi

    ## Getting the Distro version. RHEL/CentOS 5 is currently unsupported, however we're detecting it for future support.
	if grep -qs "release 7" /etc/redhat-release; then
		VERSION="7"
	elif grep -qs "release 6" /etc/redhat-release; then
		VERSION="6"
	elif grep -qs "release 5" /etc/redhat-release; then
		VERSION="5"
	else
		VERSION="Unsupported"
	fi

	## Checking for required packages
	if rpm -q epel-release; then
		EPEL_PACKAGE=1
	fi

	## Checking to see if ClamAV is installed
	if rpm -q clamav  && [[ "$DISTRO" != "cPanel" ]]; then
		CLAMAV_PACKAGE=1
		if [[ "$VERSION" == "7" ]] && rpm -q clamav-update; then
			CLAMUPDATE_PACKAGE=1
		fi
	elif [[ -d /usr/local/cpanel/3rdparty/share/clamav && "$DISTRO" == "cPanel" ]]; then
		CLAMAV_PACKAGE=1
	fi

	## Checking to see if file is installed
	if rpm -q file; then
		FILE_PACKAGE=1
	fi

	## Checking to see if git is installed
	if rpm -q git; then
		GIT_PACKAGE=1
	fi

	## Checking to see if we have missing packages
	if [[ -z "$CLAMAV_PACKAGE" || -z "$FILE_PACKAGE" || -z "$GIT_PACKAGE" || -z "$EPEL_PACKAGE" ]]; then
		INSTALL_REQUIRED=1

		## Providing install options
		echo -e "\033[31mMalscan has detected that one or more required packages are not currently installed."
		echo "For Malscan to install properly, the following packages must be installed: "

		if [[ -z "$GIT_PACKAGE" ]]; then
			echo "    git"
		fi

		if [[ -z "$FILE_PACKAGE" ]]; then
			echo "    file"
		fi

		if [[ -z "$EPEL_PACKAGE" && "$DISTRO" != "cPanel" ]]; then
			echo "    epel-release"
		fi

		if [[ -z "$CLAMAV_PACKAGE" ]]; then
			echo "    clamav"
			if [[ "$VERSION" == "7" && -z "$CLAMUPDATE_PACKAGE" ]]; then
				echo "    clamav-update"
			fi
		fi

		if [[ -z $CLAMAV_PACKAGE && "$DISTRO" == "cPanel" ]]; then
			echo "Because this is a cPanel system, ClamAV must be manually installed through WHM."
			echo "To install ClamAV through WHM, use the cPanel > Manage Plugins tool."
			echo -e "Once that has completed, you will need to install any additional missing packages manually.\033[37m"
			exit 1
		else
			echo -e "\033[32mMalscan can attempt to automatically install these packages. Please select an option below: \033[37m"
			echo "  1. Automatically install all missing packages."
			echo "  2. Exit installer and manually install missing packages."
			read INSTALL_OPTION

			if [[ "$INSTALL_OPTION" == "2" ]]; then
				echo -e "\033[31mYou have selected to manually install the missing packages. Please run this installer again once the missing packages have been installed.\033[37m"
				exit 0
			fi
		fi
	else
		INSTALL_REQUIRED=0
	fi
## Checking to see if we're on Ubuntu
elif grep -qs Ubuntu /etc/lsb-release; then
	DISTRO="Ubuntu"
	VERSION="Placeholder"

	## Checking to see if clamav is installed
	if dpkg -l | grep -E '^ii' | grep clamav; then
		CLAMAV_PACKAGE=1
	fi

	## Checking to see if file is installed
	if dpkg -l | grep -E '^ii' | grep file; then
		FILE_PACKAGE=1
	fi

	## Checking to see if git is installed
	if dpkg -l | grep -E '^ii' | grep git; then
		GIT_PACKAGE=1
	fi

	## Checking to see if we have missing packages
	if [[ -z "$CLAMAV_PACKAGE" || -z "$FILE_PACKAGE" || -z "$GIT_PACKAGE" ]]; then
		INSTALL_REQUIRED=1

		## Providing install options
		echo -e "\033[31mMalscan has detected that one or more required packages are not currently installed."
		echo "For Malscan to install properly, the following packages must be installed: "

		if [[ -z "$GIT_PACKAGE" ]]; then
			echo "    git"
		fi

		if [[ -z "$FILE_PACKAGE" ]]; then
			echo "    file"
		fi

		if [[ -z "$CLAMAV_PACKAGE" ]]; then
			echo "    clamav"
		fi

		echo -e "\033[32mMalscan can attempt to automatically install these packages. Please select an option below: \033[37m"
		echo "  1. Automatically install all missing packages."
		echo "  2. Exit installer and manually install missing packages."
		read INSTALL_OPTION

		if [[ "$INSTALL_OPTION" == "2" ]]; then
			echo -e "\033[31mYou have selected to manually install the missing packages. Please run this installer again once the missing packages have been installed.\033[37m"
			exit 0
		fi
	else
		INSTALL_REQUIRED=0
	fi
else
	DISTRO="Unsupported"
fi

## Checking Distro compatibility
if [[ "$DISTRO" == "Unsupported" || "$VERSION" == "Unsupported" || "$VERSION" == "5" ]]; then
	## Incompatible distro, exiting
	echo -e "\033[31mMalscan has detected that this server is not running a supported operating system."
	echo "Malscan is currently only available for installation on the following Operating Systems: "
	echo "    CentOS 6.x / RHEL 6.x"
	echo "    CentOS 7.x / RHEL 7.x"
	echo "    Ubuntu 14.04"
	echo -e "Feature requests for new Operating System support can be submitted to malscan.org/features\033[37m"
	exit 0
elif [[ "$DISTRO" == "CentOS" || "$DISTRO" == "RHEL" ]]; then
	## Checking to see if we have a Package installation queued for CentOS.
	if [[ "$INSTALL_REQUIRED" == "1" && "$INSTALL_OPTION" == "1" ]]; then
		echo -e "\033[33mInstalling required packages now...\033[37m"
		## Installing Epel for ClamAV unless it's already installed.
		if [[ -z "$EPEL_PACKAGE" ]]; then
			yum -y install epel-release
		fi

		## Installing all needed packages
		yum -y install git file clamav

		## If we're on CentOS 7, we need to install Freshclam separately
		if [[ "$VERSION" == "7" ]]; then
			yum -y install clamav-update
		fi

		## Confirming that all packages installed properly
		if rpm -q clamav && rpm -q file && rpm -q git; then
			echo -e "\033[32mInstallation of all required packages has been completed!\033[37m"
			CONFIGURATION_REQUIRED=1
		else
			echo -e "\033[31mInstallation of required packages has failed. Please manually install the following packages, and then restart the installer: "
			echo "    git"
			echo "    file"
			echo -e "    clamav\033[37m"
			exit 1
		fi
	else
		## No installation required, just configuration
		CONFIGURATION_REQUIRED=1
	fi
elif [[ "$DISTRO" == "Ubuntu" ]]; then
	## Checking to see if we have a Package installation queued for Ubuntu
	if [[ "$INSTALL_REQUIRED" == "1" && "$INSTALL_OPTION" == "1" ]]; then
		apt-get update
		apt-get -y install git file clamav

		## Confirming installation
		if dpkg -l | grep -E '^ii' | grep clamav; then
			CLAMAV_PACKAGE=1
		else
			CLAMAV_PACKAGE=0
		fi

		## Checking to see if file is installed
		if dpkg -l | grep -E '^ii' | grep file; then
			FILE_PACKAGE=1
		else
			FILE_PACKAGE=0
		fi

		## Checking to see if git is installed
		if dpkg -l | grep -E '^ii' | grep git; then
			GIT_PACKAGE=1
		else
			GIT_PACKAGE=0
		fi	

		if [[ "$GIT_PACKAGE" == "1" && "$FILE_PACKAGE" == "1" && "$CLAMAV_PACKAGE" == "1" ]]; then
			echo -e "\033[32mInstallation of all required packages has been completed!\033[37m"
			CONFIGURATION_REQUIRED=1
		else
			echo -e "\033[31mInstallation of required packages has failed. Please manually install the following packages, and then restart the installer: "
			echo "    git"
			echo "    file"
			echo -e"    clamav\033[37m"
			exit 1
		fi	
	fi
fi

## Beginning the main Malscan configuration
if [[ "$CONFIGURATION_REQUIRED" == "1" ]]; then

	## First, we are going to identify the native ClamAV signature directory.
	if [[ "$VERSION" == "7" ]]; then
		CLAMAV_DIRECTORY=$(find / -name "daily.cvd" | xargs dirname | head -n 1 )
	else
		CLAMAV_DIRECTORY=$(grep "DatabaseDirectory" /etc/freshclam.conf | awk '{print $2}')
	fi

	## Next, we'll identify the Clamav Update user, which will either be clamav/clam/clamupdate or something equally confusing.
	CLAMAV_USER=$(ls -ld "$CLAMAV_DIRECTORY" | awk '{print $3}')

	## Now we are checking to see if Freshclam has a conf file that is still using default Example information.
	if [[ -f /etc/freshclam.conf ]]; then
		sed -i 's/Example//g' /etc/freshclam.conf
	fi

	## Now we're getting the binary locations for Freshclam and Clamscan, which will likely be /usr/local/bin or /usr/bin
	CLAMSCAN=$(find / -name "clamscan" -executable -path "*bin*" | head -n 1)
	FRESHCLAM=$(find / -name "freshclam" -executable -path "*bin*" | head -n 1)

	## We are now creating the main Malscan directory, and moving into it.
	mkdir -p /usr/local/share/malscan
	cd /usr/local/share/malscan
	MAIN_DIRECTORY="/usr/local/share/malscan"

	## Now, we are cloning the Malscan git repo into the Malscan directory and arranging the files
	git clone https://github.com/jgrancell/Malscan.git --quiet
	rsync -aqzP /usr/local/share/malscan/Malscan/ /usr/local/share/malscan/
	
	## Cleaning up the Malscan directory
	rm -rf /usr/local/share/malscan/Malscan

	## Placeholder - Switching to the dev branch for install testing.
	git checkout 1.5.0-dev --quiet
	git pull origin 1.5.0-dev --quiet

	## Echoing the beginning of the configuration file
	{
	echo "#!/bin/bash"
	echo "# Malscan Main Configuration File"
	echo "# Autogenerated by install.sh since Version 1.5.0"
	echo ""
	echo ""
	echo "# Directory and User Structure"
	echo "CLAMAV_DIRECTORY=\"$CLAMAV_DIRECTORY\""
	echo "MALSCAN_DIRECTORY=\"$MAIN_DIRECTORY\""
	echo "MALSCAN_USER=\"$CLAMAV_USER\""
	echo "MALSCAN_BINARY_LOCATION=\"/usr/local/bin/malscan\""
	echo "CLAMSCAN_BINARY_LOCATION=\"$CLAMSCAN\""
	echo "FRESHCLAM_BINARY_LOCATION=\"$FRESHCLAM\""
	} >> conf.malscan

	## Getting the user's input on email notifications
	echo -e "\033[33mBeginning the malscan configuration process..."
	echo -ne "Would you like to enable email notifications? [y/N] [default: N] \033[37m"
	read EMAIL_NOTIFICATIONS

	if [[ "$EMAIL_NOTIFICATIONS" == "y" || "$EMAIL_NOTIFICATIONS" == "Y" || "$EMAIL_NOTIFICATIONS" == "yes" || "$EMAIL_NOTIFICATIONS" == "YES" ]]; then
		## Email notifications are being enabled, so we're now getting the list of addresses
		echo -e "\033[33mAt what email addresses would you like to receive notifications (Comma-separated list): \033[37m"
		read EMAIL_ADDRESSES

		## Echoing the formatted configuration information to the file
		{
		echo "ENABLE_EMAIL_NOTIFICATIONS=\"1\"" >> conf.malscan
		echo "NOTIFICATION_ADDRESSES=\"$EMAIL_ADDRESSES\""
		echo ""
		} >> conf.malscan
	else 
		## Email notifications are not being enabled. Echoing default disabled information.
		{
		echo "ENABLE_EMAIL_NOTIFICATIONS=\"0\"" >> conf.malscan
		echo "NOTIFICATION_ADDRESSES=\"\"" >> conf.malscan
		echo ""
		} >> conf.malscan
	fi

	## Echoing the spacer for the quarantine section into the configuration file
	echo "# Quarantine and Logging" >> conf.malscan

	## Remote Quarantine is not enabled quite yet, so we're setting up local quarantine.
	QUARANTINE_PATH="/usr/local/share/malscan/quarantine"

	## No remote quarantine, so we're now requesting the local quarantine directory
	echo -e "\033[33mWhat directory would you like to quarantine files in? [default=/usr/local/share/malscan/quarantine] \033[37m"
	read QUARANTINE_DIRECTORY

	if [[ "$QUARANTINE_DIRECTORY" != "" && "$QUARANTINE_DIRECTORY" != " " ]]; then
		"$QUARANTINE_PATH"="$QUARANTINE_DIRECTORY"
	fi

	## Creating the quarantine path if it doesn't exist
	if [[ -d "$QUARANTINE_PATH" ]]; then
		echo -e "\033[32mYour quarantine path has been successfully set!\033[37m"
	else 
		mkdir -p "$QUARANTINE_PATH"
		echo -e "\033[32mThe directory $QUARANTINE_PATH has been created, and set as the Quarantine location.\033[37m"
	fi
	
	## Echoing the local quarantine inforamtion into the configuration file.
	{
	echo "REMOTE_QUARANTINE_ENABLED=\"0\""
	echo "REMOTE_SSH=\"\""
	echo "QUARANTINE_PATH=\"$QUARANTINE_PATH\""
	} >> conf.malscan

	{
	echo ""
	echo "# Static Whitelist"
	echo "AVSCAN_WHITELIST=\"'quarantine'\""
	echo "MIME_WHITELIST=\"\""
	echo ""
	echo "# String Length Scanning"
	echo "LENGTH_MINIMUM=15000"
	} >> conf.malscan

	echo -e "\033[032mMalscan has been successfully configured! Beginning initial update...\033[37m"
	wget -q https://www.rfxn.com/downloads/rfxn.hdb
	wget -q https://www.rfxn.com/downloads/rfxn.ndb
	wget -q https://repo.joshgrancell.com/custom.hdb
	wget -q https://repo.joshgrancell.com/custom.ndb

	echo -e "\033[032mRunning Freshclam updater. This can potentially take a very long time...\033[37m"
	"$FRESHCLAM" 

	mkdir -p /usr/local/share/malscan/log
	ln -s /usr/local/share/malscan/malscan.sh /usr/local/bin/malscan

	chown -R "$CLAMAV_USER":"$CLAMAV_USER" /usr/local/share/malscan

	echo -ne "\033[32mMalware signatures have been updated successfully. Would you like to whitelist known clean files at this time? [Y/n] \033[37m"
	read BEGIN_WHITELIST

	if [[ "$BEGIN_WHITELIST" == "y" || "$BEGIN_WHITELIST" == "Y" || "$BEGIN_WHITELIST" == "yes" || "$BEGIN_WHITELIST" == "YES" ]]; then
		echo -e "\033[33mThe whitelist process will scan an entire file tree, including all subdirectories and files.\033[37m"
		echo -e "\033[33mBy whitelisting a file, it will not trigger any type of detection in its current state. Any type of alteration to the file once whitelisted will trigger a detection."
		echo -e "\033[33mAll files found within the file tree will be whitelisted. This is only recommended for known clean systems, such as default installs or imports from secure staging servers.\033[37m"
		echo -ne "\033[33mIf you would like to whitelist a specific directory, please provide the full directory path now. If you would like to cancel, type the word cancel: \033[37m"
		read WHITELIST_DIRECTORY

		if [[ "$WHITELIST_DIRECTORY" == "cancel" ]]; then
			echo -e "\033[33mWhitelisting has been cancelled. You can whitelist again at any time using the malscan program directly.\033[37m"
		else
			/usr/local/bin/malscan -w "$WHITELIST_DIRECTORY"
		fi
	fi

	echo "Malscan has been successfully configured and instantited."
	echo "All chosen configuration options can be changed within the config file at /usr/local/share/malscan/conf.malscan"
	echo "For more information on using Malscan, use the malscan -h or malscan --help command."

fi

exit 0