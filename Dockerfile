FROM alpine:latest as build

FROM alpine:latest
LABEL maintainer="Josh Grancell <jgrancell@malscan.com>"

## Installing ClamAV
RUN apk add --update \
  bash \
  clamav \
  file \
  unrar \
  wget

## Installing Malscan
RUN adduser -D -H -s /bin/false malscan \
  && mkdir -p /etc/malscan /usr/local/share/malscan /var/lib/malscan /var/log/malscan \
  && chown malscan:malscan /var/lib/malscan /etc/malscan /usr/local/share/malscan /var/log/malscan

COPY malscan.conf /etc/malscan/malscan.conf
COPY freshclam.conf /etc/malscan/freshclam.conf
COPY malscan /usr/local/bin/malscan

RUN chmod +x /usr/local/bin/malscan \
  && /usr/local/bin/malscan -u
