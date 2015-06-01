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
  * Malscan Signatures
  * ClamAV Main Signatures
* Multiple Detection Methods
  * Standard HEX or MD5 based detections, with a database of over 20,000 signatures and growing.
  * String length detections - smart detection of long injected strings, such as base64
  * MimeType mismatch detections - detects PHP files attempting to masquerade as other file types
  * Tripwire Scanning - detects files that have been changed from the reference base
* Easy File Quarantining
* Built-in new file signature generation
* Customizable email notifications

## Requirements
* Linux Server / Desktop
* Full root access, or the ability to install:
  * ClamAV
  * Git
  * File
  * Postfix or Exim, if using email notifications.
* SSH Access

## Installation

#### CentOS 6, CentOS 7, Ubuntu 14.04

* Run the following command from within the terminal to install Malscan automatically: `wget https://raw.githubusercontent.com/jgrancell/Malscan/1.5.0-dev/install.sh && bash install.sh`
  * If installing on ubuntu, you may need to run the command `wget https://raw.githubusercontent.com/jgrancell/Malscan/1.5.0-dev/install.sh --no-check-certificate && bash install.sh` instead.
* Follow the guided installer in the terminal to complete the installation, configuration, and initial whitelisting process.

#### Other Operating Systems

Generally, the installer steps should work on other versions of Ubuntu, Debian, and other RHEL derivatives. If you run into specific installer issues with any non-supported Operating Systems or versions, please submit an issue and I would be happy to add support for it.

To manually install Malscan

* Step 1: Install ClamAV, Git, and File on your server
  * For Redhat/CentOS:
    * Install the EPEL Repository using `yum install epel-release`
    * Install all other packages using `yum install clamav git file`
    * The EPEL Repository is required, as RHEL/CentOS do not package clamav in their base or extra repositories.
    * Some variants of CentOS may not include freshclam in the clamav package. If your CentOS does not include this, you also need use `yum install clamav-update`
  * For Debian/Ubuntu, install directly from the repositories using `apt-get install clamav git file`
* Step 2: Create a Malscan directory, and navigate into it:
  * `mkdir /usr/local/share/malscan && cd /usr/local/share/malscan`
* Step 3: Clone this git repository with `git clone https://github.com/jgrancell/Malscan.git`
* Step 4: Move the repository into the /usr/local/share/malscan directory directly with `rsync -avzP /usr/local/share/malscan/Malscan /usr/local/share/malscan && rm -rf /usr/local/share/malscan/Malscan`
* Step 5: Copy the `conf.malscan-blank` file to `conf-malscan` and replace all of the example information with your own custom information.
* Step 6: Create the Malscan executable with the command `ln -s /usr/local/share/malscan/malscan.sh /usr/local/bin/malscan`
* Step 5: Run the update.sh script to update the Malscan signatures with `/usr/local/share/malscan/update.sh`
* Step 6: Set the update.sh to run at least daily through `crontab -e` setting the cronjob to run daily
  * Daily: `0 2 * * * /usr/local/share/malscan/update.sh`
  * Twice Daily: `0 */2 * * * /usr/local/share/malscan/update.sh`
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
    * Installer may work with other 6.x and 7.x RHEL derivatives as well as Ubuntu 12.x, 13.x, 14.x, and 15.x, however these are officially unsupported.
    * If you run into issues with any non-supported Operating Systems, please submit a Github issue so that I can correct it and add that OS to the supported list.
    * Added package installation sanity checking, to ensure everything is set up properly
* Updated Mimetype scanning to add additional filetypes to the scan.
* Updated a substantial number of prompts, both in text and color.


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
