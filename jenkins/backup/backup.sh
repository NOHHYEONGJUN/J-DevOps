#!/bin/bash

# 환경 변수 설정
JENKINS_NAMESPACE="jenkins"
JENKINS_POD=$(kubectl get pods -n $JENKINS_NAMESPACE -l app.kubernetes.io/name=jenkins -o jsonpath="{.items[0].metadata.name}")
BACKUP_DIR="/home/ubuntu/backup/backup-files/"
DATE=$(date +%Y%m%d_%H%M%S)

# 백업 디렉토리 생성
# mkdir -p $BACKUP_DIR


# 0. Jenkins 홈 디렉토리 내용 확인
echo "Checking Jenkins home directory contents..."
kubectl exec -n $JENKINS_NAMESPACE $JENKINS_POD -- ls -la /var/jenkins_home/


# 1. Jenkins 설정 파일 백업
echo "Backing up Jenkins configuration..."
kubectl exec -n $JENKINS_NAMESPACE $JENKINS_POD -- tar czf - -C /var/jenkins_home \
    $(kubectl exec -n $JENKINS_NAMESPACE $JENKINS_POD -- find /var/jenkins_home \
    -maxdepth 1 \( \
    -name "plugins" -o \
    -name "jobs" -o \
    -name "secrets" -o \
    -name "config.xml" -o \
    -name "credentials.xml" -o \
    -name "userContent" \) \
    -printf "%P\n") > $BACKUP_DIR/jenkins_backup_$DATE.tar.gz


# 2. Helm 설정 백업
echo "Backing up Helm values..."
helm get values jenkins -n $JENKINS_NAMESPACE > $BACKUP_DIR/helm_values_$DATE.yaml

# 3. PVC 데이터 백업 (선택사항)
echo "Backing up PVC data..."
kubectl get pvc -n $JENKINS_NAMESPACE -o yaml > $BACKUP_DIR/pvc_backup_$DATE.yaml

# 4. 백업 파일 압축
echo "Compressing backup files..."
tar czf $BACKUP_DIR/complete_backup_$DATE.tar.gz $BACKUP_DIR/*_$DATE.*

# 5. 오래된 백업 삭제 (30일 이상)
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed successfully!"