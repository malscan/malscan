FROM alpine:latest
MAINTAINER Josh Grancell <jgrancell@malscan.com>

# Building Directory Structure
RUN mkdir /usr/local/share/malscan \
      /etc/malscan \
      /var/lib/malscan \
      /var/log/malscan \
      /root/.malscan \
      /root/.malscan/quarantine

COPY malscan.conf /etc/malscan/malscan.conf
COPY malscan /usr/local/bin/malscan
COPY version.txt /usr/local/share/malscan/version.txt

ADD http://database.clamav.net/main.cvd /var/lib/malscan/main.cvd
ADD http://database.clamav.net/daily.cvd /var/lib/malscan/daily.cvd
ADD http://database.clamav.net/bytecode.cvd /var/lib/malscan/bytecode.cvd
ADD https://www.rfxn.com/downloads/rfxn.hdb /var/lib/malscan/rfxn.hdb
ADD https://www.rfxn.com/downloads/rfxn.ndb /var/lib/malscan/rfxn.ndb

RUN apk update && apk add bash clamav wget curl postfix

CMD ["/bin/bash", "/usr/local/bin/malscan", "-al", "/code"]
