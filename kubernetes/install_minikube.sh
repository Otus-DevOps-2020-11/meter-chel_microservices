#!/bin/bash

echo
echo Установка служб
sudo apt-get update
sudo apt install -y wget curl apt-transport-https ca-certificates conntrack
clear

echo
echo Установка MinuKube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo chmod +x minikube
sudo mkdir -p /usr/local/bin/
sudo install minikube /usr/local/bin/

echo
echo Установка Kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
echo
kubectl version --client

sleep 15
echo
minikube start
sleep 5
kubectl get po -A
echo

kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4
kubectl expose deployment hello-minikube --type=NodePort --port=8080
minikube service hello-minikube

minikube dashboard
