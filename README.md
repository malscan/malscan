Malscan
============

Robust ClamAV-based malware scanner for web servers.


[![Build Status](https://travis-ci.org/malscan/malscan.svg?branch=refactor)](https://travis-ci.org/malscan/malscan)
[![codecov](https://codecov.io/gh/malscan/malscan/branch/refactor/graph/badge.svg)](https://codecov.io/gh/malscan/malscan)
[![Maintainability](https://api.codeclimate.com/v1/badges/6853e74c03949aeb009e/maintainability)](https://codeclimate.com/github/malscan/malscan/maintainability)
[![Code Quality](https://scrutinizer-ci.com/g/malscan/malscan/badges/quality-score.png?b=refactor)](https://scrutinizer-ci.com/g/malscan/malscan/?branch=refactor)

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
  * Python 2.7+ or 3+
* SSH Access

## Installation

The purpose of the refactor branch is to rewrite Malscan, previously written in shell script, into Python.
If you are interested in participating in the rewrite contact me directly at `jgrancell@malscan.com`.
If you're just interested in using Malscan, look at the `master` branch or visit https://docs.malscan.com

## Usage

See `malscan help` for more detailed program usage.

## Contributing

The purpose of the refactor branch is to rewrite Malscan, previously written in shell script, into Python.
If you are interested in participating in the rewrite contact me directly at `jgrancell@malscan.com`.

## Changelog

#### Version 2.0.0-dev0
*Release: April 20, 2018*
* In progress development rewrite

## Licensing and Terms of Usage

The Malscan application is released under the MIT license, which is included in the repository. This software is provided as is, with absolutely no warranty provided for it. As this application does alter file/directory structure for this server, make sure that you understand exactly what this application does and the security ramifications of it.
