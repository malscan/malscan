Malscan
============

Robust ClamAV-based malware scanner for web servers.

[![GitHub version](https://badge.fury.io/gh/jgrancell%2FMalscan.svg)](http://badge.fury.io/gh/jgrancell%2FMalscan)

#Table of Contents
* [Features](#features)
* [Requirements](#requirements)
* [Installation](#installation)
* [Changelog](#changelog)

## Summary

Malscan is a powerful malware scanner, leveraging 

## Features
* Multiple channels of malware signatures
  * RFX Networks Signatures
  * Metasploit Signatures
  * JoshGrancell.com Signatures
  * ClamAV Main Signatures
* Multiple Detection Methods
  * Standard HEX or MD5 based detections
  * String length detections
  * MimeType mismatch detections
  * Tripwire Scanning - detects files that have been changed from the reference base
* Easy File Quarantining
* Built-in new file signature generation
* Customizable email notifications

## Requirements
* Linux Server / Desktop
* ClamAV
* SSH Access

## Installation

#### CentOS 6, CentOS 7, Ubuntu 14.04

* Run the following command from within the terminal to install Malscan automatically: `wget https://raw.githubusercontent.com/jgrancell/Malscan/1.5.0-dev/install.sh && bash install.sh`
* Follow the guided installer in the terminal to complete the installation, configuration, and initial whitelisting process.

#### Other Operating Systems
* Step 1: Install ClamAV on your server
  * For Redhat/CentOS:
    * Install the EPEL Repository using `yum install epel-release`
    * Install clamav using `yum install clamav`
    * Some variants of CentOS may not include freshclam in the clamav package. If your CentOS does not include this, you also need use `yum install clamav-update`
  * For Debian/Ubuntu, install directly from the repositories using `apt-get install clamav`
* Step 2: Navigate to your clamav directory.
  * For RedHat/CentOS: `cd /usr/local/share/clamav`
  * For Debian/Ubuntu: `cd /var/lib/clamav`
* Step 3: Clone this git repository with `git clone https://github.com/jgrancell/Malscan.git`
* Step 4: Copy the `conf.malscan-blank` file to `conf-malscan` and complete all of the needed information.
* Step 5: Run the cron_update.sh script to update the signatures and build any needed directories/binaries with `./cron_update.sh`
* Step 6: Set the cron_update.sh to run at least daily through `crontab -e` setting the cronjob to run daily
  * Daily: `0 2 * * * /path/to/clamav/cron_update.sh`
  * Twice Daily: `0 */2 * * * /path/to/clamav/cron_update.sh`
  * NOTE: If running daily, ensure that the update is run BEFORE any scheduled scans.
* Step 7: Run the scanner as needed
  * Manually: `malscan -[options] /path/to/target/directory/or/file`
  * Via Cronjob: `30 3 * * * /usr/local/bin/malscan -[options] /path/to/target/directory/or/file`
 
## Usage

See `malscan -h` for more detailed program usage.

## Changelog

#### Version 1.5.0
*Release: TBD*
* Feature: Added automated whitelisting of file trees for known clean files (such as imports from development enviroments or fresh installs)
* Feature: New Tripwire scanning mode. Identifies any files that have been changed or did not exist from the whitelist reference. Excellent for static sites or minimally changing applications.
* Feature: New installer.
  * New installer is compatible with CentOS 6, CentOS 7, and Ubuntu 14.04.
  * Other Operating Systems remain supported by Malscan, however installationr requires manually installing ClamAV and Freshclam.

#### Version 1.4.4
*Released: May 6, 2015*
* Bugfix: Corrected an issue with notifications not being sent because there was no way to specify receiving email addresses. Fixed in conf.malscan-blank.
* Bugfix: Corrected an issue with whitelisting not working properly. It should now function correctly, and is working in test RHEL 6 and CentOS 7 testing environments.
* Special Note: The changes to conf.malscan-blank will need to be manually added to any active conf.malscan files. 

#### Version 1.4.3
*Released: May 5, 2015*
* Bugfix: Corrected a logging path issue. All log files will now be correctly generated in the 'log' directory inside your chosen path in conf.malscan
* Bugfix: Corrected the URL for the custom virus definitions
* Feature: Included freshclam updates within the cron_update.sh script

#### Version 1.4.2
*Released: April 09, 2015*
* Bugfix: Corrected an error with the AV-Scan whitelisting functionality, causing malscan to ignore whitelistings. It is now working properly.

#### Version 1.4.1
*Released: March 18, 2015*
* Bugfix: Proper detection of the malscan program path when run as a cronjob or from outside of the Malscan directory.

#### Version 1.4.0
*Released: March 16, 2015*
* First offical public release

## Licensing and Terms of Usage

The Malscan application is released under the GPLv3 license, which is included in the repository. This software is provided as is, with absolutely no warranty provided for it. As this application does alter file/directory structure for this server, make sure that you understand exactly what this application does and the security ramifications of it.
