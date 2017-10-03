#!/bin/bash
# -------------------------------------------------
#
# Package: Malscan
# Author: Josh Grancell <josh@joshgrancell.com>
# Description: Linux malware scanner for web servers
# Copyright: 2015-2018 Josh Grancell
# License: MIT License
#
# -------------------------------------------------

MALSCAN_REPOSITORY_URL="https://gitlab.com/malscan/malscan/raw"
SIGNATURE_REPOSITORY_URL="https://www.joshgrancell.com/signatures"

## Determining which release to install
if [[ $# == 1 ]]; then
  CURRENT_INSTALLER_BRANCH="$1"
else
  CURRENT_INSTALLER_BRANCH="master"
fi

## Verifying that we are running under root/sudo
if [[ "$EUID" != 0 ]]; then
  echo -e "\033[31mThe installer must be run either as the root user or under sudo.\033[37m"
  exit 1
fi

## Determining our OS
if [[ -f "/etc/redhat-release" ]]; then
  ## Determining the RedHat-derivative OS
  if [[ -d /usr/local/cpanel ]]; then
    DISTRO="cPanel"
  elif [[ -f /etc/centos-release ]]; then
    DISTRO="CentOS"
  elif [[ -f /etc/fedora-release ]]; then
    DISTRO="Fedora"
  else
    DISTRO="RHEL"
    ## EPEL is required for installation
    EPEL_REQUIRED=1
  fi

elif [[ -f /etc/lsb-release ]]; then
  DISTRO=$(grep "DISTRIB_ID" /etc/lsb-release | cut -d= -f2)
  VERSION=$(grep "DISTRIB_RELEASE" /etc/lsb-release | cut -d= -f2)
else
  DISTRO="Unsupported"
fi

if [[ "$DISTRO" == "cPanel" ]]; then
  echo "Because this is a cPanel system, ClamAV must be manually installed through WHM."
  echo "To install ClamAV through WHM, use the cPanel > Manage Plugins tool."
  echo "If you have completed the ClamAV plugin installation, you may continue with the Malscan installation."
  echo "Continue? [y/N]"
  read INSTALL_OPTION

  if [[ "$INSTALL_OPTION" != "y" && "$INSTALL_OPTION" != "Y" ]]; then
    echo -e "\033[31mYou have selected to exit this isntallation. Please run this installer again once the ClamAV plugin has been installed.\033[37m"
    exit 0
  fi
  yum -y install file wget

elif [[ "$DISTRO" == "RHEL" || "$DISTRO" == "CentOS" ]]; then
  yum -y install epel-release file wget

  if grep -qs "release 6" /etc/redhat-release; then
    yum -y install clamav clamav-db
  else
    yum -y install clamav clamav-update
  fi
elif [[ "$DISTRO" == "Fedora" ]]; then
  ## Installing for Fedora
  dnf -y install clamav-clamav-update file weget
elif [[ "$DISTRO" == "Ubuntu" ]]; then
  ## Installing for Ubuntu
  apt-get update
  apt-get -y install clamav clamav-freshclam file wget
else
  ## Incompatible distro, exiting
  echo -e "\033[31mMalscan has detected that this server is not running a supported operating system."
  echo "Malscan is currently only available for installation on the following Operating Systems: "
  echo "    CentOS/RHEL 6.x / 7.x"
  echo "    Fedora 24 / 25 / 26"
  echo "    Ubuntu 14.04 / 16.04"
  echo -e "Feature requests for new Operating System support can be submitted to malscan.org/features\033[37m"
  exit 0
fi

# ----------------------------------------------------
# Malscan configuration section

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
wget -P "$MALSCAN_SYSCONFIG_PATH/" "$MALSCAN_REPOSITORY_URL/$CURRENT_INSTALLER_BRANCH/malscan.conf" --quiet
wget -P "$MALSCAN_SYSCONFIG_PATH/" "$MALSCAN_REPOSITORY_URL/$CURRENT_INSTALLER_BRANCH/freshclam.conf" --quiet
chown -R malscan:malscan "$MALSCAN_SYSCONFIG_PATH"

## Setting up our Signatures and Logging directories
mkdir -p "$MALSCAN_LOGGING_PATH"
chown -R malscan:malscan "$MALSCAN_LOGGING_PATH"
mkdir -p "$MALSCAN_SIGNATURE_PATH"
chown -R malscan:malscan "$MALSCAN_SIGNATURE_PATH"

## Setting up our man page
mkdir -p "$MALSCAN_MAN_PATH"
wget -P "$MALSCAN_MAN_PATH/" "$MALSCAN_REPOSITORY_URL/$CURRENT_INSTALLER_BRANCH/malscan.1" --quiet

## Setting up the malscan binary
mkdir -p "$MALSCAN_BINARY_PATH"
echo "$MALSCAN_REPOSITORY_URL/$CURRENT_INSTALLER_BRANCH/malscan"
wget -P "$MALSCAN_BINARY_PATH" "$MALSCAN_REPOSITORY_URL/$CURRENT_INSTALLER_BRANCH/malscan" --quiet
chmod +x "$MALSCAN_BINARY_PATH/malscan"

## Creating the misc file directory
mkdir -p "$MALSCAN_MISC_PATH"
wget -P "$MALSCAN_MISC_PATH" "$MALSCAN_REPOSITORY_URL/$CURRENT_INSTALLER_BRANCH/LICENSE" --quiet
wget -P "$MALSCAN_MISC_PATH" "$MALSCAN_REPOSITORY_URL/$CURRENT_INSTALLER_BRANCH/README.md" --quiet
wget -P "$MALSCAN_MISC_PATH" "$MALSCAN_REPOSITORY_URL/$CURRENT_INSTALLER_BRANCH/version.txt" --quiet
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
wget -P "$MALSCAN_SIGNATURE_PATH/" "$SIGNATURE_REPOSITORY_URL/main.cvd" --quiet
wget -P "$MALSCAN_SIGNATURE_PATH/" "$SIGNATURE_REPOSITORY_URL/bytecode.cvd" --quiet
wget -P "$MALSCAN_SIGNATURE_PATH/" "$SIGNATURE_REPOSITORY_URL/daily.cvd" --quiet
chown -R malscan:malscan "$MALSCAN_SIGNATURE_PATH"

echo -e "Updating to the latest malscan signature versions. You can always do this using the command 'malscan -u'"

"$MALSCAN_BINARY_PATH/malscan" -u


echo "Malscan has been successfully configured and instantited."
echo "The current malscan configuration can be seen using the 'malscan -c' command"
echo "All chosen configuration options can be changed using the 'malscan -s' command"
echo "For more information on using malscan, use the 'malscan -h' or 'malscan --help' command."
echo ""
