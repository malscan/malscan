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

CURRENT_INSTALLER_BRACH="1.7.0-dev"

if [[ "$EUID" != 0 ]]; then
    echo -e "\033[31m The installer must be run as the root user, or using sudo.\033[37m"
    exit 1
fi

## Checking to see if we're on CentOS/RHEL
if [[ -f "/etc/redhat-release" ]]; then

    ## Getting the OS Distro type - cPanel is treated as a separate distro
    if [[ -d /usr/local/cpanel ]]; then
        DISTRO="cPanel"
    elif [[ -f /etc/centos-release ]]; then
        DISTRO="CentOS"
    elif [[ -f /etc/fedora-release ]]; then
        DISTRO="Fedora"
    else
        DISTRO="RHEL"
    fi

    if [[ "$DISTRO" == "RHEL" || "$DISTRO" == "CentOS" ]]; then

        if grep -qs "release 7" /etc/redhat-release; then
            VERSION="7"
        elif grep -qs "release 6" /etc/redhat-release; then
            VERSION=6
        else
            echo "What version of CentOS/RHEL are you running? (6/7)"
            read VERSION
        fi

        if rpm -q epel-release > /dev/null; then
            EPEL_PACKAGE=1
        fi
    elif [[ "$DISTRO" == "cPanel" || "$DISTRO" == "Fedora" ]]; then
        EPEL_PACKAGE=1
    fi

    if rpm -q clamav > /dev/null; then
        CLAMAV_PACKAGE=1
    elif [[ "$DISTRO" == "cPanel" && -d /usr/local/cpanel/3rdparty/share/clamav ]]; then
        CLAMAV_PACKAGE=1
        CLAMUPDATE_PACKAGE=1
    fi

    if rpm -q clamav-update > /dev/null; then
        CLAMUPDATE_PACKAGE=1
    elif rpm -q clamav-db > /dev/null; then
        CLAMUPDATE_PACKAGE=1
    fi

    ## Checking to see if file is installed
    if rpm -q file > /dev/null; then
        FILE_PACKAGE=1
    fi

    if rpm -q wget > /dev/null; then
        WGET_PACKAGE=1
    fi

    ## Checking to see if ClamAV is installed
    if rpm -q clamav > /dev/null && [[ "$DISTRO" != "cPanel" ]]; then
        CLAMAV_PACKAGE=1
        if [[ "$VERSION" == "7" ]] && rpm -q clamav-update > /dev/null; then
            CLAMUPDATE_PACKAGE=1
        elif [[ "$VERSION" == "6" ]] && rpm -q clamav-db > /dev/null; then
            CLAMUPDATE_PACKAGE=1
        fi
    elif [[ -d /usr/local/cpanel/3rdparty/share/clamav && "$DISTRO" == "cPanel" ]]; then
        CLAMAV_PACKAGE=1
        CLAMUPDATE_PACKAGE=1
    fi

    ## Checking to see if we have missing packages
    if [[ -z "$CLAMAV_PACKAGE" || -z "$FILE_PACKAGE" || -z "$CLAMUPDATE_PACKAGE" || -z "$EPEL_PACKAGE" || -z "$WGET_PACKAGE" ]]; then
        INSTALL_REQUIRED=1

        ## Providing install options
        echo -e "\033[31mMalscan has detected that one or more required packages are not currently installed."
        echo "For Malscan to install properly, the following packages must be installed: "

        INSTALL_PAYLOAD=''

        if [[ -z "$FILE_PACKAGE" ]]; then
            INSTALL_PAYLOAD="$INSTALL_PAYLOAD file"
        fi

        if [[ -z "$WGET_PACKAGE" ]]; then
            INSTALL_PAYLOAD="$INSTALL_PAYLOAD wget"
        fi

        if [[ -z "$EPEL_PACKAGE" && "$DISTRO" != "cPanel" && "$DISTRO" != "Fedora" ]]; then
            INSTALL_PAYLOAD="$INSTALL_PAYLOAD epel-release"
            EPEL_FIRST=1
        fi

        if [[ -z "$CLAMAV_PACKAGE" ]]; then

            INSTALL_PAYLOAD="$INSTALL_PAYLOAD clamav"
            if [[ "$VERSION" == "7" && -z "$CLAMUPDATE_PACKAGE" ]]; then
                INSTALL_PAYLOAD="$INSTALL_PAYLOAD clamav-update"
            elif [[ "$VERSION" == "6" && -z "$CLAMUPDATE_PACKAGE" ]]; then
                INSTALL_PAYLOAD="$INSTALL_PAYLOAD clamav-db"
            fi
        fi

        echo "    $INSTALL_PAYLOAD"

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
## Checking to see if we're on a Debian derivative
elif [[ -f /etc/lsb-release ]]; then
    DISTRO=$(grep "DISTRIB_ID" /etc/lsb-release | cut -d= -f2)
    VERSION=$(grep "DISTRIB_RELEASE" /etc/lsb-release | cut -d= -f2)

    INSTALL_PAYLOAD=''

    ## Checking to see if clamav is installed
    if dpkg -l clamav > /dev/null 2>&1; then
        CLAMAV_PACKAGE=1
        INSTALL_PAYLOAD="$INSTALL_PAYLOAD clamav"
    fi

    ## Checking to see if clamav is installed
    if dpkg -l clamav-freshclam > /dev/null 2>&1; then
        CLAMUPDATE_PACKAGE=1
        INSTALL_PAYLOAD="$INSTALL_PAYLOAD clamav-freshclam"
    fi

    ## Checking to see if file is installed
    if dpkg -l file > /dev/null 2>&1; then
        FILE_PACKAGE=1
        INSTALL_PAYLOAD="$INSTALL_PAYLOAD file"
    fi

    ## Checking to see if wget is installed
    if dpkg -l wget > /dev/null 2>&1; then
        WGET_PACKAGE=1
        INSTALL_PAYLOAD="$INSTALL_PAYLOAD wget"
    fi

    ## Checking to see if we have missing packages
    if [[ -z "$CLAMAV_PACKAGE" || -z "$FILE_PACKAGE" || -z "$CLAMUPDATE_PACKAGE" || -z "$WGET_PACKAGE" ]]; then
        INSTALL_REQUIRED=1

        ## Providing install options
        echo -e "\033[31mMalscan has detected that one or more required packages are not currently installed."
        echo "For Malscan to install properly, the following packages must be installed: "
        echo "    $INSTALL_PAYLOAD"
        

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

