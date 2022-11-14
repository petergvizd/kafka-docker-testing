#!/bin/bash

set -x

SCRIPT_PATH=$(dirname -- "$0")

docker-compose -f $SCRIPT_PATH/docker-compose.yaml up kafka-admin

sleep 30

docker-compose -f $SCRIPT_PATH/docker-compose.yaml up broker-1 broker-2 broker-3

kind create cluster --name kafka --image=kindest/node:v1.20.15

docker network connect kafka-docker kafka-control-plane

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager -n kube-system --version v1.5.3 --set installCRDs=true --kube-context kind-kafka

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/prometheus -n monitoring --create-namespace --version 15.14.0 --values $SCRIPT_PATH/prometheus.yaml --kube-context kind-kafka

helm repo add strimzi https://strimzi.io/charts
helm repo update
helm upgrade --install strimzi-kafka-operator strimzi/strimzi-kafka-operator -n kafka-k8s --create-namespace --version 0.27.1 --kube-context kind-kafka

kubectl apply -f $SCRIPT_PATH/kubernetes/kafka-docker
kubectl apply -f $SCRIPT_PATH/kubernetes/kafka-docker

kubectl apply -f $SCRIPT_PATH/kubernetes/kafka-k8s
