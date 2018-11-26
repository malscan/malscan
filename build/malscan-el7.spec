Summary: Linux malware scanner for web servers
Name: malscan
Version: 1.8.1
Release: 1.el7
URL:     https://github.com/jgrancell/malscan
License: MIT
Group: Applications/System
BuildRoot: %{_tmppath}/%{name}-root
Requires: bash wget file epel-release
Requires: clamav clamav-update
Requires: malscan-db
Source0: malscan-%{version}.tar.gz
BuildArch: noarch

%description
Malscan is a linux malware scanner developed for web servers and desktops, to provide additional signatures and scanning mechanisms to ClamAV.

%prep
%setup

%build

%pre
getent group malscan >/dev/null || groupadd -r malscan
getent passwd malscan >/dev/null || useradd -r -g malscan -s /sbin/nologin -c "Malscan Service User" malscan
exit 0

%install
rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}/etc/malscan
mkdir -p ${RPM_BUILD_ROOT}/usr/local/share/malscan
mkdir -p ${RPM_BUILD_ROOT}/usr/local/bin
mkdir -p ${RPM_BUILD_ROOT}/var/lib/malscan
mkdir -p ${RPM_BUILD_ROOT}/var/log/malscan
mkdir -p ${RPM_BUILD_ROOT}/usr/local/share/man/man1

install malscan.conf ${RPM_BUILD_ROOT}/etc/malscan/malscan.conf
install freshclam.conf ${RPM_BUILD_ROOT}/etc/malscan/freshclam.conf
install malscan ${RPM_BUILD_ROOT}/usr/local/bin/malscan
install malscan.1 ${RPM_BUILD_ROOT}/usr/local/share/man/man1/malscan.1
install LICENSE ${RPM_BUILD_ROOT}/usr/local/share/malscan/malscan.license

%clean
rm -rf ${RPM_BUILD_ROOT}

%post

%files
%defattr(-,root,root)
%config(noreplace) %attr(644,root,root) /etc/malscan/malscan.conf
%config(noreplace) %attr(644,root,root) /etc/malscan/freshclam.conf
%attr(755,root,root) /usr/local/bin/malscan
%dir %attr(755,malscan,malscan) /usr/local/share/malscan
%dir %attr(755,malscan,malscan) /var/lib/malscan
%dir %attr(755,malscan,malscan) /var/log/malscan
%attr(644,malscan,malscan) /usr/local/share/malscan/malscan.license
%doc /usr/local/share/man/man1/malscan.1

%changelog
* Mon Nov 26 2018 Josh Grancell <jgrancell@malscan.com> 1.8.1-1
- Fixed: Malscan now provides better information when attempting a run with the lockfile present.

* Tue Oct 16 2018 Josh Grancell <jgrancell@malscan.com> 1.8.0-1
- Updated: Fixed some non-portable code in the mimescan function.
- Updated: Cleaned up some shellcheck notices in the avscan function.

* Mon May 7 2018 Josh Grancell <jgrancell@malscan.com> 1.7.2-1
- Fixed: Updater will now properly pull the malscan core version from the right git branch.
- Updated: Updated all documentation to point to new docs site and new 1.x branch

* Fri Apr 20 2018 Josh Grancell <jgrancell@malscan.org> 1.7.1-2
- Updated: Changed the save path for the Tripwire whitelist file

