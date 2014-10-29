#!/bin/bash

# Copyright Stamus Networks
# All rights reserved
# Debian Live/Install ISO script - oss@stamus-networks.com
#
# Please run on Debian Wheezy

set -e

# Begin
# Pre staging
#
mkdir -p Stamus-Live-Build
cd Stamus-Live-Build && lb config -a amd64 -d wheezy --debian-installer live \
--bootappend-live "boot=live config username=selks-user live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,bluetooth,netdev,sudo" \
--iso-application SELKS - Suricata Elasticsearch Logstash Kibana Scirius \
--iso-preparer Stamus Networks --iso-publisher Stamus Networks \
--iso-volume Stamus-SELKS $LB_CONFIG_OPTIONS

# create dirs if not existing for the custom config files
mkdir -p config/includes.chroot/etc/logstash/conf.d/
mkdir -p config/includes.chroot/etc/skel/.local/share/applications/
mkdir -p config/includes.chroot/etc/skel/Desktop/
mkdir -p config/includes.chroot/usr/share/applications/
mkdir -p config/includes.chroot/etc/iceweasel/profile/
mkdir -p config/includes.chroot/etc/logrotate.d/
mkdir -p config/includes.chroot/etc/default/
mkdir -p config/includes.chroot/etc/init.d/
mkdir -p config/includes.binary/isolinux/
mkdir -p config/includes.chroot/etc/nginx/sites-available/
mkdir -p config/includes.chroot/var/log/suricata/StatsByDate/
mkdir -p config/includes.chroot/etc/logrotate.d/
mkdir -p config/includes.chroot/usr/share/images/desktop-base/
mkdir -p config/includes.chroot/opt/selks/
mkdir -p config/includes.chroot/etc/suricata/rules/
mkdir -p config/includes.chroot/etc/kibana/
mkdir -p config/includes.chroot/etc/profile.d/
mkdir -p config/includes.chroot/root/Desktop/
# kibana install
mkdir -p config/includes.chroot/var/www && \
tar -C config/includes.chroot/var/www --strip=1 -xzf ../staging/stamus/kibana-3.1.0-stamus.tgz

cd config/includes.chroot/opt/selks/ && \
git clone -b scirius-0.4 https://github.com/StamusNetworks/scirius.git
cd ../../../../../


# reverse proxy with nginx and ssl
cp staging/etc/nginx/sites-available/stamus.conf  Stamus-Live-Build/config/includes.chroot/etc/nginx/sites-available/
# copy kibana config
cp staging/etc/kibana/config.js  Stamus-Live-Build/config/includes.chroot/etc/kibana/
# cp README and LICENSE files to the user's desktop
cp LICENSE Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
cat README.rst | sed -e 's/https:\/\/your.selks.IP.here/http:\/\/selks/' | rst2html > Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/README.html
# the same as above but for root
cp LICENSE Stamus-Live-Build/config/includes.chroot/root/Desktop/
cat README.rst | sed -e 's/https:\/\/your.selks.IP.here/http:\/\/selks/' | rst2html > Stamus-Live-Build/config/includes.chroot/root/Desktop/README.html
# logstash
cp staging/etc/logstash/conf.d/logstash.conf Stamus-Live-Build/config/includes.chroot/etc/logstash/conf.d/ 
cp staging/etc/logstash/conf.d/logstash-bro22-parse.conf Stamus-Live-Build/config/includes.chroot/etc/logstash/conf.d/ 
# suricata init script
cp staging/etc/default/suricata Stamus-Live-Build/config/includes.chroot/etc/default/
cp staging/etc/init.d/suricata Stamus-Live-Build/config/includes.chroot/etc/init.d/
# Iceweasel bookmarks
cp staging/etc/iceweasel/profile/bookmarks.html Stamus-Live-Build/config/includes.chroot/etc/iceweasel/profile/
# logrotate config for eve.json
cp staging/etc/logrotate.d/suricata Stamus-Live-Build/config/includes.chroot/etc/logrotate.d/
# add the Stmaus Networs logo for the boot screen
cp staging/splash.png Stamus-Live-Build/config/includes.binary/isolinux/
# add the SELKS wallpaper
cp staging/wallpaper/joy-wallpaper_1920x1080.svg Stamus-Live-Build/config/includes.chroot/usr/share/images/desktop-base/
# copy banners
cp staging/etc/motd Stamus-Live-Build/config/includes.chroot/etc/
cp staging/etc/issue.net Stamus-Live-Build/config/includes.chroot/etc/
# install scirius db
mkdir -p Stamus-Live-Build/config/includes.chroot/opt/selks/scirius/db/
cp staging/scirius/local_settings.py Stamus-Live-Build/config/includes.chroot/opt/selks/scirius/scirius/
# copy suricata.yaml using scirius.rules
cp staging/scirius/suricata.yaml Stamus-Live-Build/config/includes.chroot/etc/suricata
cp staging/etc/profile.d/pythonpath.sh Stamus-Live-Build/config/includes.chroot/etc/profile.d/
# copy init script for suri_reloader
cp staging/scirius/suri_reloader Stamus-Live-Build/config/includes.chroot/etc/init.d/
# copy init script for djando
cp staging/scirius/django-init Stamus-Live-Build/config/includes.chroot/etc/init.d/django

# add packages to be installed
echo "
libpcre3 libpcre3-dbg libpcre3-dev 
build-essential autoconf automake libtool libpcap-dev libnet1-dev 
libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 
make flex bison git git-core libmagic-dev libnuma-dev pkg-config
libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0 
ethtool bwm-ng iptraf htop libjansson-dev libjansson4 libnss3-dev libnspr4-dev 
libgeoip1 libgeoip-dev openjdk-7-jre-headless
rsync wireshark tcpreplay sysstat hping3 screen terminator ngrep tcpflow 
dsniff mc python-daemon libnss3-tools curl 
python-crypto libgmp10 libyaml-0-2 python-simplejson
python-yaml ssh sudo tcpdump nginx openssl 
python-pip lxde debian-installer-launcher " \
>> Stamus-Live-Build/config/package-lists/StamusNetworks.list.chroot

# add packages to be installed (required by Bro)
echo "
cmake make libpcap-dev libssl-dev python-dev swig " \
>> Stamus-Live-Build/config/package-lists/StamusNetworks.list.chroot

# add specific tasks(script file) to be executed 
# inside the chroot environment
cp staging/config/hooks/chroot-inside-Debian-Live.chroot Stamus-Live-Build/config/hooks/
# Edit the menues names - add  Stamus
cp staging/config/hooks/menues-changes.binary Stamus-Live-Build/config/hooks/

# debian installer preseed.cfg
echo "
d-i netcfg/get_hostname string SELKS

d-i passwd/user-fullname string selks-user User
d-i passwd/username string selks-user
d-i passwd/user-password password selks-user
d-i passwd/user-password-again password selks-user
d-i passwd/user-default-groups string audio cdrom floppy video dip plugdev scanner bluetooth netdev sudo

d-i passwd/root-password password StamusNetworks
d-i passwd/root-password-again password StamusNetworks
" > Stamus-Live-Build/config/debian-installer/preseed.cfg

# build the ISO
cd Stamus-Live-Build && ( lb build 2>&1 | tee build.log )
mv binary.hybrid.iso SELKS.iso
