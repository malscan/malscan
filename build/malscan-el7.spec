Summary: Linux malware scanner for web servers
Name: malscan
Version: 1.7.0
Release: rc8.el7
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
install version.txt ${RPM_BUILD_ROOT}/usr/local/share/malscan/version.txt

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
%attr(644,malscan,malscan) /usr/local/share/malscan/version.txt
%doc /usr/local/share/man/man1/malscan.1

%changelog
* Thu Dec 24 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-rc7
- Fixed: Updated RPM build pipeline

* Thu Oct 06 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-rc6
- Fixed: Logs will now have the correct date and time for each entry

* Thu Oct 06 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-rc5
- New: Added pid locking. Only one copy of malscan can run at a time, now.

* Thu Oct 06 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-rc4
- Fixed broken rc3 release

* Thu Oct 06 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-rc3
- Fixed: Configuration options can now only be set by the root user, not by a user in the malscan group (updates #12)

* Thu Oct 06 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-rc2
- Updated: Build number bump for package testing

* Thu Jul 11 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-rc1
- New: Configuration options can now be viewed using the malscan -c command. (fixes #10)
- New: Configuration options can now be set using the malscan -s OPTION value command.
- New: Initial packaging of ClamAV databases to make the first `malscan -u` command run substantially faster.
- Fixed: malscan will now correctly check for sudo
- Fixed: malscan will now check to see if the user is in the malscan group, in lieu of being run as sudo
- Updated: malscan will now use its own freshclam.conf file and /var/lib/malscan signatures directory, to prevent conflicts with ClamAV
- Updated: The malscan file structure has been updated to conform with the FHS. (fixes #7)
- Updated: Removed whitelisting and tripwire scanning until it can be re-worked in a later release
- Updated: Removed reporting until it can be re-developed in a later release.
- Updated: Rewrote the install.sh script to support Fedora, Debian, and CentOS/RHEL 7
- Updated: Created RPM packaging for CentOS/RHEL 6, 7, and Fedora 22/23/24 (fixes #8)
