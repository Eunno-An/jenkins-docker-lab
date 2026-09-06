#!/usr/bin/env bash
# macOS / Linux 용 — Jenkins(Docker) + Docker Desktop Kubernetes 실습 환경 준비
set -e

echo "1) Docker 동작 확인"
docker info > /dev/null 2>&1 || { echo "❌ Docker가 실행 중이 아닙니다. Docker Desktop을 먼저 실행하세요."; exit 1; }
echo "   OK"

echo "2) Docker Desktop Kubernetes 컨텍스트 확인"
if ! kubectl config get-contexts docker-desktop > /dev/null 2>&1; then
  echo "❌ 'docker-desktop' 컨텍스트를 찾을 수 없습니다."
  echo "   Docker Desktop > Settings > Kubernetes > Enable Kubernetes 를 켜고 Apply & Restart 하세요."
  exit 1
fi
echo "   OK"

echo "3) kubeconfig 경로를 .env 파일에 기록"
echo "KUBE_CONFIG_PATH=$HOME/.kube/config" > .env
cat .env

echo "4) 네임스페이스 생성 (dev / staging / production)"
kubectl --context docker-desktop apply -f k8s/namespaces.yaml

echo "5) Jenkins 컨테이너 빌드 및 기동 (최초 실행 시 수 분 소요될 수 있습니다)"
docker compose up -d --build

echo ""
echo "완료되면 http://localhost:8080 (admin / admin123!) 으로 접속하세요."
echo "연결 상태를 확인하려면: bash verify.sh"
