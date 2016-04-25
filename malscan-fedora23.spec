Summary: Linux malware scanner for web servers
Name: malscan
Version: 1.7.0
Release: dev10.fedora23
URL:     https://github.com/jgrancell/malscan
License: MIT
Group: Applications/System
BuildRoot: %{_tmppath}/%{name}-root
Requires: bash
Requires: clamav clamav-update
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
%config(noreplace) /etc/malscan.conf
%doc /usr/local/share/man/man1/malscan.1
%attr(644,root,root) /etc/malscan.conf
%attr(755,root,root) /usr/local/bin/malscan
%attr(644,root,root) /usr/local/share/malscan/malscan.license
%dir /usr/local/share/malscan
%dir /var/lib/malscan
%dir /var/log/malscan
%attr (755,malscan,malscan) /var/lib/malscan

%changelog
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



