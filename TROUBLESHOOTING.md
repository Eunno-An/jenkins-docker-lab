# 문제 해결 가이드

## 1) `docker compose up` 이 아예 실행되지 않음 / "Cannot connect to the Docker daemon"
Docker Desktop이 실행 중인지 확인하세요 (메뉴바/트레이의 고래 아이콘이 활성 상태여야 합니다).

## 2) `kubectl config get-contexts` 에 `docker-desktop` 이 없음
Docker Desktop 설정 > Kubernetes > Enable Kubernetes 를 켜고 "Apply & Restart" 하세요.
활성화 후 하단 상태가 "Kubernetes is running" 이 될 때까지 기다린 후 다시 확인합니다.

## 3) verify 스크립트에서 "Jenkins 컨테이너 안에서 클러스터 접속 실패"가 나올 때
가장 흔한 원인은 컨테이너 안에서 kubeconfig의 서버 주소(`kubernetes.docker.internal`)가
해석되지 않는 경우입니다. Docker Desktop은 보통 이 주소를 컨테이너 내부에서도 자동으로
연결해주지만, 일부 네트워크 환경(특히 회사 VPN/방화벽)에서는 막힐 수 있습니다.

확인:
```bash
docker compose exec jenkins cat /var/jenkins_home/.kube/config | grep server
```

해결 순서 (위에서부터 시도):
1. **VPN을 끄고** 다시 `bash verify.sh` (사내 VPN이 사설 DNS를 강제하는 경우가 많습니다)
2. Docker Desktop을 재시작 후 다시 시도
3. 그래도 안 되면, 아래처럼 서버 주소를 `host.docker.internal`로 바꾼 별도 kubeconfig를 만들어 사용합니다.
   (아래는 macOS/Linux 기준이며, Windows는 PowerShell로 유사하게 처리합니다.)
   ```bash
   mkdir -p .kubeconfig-container
   sed 's/kubernetes.docker.internal/host.docker.internal/' "$HOME/.kube/config" \
     > .kubeconfig-container/config
   ```
   그 다음 `.env` 파일의 `KUBE_CONFIG_PATH`를 `.kubeconfig-container/config` 의 절대경로로
   바꾸고 `docker compose up -d --build` 를 다시 실행하세요.
4. 3번으로도 TLS 인증서 오류(`certificate is valid for ...`)가 나면, **로컬 실습에 한해서만**
   아래처럼 인증서 검증을 건너뛸 수 있습니다 (운영 환경에서는 절대 사용하지 마세요).
   ```bash
   kubectl --context docker-desktop config set-cluster docker-desktop --insecure-skip-tls-verify=true --kubeconfig=.kubeconfig-container/config
   ```

## 4) `docker build` 단계에서 권한 오류(permission denied on docker.sock)
이 실습 이미지는 root로 실행되도록 설계되어 있어 보통 발생하지 않습니다. 그래도 발생한다면
Docker Desktop을 재시작하고 `docker compose up -d --build --force-recreate` 로 다시 실행하세요.

## 5) Jenkins 플러그인 설치 중 빌드가 느리거나 실패
사내망/VPN에서 플러그인 저장소(updates.jenkins.io)가 막혀 있을 수 있습니다. 개인 네트워크나
모바일 핫스팟에서 최초 빌드를 한 번 진행해보세요. 이후에는 `jenkins_home` 볼륨에 캐시되어
다시 빌드할 필요가 없습니다.

## 6) 포트 충돌 (8080, 8443 등 이미 사용 중)
`docker-compose.yml`의 `ports` 값을 예: `"18080:8080"` 처럼 왼쪽 숫자만 바꾸고,
이후 안내되는 URL의 포트 번호도 그에 맞게 바꿔서 접속하세요.

## 7) `kubectl rollout status` 가 타임아웃되며 실패
```bash
kubectl --context docker-desktop get pods -n sample-app-dev
kubectl --context docker-desktop describe pod <pod-이름> -n sample-app-dev
```
`ImagePullBackOff`가 보이면 `docker build` 단계가 먼저 성공했는지, 이미지 태그가
Jenkinsfile의 `${IMAGE}` 값과 일치하는지 확인하세요.
