malscan
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

malscan is a scanning platform for Linux servers that simplifies keeping your
web servers secure and malware-free. It is built upon the ClamAV platform,
providing all of the features of Clamscan with a host of new features and
detection modes.

## Features
* Multiple channels of malware signatures
    * RFX Networks Signatures
    * Metasploit Signatures
    * malscan Signatures
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

## Licensing and Terms of Usage

The malscan application is released under the MIT license, which is included in the repository. This software is provided as is, with absolutely no warranty provided for it. As this application does alter file/directory structure for this server, make sure that you understand exactly what this application does and the security ramifications of it.
