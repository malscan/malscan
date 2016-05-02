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
RELEASE="$2"

# Deleting everything
rm -rf "/home/jgrancell/rpmbuild/malscan-1*"
rm -rf "/home/jgrancell/rpmbuild/BUILD/***"
rm -rf "/home/jgrancell/rpmbuild/BUILDROOT/***"
rm -rf "/home/jgrancell/rpmbuild/SOURCES/***"

# Creating a temp working directory
TEMP=$(mktemp -d)
mkdir -p "$TEMP/malscan-$VERSION"

# Moving into the malscan directory
cd /home/jgrancell/rpmbuild/malscan
git fetch
git pull
cd /home/jgrancell/rpmbuild

## Creating the file structure for the SOURCE tarball
rsync -avzP --exclude ".git" --exclude ".gitignore" --exclude "malscan.spec" --exclude "build-malscan.sh" /home/jgrancell/rpmbuild/malscan/ "$TEMP/malscan-$VERSION/"

## Packaging the files
cd "$TEMP"
tar -czvf "$TEMP/malscan-$VERSION.tar.gz" "malscan-$VERSION"

# Moving the newly packaged files into the build sources directory
mv "$TEMP/malscan-$VERSION.tar.gz" "/home/jgrancell/rpmbuild/SOURCES/"

## Copying the latest SPEC files from our git repo into SPECS
cp "/home/jgrancell/rpmbuild/malscan/malscan-el7.spec" "/home/jgrancell/rpmbuild/SPECS/malscan-el7.spec"
# cp "/home/jgrancell/rpmbuild/malscan/malscan.spec" "/home/jgrancell/rpmbuild/SPECS/malscan-el6.spec"
cp "/home/jgrancell/rpmbuild/malscan/malscan-fedora23.spec" "/home/jgrancell/rpmbuild/SPECS/malscan-fedora23.spec"

## Moving back into our pwd
cd /home/jgrancell/rpmbuild

## Deleting the temp directory and all of its staging contents
rm -rf "$TEMP"

## Finishing up the source build
echo "Staging of all malscan files completed. Beginning build process."

## Creating the RPM
rpmbuild -ba /home/jgrancell/rpmbuild/SPECS/malscan-el7.spec
# rpmbuild -ba /home/jgrancell/rpmbuild/SPECS/malscan-el6.spec
rpmbuild -ba /home/jgrancell/rpmbuild/SPECS/malscan-fedora23.spec

## Doing the RPM signing
rpm --define="%_gpg_name Josh Grancell <josh@joshgrancell.com>" --resign "/home/jgrancell/rpmbuild/RPMS/noarch/malscan-$1-$2.el7.noarch.rpm"
# rpm --define="%_gpg_name Josh Grancell <josh@joshgrancell.com>" --resign "/home/jgrancell/rpmbuild/RPMS/noarch/malscan-$1-$2.el6.noarch.rpm"
rpm --define="%_gpg_name Josh Grancell <josh@joshgrancell.com>" --resign "/home/jgrancell/rpmbuild/RPMS/noarch/malscan-$1-$2.fedora23.noarch.rpm"

## Pushing the new .rpms to the repository
package_cloud push jgrancell/malscan/el/7 RPMS/noarch/malscan-$1-$2.el7.noarch.rpm
package_cloud push jgrancell/malscan/fedora/23 RPMS/noarch/malscan-$1-$2.fedora23.noarch.rpm