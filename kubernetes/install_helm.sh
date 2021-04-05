#!/bin/bash

curl https://get.helm.sh/helm-v2.17.0-linux-amd64.tar.gz | tar -zxv
sudo mv linux-amd64/helm /usr/local/bin/helm
sudo mv linux-amd64/tiller /usr/local/bin/tiller
rm -R linux-amd64/
tiller -version
