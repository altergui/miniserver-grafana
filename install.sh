#!/bin/sh

apt install --no-install-recommends prometheus-node-exporter
( cd files/ ; cp --archive --backup=numbered ./ / )

# Install Grafana OSS according to https://grafana.com/docs/grafana/latest/installation/debian/
apt install -y apt-transport-https
apt install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
apt update
apt install grafana

systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
# end Grafana

# Install VictoriaMetrics (unavailable in buster as of 2021/03/31)
cd /tmp

wget http://ftp.debian.org/debian/pool/main/libz/libzstd/libzstd1_1.4.8+dfsg-2.1_arm64.deb
dpkg --skip-same-version -i libzstd1_1.4.8+dfsg-2.1_arm64.deb
rm libzstd1_1.4.8+dfsg-2.1_arm64.deb

wget http://ftp.debian.org/debian/pool/main/v/victoriametrics/victoria-metrics_1.53.1+ds-1+b1_arm64.deb
dpkg --skip-same-version -i victoria-metrics_1.53.1+ds-1+b1_arm64.deb
rm victoria-metrics_1.53.1+ds-1+b1_arm64.deb

( cd files/ ; cp --archive --backup=numbered ./etc/default/victoria-metrics /etc/default/victoria-metrics )

systemctl restart victoria-metrics

# end VictoriaMetrics