* Fri Apr 20 2018 Josh Grancell <jgrancell@malscan.org> 1.7.1-1
- New: Tripwire detection mode
- Fixed: Corrected permission issue on log file. (fixes #15)

* Thu Mar 22 2018 Josh Grancell <jgrancell@malscan.org> 1.7.0-1
- Feature: Lock files are used to ensure multiple runs of malscan don't stack.
- Feature: Configuration options can now be viewed using the malscan -c command. (fixes #10)
- Feature: Configuration options can now be set using the malscan -s OPTION value command.
- Fixed: malscan will now correctly check for sudo.
- Fixed: malscan will now check to see if the user is in the malscan group, in lieu of being run as sudo.
- Fixed: Notifications are now sent in a more spam-checker-friendly format, reducing issues with notifications ending up in the spam folder.
- Updated: malscan will now use its own freshclam.conf file and /var/lib/malscan signatures directory, to prevent conflicts with ClamAV.
- Updated: The malscan file structure has been updated to conform with the FHS. (fixes #7)
- Updated: Rewrote the install.sh script to support Fedora, Debian, and CentOS/RHEL 7.
- Updated: New exhaustive build testing CI pipeline for automated malscan testing.
- Removed: Removed whitelisting and tripwire scanning until it can be re-worked in a later release.
- Removed: Removed reporting until it can be re-developed in a later release.
- Removed: Removed Ubuntu/Debian support while working on packaging.

* Fri Sep 4 2015 Josh Grancell <jgrancell@malscan.org> 1.5.3-1
- Bugfix: Corrected text coloring on the update.sh script to terminate properly
- Bugfix: Removed some excess text from the Mimescan
- Updated: All malscan runs now include the current Malscan version and the time that signatures were last updated.
- Updated: Unified logging files for all scantypes into a single scan log for each scan
- Feature: Added new -u update functionality, which updates both the core application as well as the signatures

* Mon Jul 13 2015 Josh Grancell <jgrancell@malscan.org> 1.5.2-1
- Bugfix: Corrected the Mimetype scan to properly ignore files listed in conf.malscan

* Tue Jun 16 2015 Josh Grancell <jgrancell@malscan.org> 1.5.1-1
- Bugfix: Corrected a bug with update.sh causing a fatal error.
- Updated: Added output identifying when different scan types are starting, for more verbose and informative output.
- Updated: Incremented the version in malscan.sh
- Updated: Removed the version information in the comment header in install.sh, added a Since version header instead.
- Updated: Removed the output text from the freshclam updater, which was getting too messy.
- Updated: Added a warning in update.sh indicating the now-silent freshclam update portion can take a long time.

* Mon Jun 1 2015 Josh Grancell <jgrancell@malscan.org> 1.5.0-1
- Feature: Added automated whitelisting of file trees for known clean files (such as imports from development enviroments or fresh installs)
- Feature: New Tripwire scanning mode. Identifies any files that have been changed or did not exist from the whitelist reference. Excellent for static sites or minimally changing applications.
- Updated: Mimetype scanning to add additional filetypes to the scan.
- Updated: A substantial number of prompts, both in text and color.

* Wed May 6 2015 Josh Grancell <jgrancell@malscan.org> 1.4.4-1
- Bugfix: Corrected an issue with notifications not being sent because there was no way to specify receiving email addresses. Fixed in conf.malscan-blank.
- Bugfix: Corrected an issue with whitelisting not working properly. It should now function correctly, and is working in test RHEL 6 and CentOS 7 testing environments.
- Special Note: The changes to conf.malscan-blank will need to be manually added to any active conf.malscan files.

* Tue May 5 2015 Josh Grancell <jgrancell@malscan.org> 1.4.3-1
- Bugfix: Corrected a logging path issue. All log files will now be correctly generated in the 'log' directory inside your chosen path in conf.malscan
- Bugfix: Corrected the URL for the custom virus definitions
- Feature: Included freshclam updates within the cron_update.sh script

* Thu Apr 9 2015 Josh Grancell <jgrancell@malscan.org> 1.4.2-1
- Bugfix: Corrected an error with the AV-Scan whitelisting functionality, causing malscan to ignore whitelistings. It is now working properly.

* Wed Mar 18 2015 Josh Grancell <jgrancell@malscan.org> 1.4.1-1
- Bugfix: Proper detection of the malscan program path when run as a cronjob or from outside of the Malscan directory.

* Mon Mar 16 2015 Josh Grancell <jgrancell@malscan.org> 1.4.0-1
- First offical public release
