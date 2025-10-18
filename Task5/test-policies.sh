#!/bin/bash

echo "=== ТЕСТИРОВАНИЕ СЕТЕВЫХ ПОЛИТИК ==="

# Ждем пока поды запустятся
echo -e "\n⏳ Ожидаем запуск подов..."
kubectl wait --for=condition=Ready pod -l role --timeout=60s

echo -e "\n📋 Состояние системы:"
kubectl get pods,services,networkpolicies

echo -e "\n🔍 ТЕСТЫ:"

echo "1. front-end -> back-end-api (должно РАБОТАТЬ):"
kubectl exec front-end-app -- curl -s --connect-timeout 3 http://back-end-api-app > /dev/null 2>&1 && echo "✅ СВЯЗЬ ЕСТЬ" || echo "❌ СВЯЗИ НЕТ"

echo "2. admin-front-end -> admin-back-end-api (должно РАБОТАТЬ):"
kubectl exec admin-front-end-app -- curl -s --connect-timeout 3 http://admin-back-end-api-app > /dev/null 2>&1 && echo "✅ СВЯЗЬ ЕСТЬ" || echo "❌ СВЯЗИ НЕТ"

echo "3. front-end -> admin-back-end-api (должно БЛОКИРОВАТЬСЯ):"
kubectl exec front-end-app -- curl -s --connect-timeout 3 http://admin-back-end-api-app > /dev/null 2>&1 && echo "❌ ОШИБКА" || echo "✅ ЗАБЛОКИРОВАНО"

echo "4. admin-front-end -> back-end-api (должно БЛОКИРОВАТЬСЯ):"
kubectl exec admin-front-end-app -- curl -s --connect-timeout 3 http://back-end-api-app > /dev/null 2>&1 && echo "❌ ОШИБКА" || echo "✅ ЗАБЛОКИРОВАНО"

echo "5. Внешний доступ -> back-end-api (должно БЛОКИРОВАТЬСЯ):"
kubectl run external-test --rm -i -t --image=alpine --restart=Never -- sh -c 'wget -qO- --timeout=3 http://back-end-api-app > /dev/null 2>&1 && echo "❌ ОШИБКА" || echo "✅ ЗАБЛОКИРОВАНО"' 2>/dev/null

echo -e "\n🎉 ТЕСТИРОВАНИЕ ЗАВЕРШЕНО"