if [[ "$VERSION" != "7" && "$VERSION" != "6" && "$VERSION" != "14.04" && "$VERSION" != "22" && "$VERSION" != "23" && "$VERSION" != "24" ]]; then
    VERSION="Unsupported"
fi

## Checking Distro compatibility
if [[ "$DISTRO" == "Unsupported" || "$VERSION" == "Unsupported" ]]; then
    ## Incompatible distro, exiting
    echo -e "\033[31mMalscan has detected that this server is not running a supported operating system."
    echo "Malscan is currently only available for installation on the following Operating Systems: "
    echo "    CentOS 6.x / RHEL 6.x"
    echo "    CentOS 7.x / RHEL 7.x"
    echo "    Fedora 22 / 23 / 24"
    echo "    Ubuntu 14.04"
    echo -e "Feature requests for new Operating System support can be submitted to malscan.org/features\033[37m"
    exit 0
else

    if [[ "$DISTRO" == "CentOS" || "$DISTRO" == "RHEL" ]]; then
        PACKAGE_MANAGER="yum"
        PACKAGE_CHECKER="rpm -q"
    elif [[ "$DISRO" == "Fedora" ]]; then
        PACKAGE_MANAGER="dnf"
        PACKAGE_CHECKER="rpm -q"
    else
        PACKAGE_MANAGER="apt-get"
        PACKAGE_CHECKER="dpkg -l"
    fi
    ## Checking to see if we have a Package installation queued for CentOS.
    if [[ "$INSTALL_REQUIRED" == "1" && "$INSTALL_OPTION" == "1" ]]; then
        echo -e "\033[33mInstalling required packages now...\033[37m"

        for PACKAGE in $INSTALL_PAYLOAD; do
            $PACKAGE_MANAGER -y install $PACKAGE
        done

        ## Confirming that all packages installed properly
        if $PACKAGE_CHECKER $INSTALL_PAYLOAD > /dev/null; then
            echo -e "\033[32mInstallation of all required packages has been completed!\033[37m"
            CONFIGURATION_REQUIRED=1
        else
            echo -e "\033[31mInstallation of required packages has failed. Please manually install the following packages, and then restart the installer: "
            echo "    $INSTALL_PAYLOAD\033[37m"
            exit 1
        fi
    else
        ## No installation required, just configuration
        CONFIGURATION_REQUIRED=1
    fi
