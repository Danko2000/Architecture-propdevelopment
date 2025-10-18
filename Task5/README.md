###  Создание сервисов

create-services.sh:\
```
#!/bin/bash
echo "=== СОЗДАНИЕ СЕРВИСОВ ==="

kubectl run front-end-app --image=nginx --labels=role=front-end --expose --port=80
kubectl run back-end-api-app --image=nginx --labels=role=back-end-api --expose --port=80
kubectl run admin-front-end-app --image=nginx --labels=role=admin-front-end --expose --port=80
kubectl run admin-back-end-api-app --image=nginx --labels=role=admin-back-end-api --expose --port=80

echo -e "\n✅ Сервисы созданы:"
kubectl get pods,services --show-labels
```

###  Создание сетевых политик 

network-policies.yaml:
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: allow-frontend-to-backend
spec:
podSelector:
matchLabels:
role: back-end-api
policyTypes:
- Ingress
  ingress:
- from:
    - podSelector:
      matchLabels:
      role: front-end
      ports:
    - protocol: TCP
      port: 80

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: allow-admin-frontend-to-admin-backend
spec:
podSelector:
matchLabels:
role: admin-back-end-api
policyTypes:
- Ingress
  ingress:
- from:
    - podSelector:
      matchLabels:
      role: admin-front-end
      ports:
    - protocol: TCP
      port: 80

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: allow-frontend-egress
spec:
podSelector:
matchLabels:
role: front-end
policyTypes:
- Egress
  egress:
- to:
    - podSelector:
      matchLabels:
      role: back-end-api
      ports:
    - protocol: TCP
      port: 80
- to:
    - namespaceSelector:
      matchLabels:
      kubernetes.io/metadata.name: kube-system
      podSelector:
      matchLabels:
      k8s-app: kube-dns
      ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: allow-admin-frontend-egress
spec:
podSelector:
matchLabels:
role: admin-front-end
policyTypes:
- Egress
  egress:
- to:
    - podSelector:
      matchLabels:
      role: admin-back-end-api
      ports:
    - protocol: TCP
      port: 80
- to:
    - namespaceSelector:
      matchLabels:
      kubernetes.io/metadata.name: kube-system
      podSelector:
      matchLabels:
      k8s-app: kube-dns
      ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: allow-backend-egress
spec:
podSelector:
matchLabels:
role: back-end-api
policyTypes:
- Egress
  egress: []

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: allow-admin-backend-egress
spec:
podSelector:
matchLabels:
role: admin-back-end-api
policyTypes:
- Egress
  egress: []

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: deny-all-ingress
spec:
podSelector: {}
policyTypes:
- Ingress
  ingress: []
```
### Проверка сетевых политик

test-policies.sh:
```
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
```
### Очистка сетевых политик
```
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
```

###  Команды для запуска

#### 1. Создание сервисов
./create-services.sh

#### 2. Подождать пока поды запустятся (30 секунд)
sleep 30

#### 3. Применить политики
kubectl apply -f network-policies.yaml

#### 4. Протестировать
./test-policies.sh

#### 5. Очистить
./cleanup-all.sh

