Summary: Linux malware scanner for web servers
Name: malscan
Version: 1.7.0
Release: dev2
URL:     https://github.com/jgrancell/malscan
License: MIT
Group: Applications/System
BuildRoot: %{_tmppath}/%{name}-root
Requires: bash epel-release
Requires: clamav clamav-update
Source0: malscan-%{version}.tar.gz
BuildArch: noarch

%description
Malscan is a linux malware scanner developed for web servers and desktops, to provide additional signatures and scanning mechanisms to ClamAV.

%prep
%setup

%build

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

%files
%defattr(-,root,root)
%config(noreplace) /etc/malscan.conf
%doc /usr/local/share/man/man1/malscan.1
%attr(644,root,root) /etc/malscan.conf
%attr(755,root,root) /usr/local/bin/malscan
%attr(644,root,root) /usr/local/share/malscan/malscan.license

%changelog
* Thu Apr 21 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev2
- Bugfix: Corrected a redirect of stderr that was causing bash to fatal error
- Update: Removed several unused variables

* Thu Apr 21 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev1
- New: Initial rpm packaging



