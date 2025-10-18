#!/bin/bash

echo "=== Создание пользователей Kubernetes для PropDevelopment ==="

# Создание неймспейсов для доменов компании
echo "Создание неймспейсов..."
kubectl create namespace sales --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace housing --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace finance --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace data --dry-run=client -o yaml | kubectl apply -f -

# Создание ServiceAccount для различных ролей
echo "Создание ServiceAccounts..."

# Пользователь для команды безопасности
kubectl create serviceaccount security-user --namespace=default --dry-run=client -o yaml | kubectl apply -f -

# Пользователь для разработчиков сервисов продаж
kubectl create serviceaccount dev-sales-user --namespace=sales --dry-run=client -o yaml | kubectl apply -f -

# Пользователь для бизнес-аналитиков
kubectl create serviceaccount business-analyst-user --namespace=default --dry-run=client -o yaml | kubectl apply -f -

# Пользователь для DevOps команды
kubectl create serviceaccount devops-user --namespace=default --dry-run=client -o yaml | kubectl apply -f -

# Пользователь для разработчиков ЖКУ
kubectl create serviceaccount dev-housing-user --namespace=housing --dry-run=client -o yaml | kubectl apply -f -

echo "=== Пользователи созданы ==="
kubectl get serviceaccounts --all-namespaces | grep -E "(security-user|dev-sales-user|business-analyst-user|devops-user|dev-housing-user)"