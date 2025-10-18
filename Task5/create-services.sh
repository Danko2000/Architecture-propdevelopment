#!/bin/bash

echo "=== Создание сервисов с метками в namespace default ==="

# Создание front-end сервиса
kubectl run front-end-app --image=nginx --labels=role=front-end --expose --port=80

# Создание back-end-api сервиса  
kubectl run back-end-api-app --image=nginx --labels=role=back-end-api --expose --port=80

# Создание admin-front-end сервиса
kubectl run admin-front-end-app --image=nginx --labels=role=admin-front-end --expose --port=80

# Создание admin-back-end-api сервиса
kubectl run admin-back-end-api-app --image=nginx --labels=role=admin-back-end-api --expose --port=80

echo "=== Сервисы созданы ==="
kubectl get pods,services --show-labels