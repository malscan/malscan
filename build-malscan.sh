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

VERSION="$1"

# Deleting everything
rm -rf "/home/makerpm/rpmbuild/malscan***"
rm -rf "/home/makerpm/rpmbuild/BUILD/***"
rm -rf "/home/makerpm/rpmbuild/BUILDROOT/***"
rm -rf "/home/makerpm/rpmbuild/SOURCES/***"

# Creating a temp working directory
TEMP=$(mktemp -d)
mkdir -p "$TEMP/malscan-$VERSION"

rsync -avzP --exclude ".git" --exclude ".gitignore" --exclude "malscan.spec" --exclude "build-malscan.sh" /home/makerpm/rpmbuild/malscan/ "$TEMP/malscan-$VERSION/"

## Packaging the files
cd "$TEMP"
tar -czvf "$TEMP/malscan-$VERSION.tar.gz" "malscan-$VERSION"

# Moving the newly packaged files into the build sources directory
mv "$TEMP/malscan-$VERSION.tar.gz" "/home/makerpm/rpmbuild/SOURCES/"

cp "/home/makerpm/rpmbuild/malscan/malscan.spec" "/home/makerpm/rpmbuild/SPECS/malscan.spec"

## Deleting the temp directory and all of its staging contents
rm -rf "$TEMP"

## Finishing up
echo "Staging of all malscan files completed. Update the SPEC file with the correct version number and changelog."
exit 0
