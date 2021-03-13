#!/bin/bash

add-apt-repository ppa:longsleep/golang-backports
apt update -y
apt install golang-go -y
go get -u github.com/yandex-cloud/docker-machine-driver-yandex
export PATH=$PATH:$HOME/go/bin
docker-machine create \
--driver yandex \
--yandex-image-family "ubuntu-1804-lts" \
--yandex-platform-id "standard-v1" \
--yandex-folder-id $FOLDER_ID \
--yandex-sa-key-file $SA_KEY_PATH \
--yandex-memory "4" \
logging
