Malscan
============

Robust ClamAV-based malware scanner for web servers.

[![GitHub version](https://img.shields.io/badge/version-1.7.0-green.svg)](https://github.com/jgrancell/malscan)
[![Build status](https://gitlab.com/malscan/malscan/badges/master/pipeline.svg)](https://gitlab.com/malscan/malscan/commits/master)

# Table of Contents
* [Features](#features)
* [Requirements](#requirements)
* [Installation](#installation)
* [Changelog](#changelog)

## Summary

Malscan is a robust and fully featured scanning platform for Linux servers that greatly simplifies keeping your web servers secure and malware-free. It is built upon the ClamAV platform, providing all of the features of Clamscan with a host of new features and detection modes.

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
  * Tripwire detection mode - identifies files that have changed (or new files that have been created) to a known base filetree state.
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

__NOTE__: New installation procedures will be deployed shortly for CentOS 6, 7, Fedora, and Puppet Community/Enterprise.

#### CentOS 6, CentOS 7

Repositories are available for CentOS and RHEL 6 and 7, as well as Fedora 27 and 26. Installation instructions for these repositories can be found at https://www.malscan.org/getting-started/ .  If you do not (or cannot) install repositories, you can use the automated installation script by following these steps:

* Run the following command from within the terminal to install Malscan automatically: `wget https://raw.githubusercontent.com/jgrancell/malscan/master/install.sh && bash install.sh`
* Follow the guided installer in the terminal to complete the installation, configuration, and initial whitelisting process.

#### Other Operating Systems

Generally, the installer steps should work on all other RHEL derivatives. If you run into specific installer issues with any non-supported Operating Systems or versions, please submit an issue and or pull request to add support for it.

Malscan can be manually installed on any operating system that successfully meets the System Requirements listed above. This can be done by following the steps outlined below.
* Install all software dependencies with your OS's package manager (or from source):
  * clamav
  * clamav-update (your package manager may name it clamav-update or clamav-db)
  * bash
  * file
  * wget
  * sendmail
* Create the required malscan directories.
  * mkdir /usr/local/share/malscan
  * mkdir /etc/malscan
  * mkdir /var/lib/malscan
  * mkdir /var/log/malscan
  * mkdir /root/.malscan/quarantine
* Place the following files in the listed locations:
  * wget -P "/etc/malscan/" "https://gitlab.com/malscan/malscan/raw/master/malscan.conf"
  * wget -P "/etc/malscan/" "https://gitlab.com/malscan/malscan/raw/master/freshclam.conf"
  * wget -P "/usr/local/share/man/man1/" "https://gitlab.com/malscan/malscan/raw/master/malscan.1"
  * wget -P "/usr/local/bin/" "https://gitlab.com/malscan/malscan/raw/master/malscan"
  * wget -P "/usr/local/share/malscan/" "https://gitlab.com/malscan/malscan/raw/master/version.txt"
* Create a malscan user and group, and assign any users that you would like to use malscan to the malscan group
  * groupadd -r malscan
  * useradd -r -g malscan -s /sbin/nologin -c "Malscan Service User" malscan
  * usermod -a -G malscan your_user
* Make the binary executable with chmod +x /usr/local/bin/malscan

## Usage

See `malscan -h` for more detailed program usage.

## Contributing

If you're interested in contributing to malscan, I am looking for the following help:

* Feature development
* Documentation
* Web design
* Logo design

Contact me at `jgrancell@malscan.org` or `josh@joshgrancell.com` if you're interested.

## Changelog

#### Version 1.7.1
*Release: April 20, 2018*
* New: Tripwire detection mode
* Fixed: Corrected permission issue on log file. (fixes #15)
* Updated: Changed the save path for the Tripwire whitelist file

#### Version 1.7.0
*Release: March 22, 2018*
* Feature: Lock files are used to ensure multiple runs of malscan don't stack.
* Feature: Configuration options can now be viewed using the malscan -c command. (fixes #10)
* Feature: Configuration options can now be set using the malscan -s OPTION value command.
* Fixed: malscan will now correctly check for sudo.
* Fixed: malscan will now check to see if the user is in the malscan group, in lieu of being run as sudo.
* Fixed: Notifications are now sent in a more spam-checker-friendly format, reducing issues with notifications ending up in the spam folder.
* Updated: malscan will now use its own freshclam.conf file and /var/lib/malscan signatures directory, to prevent conflicts with ClamAV.
* Updated: The malscan file structure has been updated to conform with the FHS. (fixes #7)
* Updated: Rewrote the install.sh script to support Fedora, Debian, and CentOS/RHEL 7.
* Updated: Created RPM packaging for CentOS/RHEL 6, 7, and Fedora 26/27. (fixes #8)
* Updated: New exhaustive build testing CI pipeline for automated malscan testing.
* Removed: Removed whitelisting and tripwire scanning until it can be re-worked in a later release.
* Removed: Removed reporting until it can be re-developed in a later release.
* Removed: Removed Ubuntu/Debian support while working on packaging.

#### Version 1.5.3
*Release: September 4, 2015*
* Bugfix: Corrected text coloring on the update.sh script to terminate properly
* Bugfix: Removed some excess text from the Mimescan
* Updated: All malscan runs now include the current Malscan version and the time that signatures were last updated.
* Updated: Unified logging files for all scantypes into a single scan log for each scan
* Feature: Added new -u update functionality, which updates both the core application as well as the signatures

#### Version 1.5.2
*Release: July 13, 2015*
* Bugfix: Corrected the Mimetype scan to properly ignore files listed in conf.malscan

#### Version 1.5.1
*Release: June 16, 2015*
* Bugfix: Corrected a bug with update.sh causing a fatal error.
* Updated: Added output identifying when different scan types are starting, for more verbose and informative output.
* Updated: Incremented the version in malscan.sh
* Updated: Removed the version information in the comment header in install.sh, added a Since version header instead.
* Updated: Removed the output text from the freshclam updater, which was getting too messy.
* Updated: Added a warning in update.sh indicating the now-silent freshclam update portion can take a long time.

#### Version 1.5.0
*Release: June 1, 2015*
* Feature: Added automated whitelisting of file trees for known clean files (such as imports from development enviroments or fresh installs)
* Feature: New Tripwire scanning mode. Identifies any files that have been changed or did not exist from the whitelist reference. Excellent for static sites or minimally changing applications.
* Feature: New installer.
  * New installer is compatible with and fully tested on CentOS 6, CentOS 7, and Ubuntu 14.04.
    * Installer may work with other 6.x and 7.x RHEL derivatives as well as Ubuntu 12.x, 13.x, 14.x, and 15.x, however these are officially unsupported.
    * If you run into issues with any non-supported Operating Systems, please submit a Github issue so that I can correct it and add that OS to the supported list.
    * Added package installation sanity checking, to ensure everything is set up properly
  * New installer may work with other RHEL derivatives as well as RHEL/CentOS 5
* Updated: Mimetype scanning to add additional filetypes to the scan.
* Updated: A substantial number of prompts, both in text and color.

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

The Malscan application is released under the MIT license, which is included in the repository. This software is provided as is, with absolutely no warranty provided for it. As this application does alter file/directory structure for this server, make sure that you understand exactly what this application does and the security ramifications of it.
