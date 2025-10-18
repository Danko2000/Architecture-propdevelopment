#!/bin/bash

echo "=== ПОЛНАЯ ОЧИСТКА КЛАСТЕРА ==="

echo -e "\n🗑️ Удаляем сетевые политики..."
kubectl delete networkpolicy --all

echo -e "\n🗑️ Удаляем поды и сервисы..."
kubectl delete pod,service -l role

echo -e "\n🗑️ Удаляем тестовые поды..."
kubectl delete pod -l run --field-selector=status.phase!=Running 2>/dev/null || true

echo -e "\n🔍 Проверяем что очистилось:"
echo "Поды:"
kubectl get pods --show-labels | grep -E "(front-end|back-end|admin-)"

echo -e "\nСервисы:"
kubectl get services | grep -E "(front-end|back-end|admin-)"

echo -e "\nСетевые политики:"
kubectl get networkpolicies

echo -e "\n✅ ОЧИСТКА ЗАВЕРШЕНА"