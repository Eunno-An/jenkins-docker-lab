# Section 5 실습 — 나란히 비교 (Push vs Pull)

이 실습은 Section 3(Jenkins Push)에서 배포한 `sample-app-dev` 네임스페이스와
Section 4(ArgoCD Pull)에서 배포한 `argocd-demo-app` 네임스페이스가 **둘 다 이미
배포되어 있다는 전제**로 진행합니다. 아직이라면 두 Section을 먼저 완료하세요.

## 비교 1 — Drift 복구 (Self-Heal)

터미널을 두 개 열어서 각각 실행하며 동시에 관찰하는 것을 권장합니다.

**터미널 A (Jenkins로 배포한 쪽)**
```bash
kubectl --context docker-desktop get deploy sample-app -n sample-app-dev --watch
```

**터미널 B — 수동으로 replica 수 변경**
```bash
kubectl --context docker-desktop scale deployment/sample-app --replicas=5 -n sample-app-dev
```
→ 터미널 A에서 replicas가 5로 바뀐 채 **그대로 유지**되는 것을 확인합니다. (아무도 되돌리지 않음)

이제 ArgoCD 쪽으로 동일하게 반복합니다.

**터미널 A**
```bash
kubectl --context docker-desktop get deploy argocd-demo-app -n argocd-demo-app --watch
```

**터미널 B**
```bash
kubectl --context docker-desktop scale deployment/argocd-demo-app --replicas=5 -n argocd-demo-app
```
→ 이번에는 몇 초 뒤 터미널 A에서 replicas가 **원래 값으로 자동으로 되돌아오는 것**을 확인합니다
(ArgoCD의 Self-Heal). ArgoCD UI(https://localhost:8443)를 같이 열어두면 OutOfSync →
Synced로 바뀌는 것도 함께 볼 수 있습니다.

## 비교 2 — 롤백

**Jenkins 쪽 (재배포로 롤백)**
1. Jenkins Job의 Build History에서 이전 성공 빌드 번호를 확인
2. 해당 빌드 번호로 다시 배포하려면: Jenkinsfile 구조상 가장 쉬운 방법은 이전 커밋으로
   `git revert` 후 다시 Build 하는 것입니다 (Jenkins 자체에는 "이전 이미지로 즉시 롤백"
   버튼이 없기 때문입니다 — 이 차이 자체가 비교 포인트입니다).
```bash
git revert HEAD
git push
# Jenkins에서 다시 Build with Parameters 실행
```

**ArgoCD 쪽 (Git 되돌리기 → 자동 반영)**
```bash
# argocd/manifests 디렉토리의 최근 변경을 되돌린다고 가정
git revert HEAD
git push
# 아무 것도 더 할 필요 없음 — automated sync가 켜져 있다면 ArgoCD가 자동으로 재동기화합니다.
argocd app get argocd-demo-app   # 또는 UI에서 Synced 상태 확인
```

## 비교 3 — 배포 이력 확인

```bash
# Jenkins: 웹 UI의 Build History, 또는
curl -s http://localhost:8080/job/<job-이름>/api/json?tree=builds[number,result,timestamp]

# ArgoCD: 배포 이력이 곧 Git 커밋 이력 + ArgoCD 자체 History
argocd app history argocd-demo-app
git log --oneline argocd/manifests
```

## 정리 메모

실습을 마치면 아래 표를 직접 채워보면서 오늘 관찰한 내용을 정리해보세요.

| 관찰 항목 | Jenkins (Push) | ArgoCD (Pull) |
|---|---|---|
| 수동 변경 후 자동 복구되었는가? | | |
| 롤백에 몇 단계가 필요했는가? | | |
| 배포 이력을 몇 초 만에 확인할 수 있었는가? | | |
