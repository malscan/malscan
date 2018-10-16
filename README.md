Malscan
============

ClamAV-based malware scanner for Linux web servers.

[![Latest version](https://img.shields.io/github/release/malscan/malscan.svg)](https://github.com/malscan/malscan/releases)
[![GitHub license](https://img.shields.io/github/license/malscan/malscan.svg)](https://github.com/malscan/malscan/blob/1.x/LICENSE)
[![Build status](https://gitlab.com/malscan/malscan/badges/1.x/pipeline.svg)](https://gitlab.com/malscan/malscan/pipelines)

# Table of Contents
* [Features](#features)
* [Requirements](#requirements)
* [Installation](#installation)
* [Changelog](#changelog)

## Summary

Malscan is a scanning platform for Linux servers that simplifies keeping your
web servers secure and malware-free. It is built upon the ClamAV platform,
providing all of the features of Clamscan with a host of new features and
detection modes.

## Features
* Multiple channels of malware signatures
    * RFX Networks Signatures
    * Metasploit Signatures
    * Malscan Signatures
    * ClamAV Main Signatures
* Multiple Detection Methods
    * Standard HEX or MD5 based detections
        * Includes a database of over 30,000 signatures
        * Uses both HEX and hash based detections
    * String length detections
        * Identifies long obfuscated strings.
        * Non-signature based, to help detect zero day code injections
    * MimeType mismatch detections
        * Detects PHP files that are masquerading as other file types.
        * Identifies certain common obfuscated attack vectors, such as command
        shells hiding as `.png` files.
    * Tripwire detection mode
        * Allows you to whitelist files in a known clean configuration.
        * Compares the file tree to previously whitelisted states to identify changes.
        * Can be hooked into common deploy tools, such as `capistrano` or `dpl`.
* Easy File Quarantining
* Custom email notifications

## Requirements
* Linux Server / Desktop
* Full root access, or the ability to install:
  * ClamAV
  * File
  * Postfix or Exim, if using email notifications.
* SSH Access

## Installation

__NOTE__: New installation procedures will be deployed shortly for CentOS 6, 7, Fedora, and Puppet Community/Enterprise.

#### Puppet

Puppet is the primary supported installation method for malscan.

The malscan Puppet module is currently under development. You can find the
status of the module's development [here](https://github.com/malscan/puppetmodule)

#### Red Hat Enterprise Linux, CentOS, and Fedora

RPM packages are available for RHEL, CentOS, and Fedora. Packages are generated
only for currently supported operating systems. Support includes:

| Operating System | Version |           |
| :--------------: | :-----: | :-------: |
|   RHEL / CentOS  |    7    | ![](https://img.shields.io/badge/supported-yes-blue.svg) |
|   RHEL / CentOS  |    6    | ![](https://img.shields.io/badge/supported-yes-blue.svg) |
|      Fedora      |    28   | ![](https://img.shields.io/badge/supported-yes-blue.svg) |
|      Fedora      |    27   | ![](https://img.shields.io/badge/supported-yes-blue.svg) |
|      Fedora      |    26   | ![](https://img.shields.io/badge/supported-no-red.svg) |

To set up the yum repository, install one of the three below RPM files depending on your distribution and version:

* RHEL/CentOS 7: `https://yum.malscan.org/malscan-release-el-7.rpm`
* RHEL/CentOS 6: `https://yum.malscan.org/malscan-release-el-6.rpm`
* Fedora (all versions): `https://yum.malscan.org/malscan-release-fedora.rpm`

#### Other Operating Systems

We make every effort to support as many operating systems as possible. Currently, we
officially support the following operating systems:

* Alpine Linux
* Debian
* Unbuntu (LTS only)

All of the above are supported via the malscan installer. This installer will automatically
identify your operating system, and install required dependencies.

**NOTE:** For Alpine Linux, you *must* install bash before you can run the installer.

To install via the installer on a supported system, simply run:

``` bash
curl -sSL https://get.malscan.com | bash
```

We strongly recommend reading through the installer before running it. Running scripts
without knowing what they do is dumb.

## Usage

See `malscan -h` for more detailed program usage.

## Contributing

If you're interested in contributing to malscan, I am looking for the following help:

* Feature development
* Documentation
* Web design
* Logo design

Contact me at `jgrancell@malscan.com` if you're interested.

## Changelog

#### Version 1.8.0
*Release: Oct 18, 2018*
* Fixed: Installer was referencing bad download URLs
* Fixed: `which` may not be available in some distributions.
* Updated: Added support for Ubuntu 16.04 and 18.04
* Updated: Added support for Debian 8 and 9.
* Updated: Added support for Alpine Linux.

#### Version 1.7.2-1
*Release: May 15, 2018*
* Fixed: Updater will now properly pull the malscan core version from the right git branch.
* Updated: Updated all documentation to point to new docs site and new 1.x branch

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
