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