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