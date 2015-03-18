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
** RFX Networks Signatures
** Metasploit Signatures
** JoshGrancell.com Signatures
** ClamAV Main Signatures
* Multiple Detection Methods
** Standard HEX or MD5 based detections
** String length detections
** MimeType mismatch detections
* Easy File Quarantining
* Built-in new file signature generation
* Customizable email notifications

## Requirements
* Linux Server / Desktop
* ClamAV
* SSH Access

## Installation
* Step 1: Install ClamAV on your server
  * For Redhat/CentOS:
    * Install the EPEL Repository using `yum install epel-release`
    * Install clamav using `yum install clamav`
  * For Debian/Ubuntu, install directly from the repositories using `apt-get install clamav`
* Step 2: Navigate to your clamav directory.
  * For RedHat/CentOS: `cd /usr/local/share/clamav`
  * For Debian/Ubuntu: `cd /var/lib/clamav`
* Step 3: Clone this git repository with `git clone https://github.com/jgrancell/Malscan.git`
* Step 4: Run the cron_update.sh script to update the signatures and build any needed directories/binaries with `./cron_update.sh`
* Step 5: Set the cron_update.sh to run at least daily through `crontab -e` setting the cronjob to run daily
  * Daily: `0 2 * * * /path/to/clamav/cron_update.sh`
  * Twice Daily: `0 */2 * * * /path/to/clamav/cron_update.sh`
  * NOTE: If running daily, ensure that the update is run BEFORE any scheduled scans.
* Step 6: Run the scanner as needed
  * Manually: `malscan -[options] /path/to/target/directory/or/file`
  * Via Cronjob: `30 3 * * * /usr/local/bin/malscan -[options] /path/to/target/directory/or/file`
* 
## Usage

See `malscan -h` for more detailed program usage.

## Changelog

#### Version 1.4.1
*Released: March 18, 2015*
* Bugfix: Proper detection of the malscan program path when run as a cronjob or from outside of the Malscan directory.

#### Version 1.4.0
*Released: March 16, 2015*
* First offical public release

## Licensing and Terms of Usage

The Malscan application is released under the GPLv3 license, which is included in the repository. This software is provided as is, with absolutely no warranty provided for it. As this application does alter file/directory structure for this server, make sure that you understand exactly what this application does and the security ramifications of it.
