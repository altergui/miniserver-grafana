#!/bin/sh

apt install --no-install-recommends prometheus prometheus-node-exporter
( cd files/ ; cp --archive --backup=numbered ./ / )
