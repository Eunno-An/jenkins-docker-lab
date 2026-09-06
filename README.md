# Jenkins(Docker) + Docker Desktop Kubernetes 실습 환경

이 폴더는 "Jenkins Push vs ArgoCD GitOps — 비교 실습형 Kubernetes CI/CD 교육"
(7시간 과정)의 실습 파일입니다. **Section 2~8을 처음부터 끝까지 따라하려면
`EXERCISES.md`를 보세요.** 이 README는 환경을 처음 설치·점검하는 방법만 다룹니다.

- **Kubernetes**: 별도 클러스터(Kind/Minikube) 대신 **Docker Desktop 내장 Kubernetes**를 사용합니다.
- **Jenkins**: Kubernetes 위에 설치하지 않고 **Docker 컨테이너로 직접 실행**합니다.
- **ArgoCD**(선택 실습): Jenkins가 배포하는 것과 **동일한 Docker Desktop Kubernetes 클러스터**에 설치합니다.
  (이유는 `argocd/install-argocd.sh` 상단 주석 참고)

## 사전 준비물 (강사: macOS / 수강생: 대부분 Windows)
1. **Docker Desktop** 설치 및 실행
   - Windows: https://www.docker.com/products/docker-desktop (WSL2 백엔드 권장)
   - macOS: https://www.docker.com/products/docker-desktop (Apple Silicon은 자동으로 arm64용으로 빌드됩니다)
2. Docker Desktop 설정에서 **Settings > Kubernetes > Enable Kubernetes** 체크 후 Apply & Restart
   - 우측 하단 고래 아이콘이 "Kubernetes is running" 상태가 될 때까지 기다립니다 (수 분 소요)
3. 터미널에서 확인:
   ```bash
   kubectl config get-contexts
   ```
   목록에 `docker-desktop` 이 보이면 준비 완료입니다.

## 실행 방법

### macOS
```bash
bash setup-mac.sh
```

### Windows (PowerShell)
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup-windows.ps1
```

두 스크립트 모두 다음을 자동으로 수행합니다.
1. Docker/Kubernetes 상태 확인
2. `.env` 파일에 kubeconfig 경로 기록 (OS별 경로 차이를 자동 처리)
3. dev/staging/production 네임스페이스 생성
4. Jenkins 이미지 빌드 및 컨테이너 기동 (`docker compose up -d --build`)

**최초 실행은 이미지 빌드 때문에 3~7분 정도 걸릴 수 있습니다.** (플러그인 다운로드 포함)

## 완료 후 확인

```bash
# macOS
bash verify.sh
# Windows
.\verify.ps1
```

정상이라면 Jenkins 컨테이너 내부에서도 `kubectl cluster-info` 결과가 출력됩니다.
문제가 있다면 `TROUBLESHOOTING.md` 를 참고하세요.

## Jenkins 접속
- URL: http://localhost:8080
- 계정: `admin` / `admin123!` (JCasC로 자동 생성됨 — **로컬 실습 전용 비밀번호입니다**)

## 실습용 Pipeline Job 만들기 (최초 1회, 수동)
1. 이 폴더 전체를 본인 Git 저장소(GitHub 등)에 push
2. Jenkins 웹 UI에서 **New Item > Pipeline** 선택, 이름 입력 후 생성
3. **Pipeline > Definition: Pipeline script from SCM > SCM: Git**
4. Repository URL에 방금 만든 저장소 주소 입력, Branch는 `main`
5. Script Path는 기본값 `Jenkinsfile` 그대로 두고 저장
6. **Build with Parameters** 클릭 → `TARGET_ENV`(dev/staging/production) 선택 → 실행

파이프라인은 `./app` 이미지를 로컬로 빌드하고, 선택한 네임스페이스에 바로 배포합니다.
**레지스트리 push가 필요 없습니다** — Docker Desktop Kubernetes는 호스트와 같은 Docker
엔진을 쓰기 때문에, 로컬에서 빌드한 이미지를 바로 인식합니다.

## 배포 결과 확인
```bash
kubectl --context docker-desktop port-forward svc/sample-app 8081:80 -n sample-app-dev
```
브라우저에서 http://localhost:8081 접속.

## (선택) ArgoCD 실습
```bash
bash argocd/install-argocd.sh
```
자세한 내용은 `argocd/install-argocd.sh` 상단 주석과 `argocd/sample-app-argo.yaml` 참고.

## (선택) Push vs Pull 나란히 비교 실습
Jenkins와 ArgoCD 두 배포를 모두 마쳤다면, `compare/README.md`를 따라 같은 클러스터
위에서 Self-Heal·롤백·배포이력 차이를 직접 비교해보세요.

## 폴더 구성
| 경로 | 설명 |
|---|---|
| `Dockerfile` | Jenkins + Docker CLI + kubectl 이미지 정의 |
| `docker-compose.yml` | Jenkins 컨테이너 실행 설정 |
| `casc/jenkins.yaml` | Jenkins 초기 설정 자동화 (관리자 계정 등) |
| `k8s/` | dev/staging/production 네임스페이스, Deployment/Service 템플릿 |
| `app/` | 실습용 샘플 애플리케이션 (정적 nginx 페이지) |
| `Jenkinsfile` | 빌드→배포 파이프라인 (환경 선택 파라미터 포함) |
| `argocd/` | (선택) ArgoCD 설치 스크립트 및 GitOps 데모 매니페스트 |
| `compare/` | Push(Jenkins) vs Pull(ArgoCD) 나란히 비교 실습 가이드 |
| `rollouts/` | Section 6 실습용 Argo Rollouts Canary 데모 매니페스트 |
| `EXERCISES.md` | **Section 2~8 전체를 처음부터 끝까지 따라할 수 있는 step-by-step 가이드** |
| `setup-mac.sh` / `setup-windows.ps1` | 환경 자동 준비 스크립트 |
| `verify.sh` / `verify.ps1` | 연결 상태 점검 스크립트 |
| `TROUBLESHOOTING.md` | 자주 발생하는 문제와 해결법 |

## 정리(초기화)
```bash
docker compose down -v
kubectl --context docker-desktop delete ns sample-app-dev sample-app-staging sample-app-production argocd argocd-demo-app --ignore-not-found
```
