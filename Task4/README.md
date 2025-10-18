| Роль| Права роли | Группы пользователей                               | 
|-----|------------|----------------------------------------------------|
|security-auditor | get, list, watch на все ресурсы (включая секреты), но без модификации | security-team, compliance-team   |
|namespace-developer |	Полный доступ в пределах неймспейсов: get, list, create, update, delete, patch (исключая секреты и RBAC) | dev-team-sales, dev-team-housing, dev-team-finance |
| namespace-viewer | get, list, watch в пределах назначенных неймспейсов (исключая секреты) | business-analysts, product-managers, qa-team   |
| secret-manager | Полный доступ к секретам в пределах неймспейсов | devops-team, security-specialist   |
|finance-reader	|только чтение для финансового домена | analyst-finance    |

##### Скрипт для создания пользователей

create-users.sh:

```
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

```

##### Скрипт для создания RBAC ролей

create-roles.sh:
```
#!/bin/bash

echo "=== Создание RBAC ролей для PropDevelopment ==="

# 1. Роль security-auditor (просмотр всех ресурсов включая секреты)
echo "Создание роли security-auditor..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: security-auditor
  labels:
    domain: security
    created-by: rbac-setup
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch"]
EOF

# 2. Роль namespace-developer (разработчик в неймспейсе)
echo "Создание роли namespace-developer..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-developer
  labels:
    domain: development
    created-by: rbac-setup
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "persistentvolumeclaims", "pods/log"]
  verbs: ["*"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["*"]
- apiGroups: ["batch"]
  resources: ["jobs", "cronjobs"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: []  # Явно запрещаем доступ к секретам
EOF

# 3. Роль namespace-viewer (только просмотр)
echo "Создание роли namespace-viewer..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-viewer
  labels:
    domain: business
    created-by: rbac-setup
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "persistentvolumeclaims"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: []  # Запрет просмотра секретов
EOF

# 4. Роль secret-manager (управление секретами)
echo "Создание роли secret-manager..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-manager
  labels:
    domain: security
    created-by: rbac-setup
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "create", "update", "delete", "patch"]
EOF

# 5. Роль finance-reader (только чтение для финансового домена)
echo "Создание роли finance-reader..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: finance-reader
  labels:
    domain: finance
    created-by: rbac-setup
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
EOF

echo "=== Роли созданы ==="
kubectl get clusterroles -l created-by=rbac-setup
```
#####  Скрипт для создания привязок ролей

create-rolebindings.sh:
```
#!/bin/bash

echo "=== Создание RBAC привязок для PropDevelopment ==="

# 1. Привязка security-auditor для security-user (Cluster-wide)
echo "Создание привязки security-auditor-binding..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: security-auditor-binding
  labels:
    domain: security
    created-by: rbac-setup
subjects:
- kind: ServiceAccount
  name: security-user
  namespace: default
roleRef:
  kind: ClusterRole
  name: security-auditor
  apiGroup: rbac.authorization.k8s.io
EOF

# 2. Привязка namespace-developer для dev-sales-user (только в неймспейсе sales)
echo "Создание привязки sales-developer-binding..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sales-developer-binding
  namespace: sales
  labels:
    domain: sales
    created-by: rbac-setup
subjects:
- kind: ServiceAccount
  name: dev-sales-user
  namespace: sales
roleRef:
  kind: ClusterRole
  name: namespace-developer
  apiGroup: rbac.authorization.k8s.io
EOF

# 3. Привязка namespace-developer для dev-housing-user (только в неймспейсе housing)
echo "Создание привязки housing-developer-binding..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: housing-developer-binding
  namespace: housing
  labels:
    domain: housing
    created-by: rbac-setup
subjects:
- kind: ServiceAccount
  name: dev-housing-user
  namespace: housing
roleRef:
  kind: ClusterRole
  name: namespace-developer
  apiGroup: rbac.authorization.k8s.io
EOF

# 4. Привязка namespace-viewer для business-analyst-user (Cluster-wide)
echo "Создание привязки business-analyst-viewer-binding..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: business-analyst-viewer-binding
  labels:
    domain: business
    created-by: rbac-setup
subjects:
- kind: ServiceAccount
  name: business-analyst-user
  namespace: default
roleRef:
  kind: ClusterRole
  name: namespace-viewer
  apiGroup: rbac.authorization.k8s.io
EOF

# 5. Привязка secret-manager для devops-user (Cluster-wide)
echo "Создание привязки devops-secret-manager-binding..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: devops-secret-manager-binding
  labels:
    domain: devops
    created-by: rbac-setup
subjects:
- kind: ServiceAccount
  name: devops-user
  namespace: default
roleRef:
  kind: ClusterRole
  name: secret-manager
  apiGroup: rbac.authorization.k8s.io
EOF

# 6. Привязка finance-reader для просмотра финансового неймспейса
echo "Создание привязки finance-reader-binding..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: finance-reader-binding
  namespace: finance
  labels:
    domain: finance
    created-by: rbac-setup
subjects:
- kind: ServiceAccount
  name: business-analyst-user
  namespace: default
roleRef:
  kind: ClusterRole
  name: finance-reader
  apiGroup: rbac.authorization.k8s.io
EOF

echo "=== Привязки ролей созданы ==="
echo "ClusterRoleBindings:"
kubectl get clusterrolebindings -l created-by=rbac-setup

echo -e "\nRoleBindings:"
kubectl get rolebindings --all-namespaces -l created-by=rbac-setup
```
##### Скрипт для проверки RBAC
verify-rbac.sh:
```
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
```
##### Инструкция по запуску

```
# Даем права на выполнение
chmod +x create-users.sh create-roles.sh create-rolebindings.sh verify-rbac.sh

# Запускаем в последовательности
./create-users.sh
./create-roles.sh  
./create-rolebindings.sh
./verify-rbac.sh

# Или одной командой
./create-users.sh && ./create-roles.sh && ./create-rolebindings.sh && ./verify-rbac.sh
```