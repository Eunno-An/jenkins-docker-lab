#!/usr/bin/env bash
# 실습 환경 연결 상태 점검 (macOS/Linux)
set -e

echo "1) 호스트에서 클러스터 접속 확인"
kubectl --context docker-desktop cluster-info

echo ""
echo "2) Jenkins 컨테이너 기동 확인"
docker compose ps

echo ""
echo "3) Jenkins 웹 응답 확인"
code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/login || echo "000")
echo "   HTTP $code"
if [ "$code" != "200" ] && [ "$code" != "403" ]; then
  echo "   ⚠️  Jenkins가 아직 기동 중일 수 있습니다. 1분 후 다시 시도해보세요: bash verify.sh"
fi

echo ""
echo "4) Jenkins 컨테이너 내부에서 K8s 클러스터 접속 확인 (가장 중요한 확인 단계)"
if docker compose exec -T jenkins kubectl --context docker-desktop cluster-info > /tmp/verify_out.txt 2>&1; then
  cat /tmp/verify_out.txt
  echo "   ✅ Jenkins 컨테이너 안에서 Docker Desktop Kubernetes에 정상 접속됩니다."
else
  cat /tmp/verify_out.txt
  echo ""
  echo "   ❌ Jenkins 컨테이너 안에서 클러스터 접속에 실패했습니다."
  echo "   ── 문제 해결 (TROUBLESHOOTING.md 3번 항목 참고) ──"
  echo "   docker compose exec jenkins cat /var/jenkins_home/.kube/config | grep server"
  echo "   위 명령으로 나온 서버 주소가 'kubernetes.docker.internal' 또는 '127.0.0.1' 인지 확인 후"
  echo "   TROUBLESHOOTING.md 안내에 따라 조치하세요."
fi
