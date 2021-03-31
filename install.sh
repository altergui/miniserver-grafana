#!/bin/sh

apt install --no-install-recommends prometheus prometheus-node-exporter
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
