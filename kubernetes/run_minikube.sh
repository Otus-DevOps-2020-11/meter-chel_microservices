#!/bin/bash

minikube start
sleep 5

kubectl get po -A

minikube dashboard
