Summary: Linux malware scanner for web servers
Name: malscan
Version: 1.7.0
Release: dev.4
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
* Sat Feb 13 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev.4
- Bugfix: Corrected the configuration file loading path

* Sat Feb 13 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev.3
- Bugfix: Correcting a flaw in pre-build compiling

* Sat Feb 13 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev.2
- Bug Fix: Corrected an invalid argument
- Bug Fix: Removed several sections of unused code

* Sat Feb 13 2016 Josh Grancell <josh@joshgrancell.com> 1.7.0-dev.1
- Feature: Initial packaging test for malscan

