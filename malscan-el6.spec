Summary: Linux malware scanner for web servers
Name: malscan
Version: 1.7.0
Release: dev18.el6
URL:     https://github.com/jgrancell/malscan
License: MIT
Group: Applications/System
BuildRoot: %{_tmppath}/%{name}-root
Requires: bash epel-release
Requires: clamav clamav-db
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
mkdir -p ${RPM_BUILD_ROOT}/etc
mkdir -p ${RPM_BUILD_ROOT}/usr/local/share/malscan
mkdir -p ${RPM_BUILD_ROOT}/usr/local/bin
mkdir -p ${RPM_BUILD_ROOT}/var/lib/malscan
mkdir -p ${RPM_BUILD_ROOT}/var/log/malscan
mkdir -p ${RPM_BUILD_ROOT}/usr/local/share/man/man1

install malscan.conf ${RPM_BUILD_ROOT}/etc/malscan.conf
install malscan.sh ${RPM_BUILD_ROOT}/usr/local/bin/malscan
install malscan.1 ${RPM_BUILD_ROOT}/usr/local/share/man/man1/malscan.1
install LICENSE ${RPM_BUILD_ROOT}/usr/local/share/malscan/malscan.license

%clean
rm -rf ${RPM_BUILD_ROOT}

%post
sed -i 's/^Example.*$//g' /etc/freshclam.conf
sed -i 's/^#DatabaseOwner.*$/DatabaseOwner malscan/g' /etc/freshclam.conf

%files
%defattr(-,root,root)
%config(noreplace) %attr(644,root,root) /etc/malscan.conf
%attr(755,root,root) /usr/local/bin/malscan
%dir %attr(755,malscan,malscan) /usr/local/share/malscan
%dir %attr(755,malscan,malscan) /var/lib/malscan
%dir %attr(755,malscan,malscan) /var/log/malscan
%attr(644,malscan,malscan) /usr/local/share/malscan/malscan.license
%doc /usr/local/share/man/man1/malscan.1

%changelog
* Thu Jun 09 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev18
- Bugfix: Corrected a typo in output

* Wed Jun 08 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev17
- New: Config information can now be changed using the -s switch.

* Wed Jun 08 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev16
- Bugfix: Corrected a mismatch between RPM version and application version.

* Mon May 02 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev15
- New: Finished the display for config information via the -c switch.
- Bugfix: Fixed a missplelling in the malscan.conf file with the STRING_LENGTH_MINIMUM variable.
- Bugfix: Fixed a bug where the helper function wasn't correctly executing because of location.
- Updated: Malscan will now exit properly when either -v or -c are called, rather than attempting to run a scan afterwards.

* Mon May 02 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev14
- Bugfix: The correct version number will be shown for the main program now.
- Updated: Updated how the Update function will output status updates. Less empty lines, more consise code.
- Updated: Updated indenting for the Update function, bringing it in line with all other functions' output.
- Updated: Removed the empty line from the -v command.

* Mon May 02 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev13
- Bugfix: Removed several lines of unused code.
- Bugfix: Updated the notification sender to only work when a detection has been made.
- Bugfix: Moved the helper exit up to the beginning of the file.

* Sun May 01 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev12
- New: Initial parsing for the -c configuration and -s set options have been completed.
- Bugfix: Sudo checking will now correctly identify when it's being run by the malscan user directly.
- Updated: Rewrote the argument parser. Removed about 30% of the code while using proper bash builtins.

* Sat Apr 30 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev11
- Bugfix: Updater will now correctly check for sudo before attempting to update.
- Bugfix: Removed some currently unused arguments from the --help command output.

* Mon Apr 25 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev10
- New: Fedora packaging testing
- Bugfix: Corrected an issue in the build process with duplicate files.
- Update: All directories and files should now be properly owned by the malscan user.

* Sat Apr 23 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev9
- New: Warning message when running updater as a non-root user that not everything will update without root.
- Bugfix: Removed freshclam from the updater when a non-root user is identified.
- Bugfix: Updated the rfxn database updates to correctly assign malscan:malscan ownership

* Sat Apr 23 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev8
- New: Added permissions checking. User must be root or a member of the malscan group now.

* Sat Apr 23 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev7
- Bugfix: Removed a chown that was no longer needed
- Bugfix: Corrected a variable name that was preventing the AV scan from working
- Bugfix: Corrected an issue where the first update run wouldn't be able to get the date of previous non-existant updates. It shows "Never" now.

* Sat Apr 23 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev6
- Bugfix: Fixed how the rpm updates the /etc/freshclam.conf file's DatabaseOwner variable

* Sat Apr 23 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev5
- Bugfix: Updated /etc/freshclam.conf to use the new malscan user.
- Bugfix: Updated /etc/freshclam.conf to remove the 'Example' text that stops updates.
- Bugfix: Corrected an issue where the malscan user wasn't being created.

* Fri Apr 22 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev4
- New: Added malscan user/group to the installation process.
- New: Added 775 malscan:malscan permission for /var/lib/malscan to allow freshclam to write to it.
- New: Added clamupdate to the malscan group.

* Thu Apr 21 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev3
- Bugfix: RPM will now correctly build the /var/lib/malscan database directory
- Bugfix: RPM will now correctly build the /var/log/malscan logging directory
- Bugfix: Several clamscan entries removed from the man page
- Bugfix: Misspelling fixed in the man page

* Thu Apr 21 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev2
- Bugfix: Corrected a redirect of stderr that was causing bash to fatal error
- Update: Removed several unused variables

* Thu Apr 21 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev1
- New: Initial rpm packaging



