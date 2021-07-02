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

( cd files/ ; cp --archive --backup=numbered ./etc/grafana/grafana.ini /etc/grafana/grafana.ini )

systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
# end Grafana

# Install Loki (and promtail) according to https://grafana.com/docs/loki/latest/installation/local/
apt update
apt install unzip
wget https://github.com/grafana/loki/releases/download/v2.2.1/loki-linux-arm64.zip
unzip loki-linux-arm64.zip
chmod a+x "loki-linux-arm64"
mv loki-linux-arm64 /usr/local/bin/loki
wget https://raw.githubusercontent.com/grafana/loki/master/cmd/loki/loki-local-config.yaml
sed -i 's,/tmp/loki,/data/loki,g' loki-local-config.yaml
sed -i 's,/tmp/wal,/data/loki/wal,g' loki-local-config.yaml
sed -i 's/retention_period: 0s/retention_period: 1440h # 60 days/' loki-local-config.yaml
sed -i 's/retention_deletes_enabled: false/retention_deletes_enabled: true/' loki-local-config.yaml
sed -i 's/max_look_back_period: 0s/max_look_back_period: 1440h # 60 days/' loki-local-config.yaml
mv loki-local-config.yaml /etc/loki-config.yaml
### run it with systemd:
useradd --system loki --home-dir /data/loki
cat << EOF > /etc/systemd/system/loki.service
[Unit]
Description=Loki service
After=network.target

[Service]
Type=simple
User=loki
ExecStart=/usr/local/bin/loki -config.file /etc/loki-config.yaml

[Install]
WantedBy=multi-user.target
EOF
systemctl enable loki.service
### service loki start
### service loki status

wget https://github.com/grafana/loki/releases/download/v2.2.1/promtail-linux-arm64.zip
unzip promtail-linux-arm64.zip
chmod a+x "promtail-linux-arm64"
mv promtail-linux-arm64 /usr/local/bin/promtail
cat << EOF > /etc/loki-promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /data/loki/promtail-positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
- job_name: syslog
  syslog:
    listen_address: 0.0.0.0:1514
    labels:
      job: "syslog"
  relabel_configs:
    - source_labels: ['__syslog_message_hostname']
      target_label: 'host'
EOF
### then systemd
cat << EOF > /etc/systemd/system/loki-promtail.service
[Unit]
Description=Loki promtail service
After=network.target

[Service]
Type=simple
User=loki
ExecStart=/usr/local/bin/promtail -config.file /etc/loki-promtail-config.yaml

[Install]
WantedBy=multi-user.target
EOF
systemctl enable loki-promtail.service
### service loki start
### service loki status

### finally, configure rsyslog as a "gateway" to support ingesting udp and rfc3164
### which promtail currently doesn't support (and probably never will)
cat << EOF > /etc/rsyslog.d/remote.conf
# provides UDP syslog reception
module(load="imudp")
input(type="imudp" port="514")

# provides TCP syslog reception
module(load="imtcp")
input(type="imtcp" port="514")

*.* @@(o)127.0.0.1:1514;RSYSLOG_SyslogProtocol23Format
:fromhost-ip , !isequal , "127.0.0.1" stop
EOF
### /etc/init.d/rsyslog restart
# end Loki

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