fi

## Beginning the main Malscan configuration
if [[ "$CONFIGURATION_REQUIRED" == "1" ]]; then

    getent group malscan > /dev/null || groupadd -r malscan
    getent passwd malscan > /dev/null || useradd -r -g malscan -s /sbin/nologin -c "Malscan Service User" malscan

    MALSCAN_BINARY_PATH="/usr/local/bin"
    MALSCAN_SYSCONFIG_PATH="/etc/malscan"
    MALSCAN_LOGGING_PATH="/var/log/malscan"
    MALSCAN_SIGNATURE_PATH="/var/lib/malscan"
    MALSCAN_MAN_PATH="/usr/local/share/man/man1"
    MALSCAN_MISC_PATH="/usr/local/share/malscan"

    ## Setting up our configuration files
    mkdir -p "$MALSCAN_SYSCONFIG_PATH"
    wget -P "$MALSCAN_SYSCONFIG_PATH/" "https://raw.githubusercontent.com/jgrancell/malscan/$CURRENT_INSTALLER_BRACH/malscan.conf" --quiet
    wget -P "$MALSCAN_SYSCONFIG_PATH/" "https://raw.githubusercontent.com/jgrancell/malscan/$CURRENT_INSTALLER_BRACH/freshclam.conf" --quiet
    chown -R malscan:malscan "$MALSCAN_SYSCONFIG_PATH"

    ## Setting up our Signatures and Logging directories
    mkdir -p "$MALSCAN_LOGGING_PATH"
    chown -R malscan:malscan "$MALSCAN_LOGGING_PATH"
    mkdir -p "$MALSCAN_SIGNATURE_PATH"
    chown -R malscan:malscan "$MALSCAN_SIGNATURE_PATH"

    ## Setting up our man page
    mkdir -p "$MALSCAN_MAN_PATH"
    wget -P "$MALSCAN_MAN_PATH/" "https://raw.githubusercontent.com/jgrancell/malscan/$CURRENT_INSTALLER_BRACH/malscan.1" --quiet

    ## Setting up the malscan binary
    mkdir -p "$MALSCAN_BINARY_PATH"
    wget -P "$MALSCAN_BINARY_PATH" "https://raw.githubusercontent.com/jgrancell/malscan/$CURRENT_INSTALLER_BRACH/malscan" --quiet
    chmod +x "$MALSCAN_BINARY_PATH/malscan"

    ## Creating the misc file directory
    mkdir -p "$MALSCAN_MISC_PATH"
    wget -P "$MALSCAN_MISC_PATH" "https://raw.githubusercontent.com/jgrancell/malscan/$CURRENT_INSTALLER_BRACH/LICENSE" --quiet 
    wget -P "$MALSCAN_MISC_PATH" "https://raw.githubusercontent.com/jgrancell/malscan/$CURRENT_INSTALLER_BRACH/README.md" --quiet
    wget -P "$MALSCAN_MISC_PATH" "https://raw.githubusercontent.com/jgrancell/malscan/$CURRENT_INSTALLER_BRACH/version.txt" --quiet
    chown -R malscan:malscan "$MALSCAN_MISC_PATH"

    ## Getting the user's input on email notifications
    echo -e "\033[33mBeginning the malscan configuration process..."
    echo ""
    echo -ne "Would you like to enable email notifications? [y/N] [default: N] \033[37m"
    read EMAIL_NOTIFICATIONS

    if [[ "$EMAIL_NOTIFICATIONS" == "y" || "$EMAIL_NOTIFICATIONS" == "Y" || "$EMAIL_NOTIFICATIONS" == "yes" || "$EMAIL_NOTIFICATIONS" == "YES" ]]; then
        ## Email notifications are being enabled, so we're now getting the list of addresses
        echo -e "\033[33mAt what email addresses would you like to receive notifications (Comma-separated list): \033[37m"
        read EMAIL_ADDRESSES

        echo -e "\033[33mWhat email address would you like malscan to send email from? \033[37m"
        read SENDER_ADDRESS

        "$MALSCAN_BINARY_PATH/malscan" -s EMAIL_NOTIFICATIONS TRUE > /dev/null
        "$MALSCAN_BINARY_PATH/malscan" -s NOTIFICATION_ADDRESS "$EMAIL_ADDRESSES" > /dev/null
        "$MALSCAN_BINARY_PATH/malscan" -s MALSCAN_SENDER_ADDRESS "$SENDER_ADDRESS" > /dev/null

    fi

    ## No remote quarantine, so we're now requesting the local quarantine directory
    echo ""
    echo -e "\033[33mWhat directory would you like to quarantine files in? [default=/root/.malscan/quarantine] \033[37m"
    read QUARANTINE_DIRECTORY

    if [[ "$QUARANTINE_DIRECTORY" = "" || "$QUARANTINE_DIRECTORY" = " " ]]; then
        QUARANTINE_PATH="/root/.malscan/quarantine"
    else
        QUARANTINE_PATH="$QUARANTINE_DIRECTORY"
    fi

    ## Creating the quarantine path if it doesn't exist
    if [[ -d "$QUARANTINE_PATH" ]]; then
        echo -e "\033[32mYour quarantine path has been successfully set!\033[37m"
        "$MALSCAN_BINARY_PATH/malscan" -s QUARANTINE_DIRECTORY "$QUARANTINE_PATH" > /dev/null
    else 
        mkdir -p "$QUARANTINE_PATH"
        echo -e "\033[32mThe directory $QUARANTINE_PATH has been created, and set as the Quarantine location.\033[37m"
        "$MALSCAN_BINARY_PATH/malscan" -s QUARANTINE_DIRECTORY "$QUARANTINE_PATH" > /dev/null
    fi
    
    echo -e "\033[032mMalscan has been successfully configured! Beginning initial update...\033[37m"

    echo -e "Pre-seeding the malscan signature databases with bundled signatures. This may take some time to complete."
    wget -P "$MALSCAN_SIGNATURE_PATH/" "http://database.clamav.net/main.cvd" --quiet
    wget -P "$MALSCAN_SIGNATURE_PATH/" "http://database.clamav.net/bytecode.cvd" --quiet
    wget -P "$MALSCAN_SIGNATURE_PATH/" "http://database.clamav.net/daily.cvd" --quiet
    chown -R malscan:malscan "$MALSCAN_SIGNATURE_PATH"

    echo -e "Updating to the latest malscan signature versions. You can always do this using the command 'malscan -u'"

    "$MALSCAN_BINARY_PATH/malscan" -u


    echo "Malscan has been successfully configured and instantited."
    echo "The current malscan configuration can be seen using the 'malscan -c' command"
    echo "All chosen configuration options can be changed using the 'malscan -s' command"
    echo "For more information on using malscan, use the 'malscan -h' or 'malscan --help' command."
    echo ""

fi

exit 0
