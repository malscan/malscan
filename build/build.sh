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

VERSION="$1"
DISTRO="$2"

if [[ "$VERSION" == "ci" ]]; then
  PACKAGE_VERSION=$(cat /home/makerpm/rpmbuild/malscan/version.txt | cut -d- -f1)
else
  PACKAGE_VERSION=$VERSION
fi

# Deleting everything
rm -rf "/home/makerpm/rpmbuild/malscan-1*"
rm -rf "/home/makerpm/rpmbuild/BUILD/***"
rm -rf "/home/makerpm/rpmbuild/BUILDROOT/***"
rm -rf "/home/makerpm/rpmbuild/SOURCES/***"

# Creating a temp working directory
TEMP=$(mktemp -d)
mkdir -p "$TEMP/malscan-$PACKAGE_VERSION"

# Moving into the malscan directory
cd /home/makerpm/rpmbuild

## Creating the file structure for the SOURCE tarball
rsync -avzP --exclude ".git" --exclude ".gitignore" --exclude ".codeclimate.yml" --exclude "build" /home/makerpm/rpmbuild/malscan/ "$TEMP/malscan-$PACKAGE_VERSION/"

## Packaging the files
cd "$TEMP"
tar -czvf "$TEMP/malscan-$PACKAGE_VERSION.tar.gz" "malscan-$PACKAGE_VERSION"

# Moving the newly packaged files into the build sources directory
mv "$TEMP/malscan-$PACKAGE_VERSION.tar.gz" "/home/makerpm/rpmbuild/SOURCES/"

## Copying the latest SPEC files from our git repo into SPECS
cp "/home/makerpm/rpmbuild/malscan/build/malscan-$DISTRO.spec" "/home/makerpm/rpmbuild/SPECS/malscan-$DISTRO.spec"

## Moving back into our pwd
cd /home/makerpm/rpmbuild

## Deleting the temp directory and all of its staging contents
rm -rf "$TEMP"

## Finishing up the source build
echo "Staging of all malscan files completed. Beginning build process."

## Creating the RPM
rpmbuild -ba /home/makerpm/rpmbuild/SPECS/malscan-$DISTRO.spec

echo "Builds complete for Malscan $PACKAGE_VERSION"
