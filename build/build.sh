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

if [[ "$VERSION" == "ci" ]]; then
  PACKAGE_VERSION=$(cat /home/makerpm/rpmbuild/malscan/version.txt | cut -d- -f1)
  RPM_VERSION=$(cat /home/makerpm/rpmbuild/malscan/version.txt)
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
cd /home/makerpm/rpmbuild || exit 1

## Creating the file structure for the SOURCE tarball
rsync -avzP --exclude ".git" --exclude ".gitlab-ci.yml" --exclude ".gitignore" --exclude ".codeclimate.yml" --exclude "build" /home/makerpm/rpmbuild/malscan/ "$TEMP/malscan-$PACKAGE_VERSION/"

## Packaging the files
cd "$TEMP" || exit 1
tar -czvf "$TEMP/malscan-$PACKAGE_VERSION.tar.gz" "malscan-$PACKAGE_VERSION"

# Moving the newly packaged files into the build sources directory
mv "$TEMP/malscan-$PACKAGE_VERSION.tar.gz" "/home/makerpm/rpmbuild/SOURCES/"

## Copying the latest SPEC files from our git repo into SPECS
cp "/home/makerpm/rpmbuild/malscan/build/malscan-el7.spec" "/home/makerpm/rpmbuild/SPECS/malscan-el7.spec"
cp "/home/makerpm/rpmbuild/malscan/build/malscan-el6.spec" "/home/makerpm/rpmbuild/SPECS/malscan-el6.spec"
cp "/home/makerpm/rpmbuild/malscan/build/malscan-fedora.spec" "/home/makerpm/rpmbuild/SPECS/malscan-fedora.spec"

## Moving back into our pwd
cd /home/makerpm/rpmbuild || exit 1

## Deleting the temp directory and all of its staging contents
rm -rf "$TEMP"

## Finishing up the source build
echo "Staging of all malscan files completed. Beginning build process."

## Creating the RPM
rpmbuild -ba /home/makerpm/rpmbuild/SPECS/malscan-el7.spec
rpmbuild -ba /home/makerpm/rpmbuild/SPECS/malscan-el6.spec
rpmbuild -ba /home/makerpm/rpmbuild/SPECS/malscan-fedora.spec

echo "Builds complete for Malscan $PACKAGE_VERSION"

echo "Beginning RPM signing."
## Doing the RPM signing
for RPM in `ls /home/makerpm/rpmbuild/RPMS/noarch/`; do
  echo "Now signing $RPM"
  /home/makerpm/rpmbuild/malscan/build/sign.exp "/home/makerpm/rpmbuild/RPMS/noarch/$RPM"
done

echo "Uploading RPMs to AWS S3"
aws s3 sync "/home/makerpm/rpmbuild/RPMS/noarch/" s3://yum.malscan.org/el/7/ --exclude="*el6*" --exclude="*fedora*"
aws s3 sync "/home/makerpm/rpmbuild/RPMS/noarch/" s3://yum.malscan.org/el/6/ --exclude="*el7*" --exclude="*fedora*"
aws s3 sync "/home/makerpm/rpmbuild/RPMS/noarch/" s3://yum.malscan.org/fedora/26/ --exclude="*el6*" --exclude="*el7*"
aws s3 sync "/home/makerpm/rpmbuild/RPMS/noarch/" s3://yum.malscan.org/fedora/27/ --exclude="*el6*" --exclude="*el7*"
aws s3 sync "/home/makerpm/rpmbuild/RPMS/noarch/" s3://yum.malscan.org/fedora/28/ --exclude="*el6*" --exclude="*el7*"
