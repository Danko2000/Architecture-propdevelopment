#!/bin/bash

echo "=== Проверка RBAC настроек PropDevelopment ==="

echo -e "\n1. Проверка security-user (должен видеть секреты):"
kubectl auth can-i get secrets --as=system:serviceaccount:default:security-user

echo -e "\n2. Проверка dev-sales-user к секретам в sales (должен быть запрещен):"
kubectl auth can-i get secrets --as=system:serviceaccount:sales:dev-sales-user -n sales

echo -e "\n3. Проверка dev-sales-user к deployment в sales (должен быть разрешен):"
kubectl auth can-i create deployments --as=system:serviceaccount:sales:dev-sales-user -n sales

echo -e "\n4. Проверка business-analyst-user на создание pod (должен быть запрещен):"
kubectl auth can-i create pods --as=system:serviceaccount:default:business-analyst-user

echo -e "\n5. Проверка business-analyst-user на просмотр pod в finance (должен быть разрешен):"
kubectl auth can-i get pods --as=system:serviceaccount:default:business-analyst-user -n finance

echo -e "\n6. Проверка devops-user к секретам (должен быть разрешен):"
kubectl auth can-i create secrets --as=system:serviceaccount:default:devops-user

echo -e "\n7. Проверка dev-housing-user к ресурсам в housing (должен быть разрешен):"
kubectl auth can-i create deployments --as=system:serviceaccount:housing:dev-housing-user -n housing

echo -e "\n8. Проверка dev-housing-user к ресурсам в sales (должен быть запрещен):"
kubectl auth can-i get pods --as=system:serviceaccount:housing:dev-housing-user -n sales

echo -e "\n=== Проверка завершена ==="