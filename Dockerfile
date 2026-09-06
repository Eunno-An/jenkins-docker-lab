# Jenkins + Docker CLI + kubectl 이미지
# 로컬 실습(Docker Desktop) 전용 이미지입니다. 프로덕션에는 사용하지 마세요.
FROM jenkins/jenkins:lts

USER root

# Docker CLI (호스트 도커 소켓을 마운트해서 사용 — Docker-outside-of-Docker 방식)
# kubectl (Docker Desktop Kubernetes에 접속하기 위함)
#
# 참고: 이전 버전은 Debian의 docker.io 패키지를 사용했으나, 배포판/버전에 따라
# 설치가 되지 않는 사례가 확인되어 Docker 공식 정적 바이너리를 직접 받는 방식으로 변경했습니다.
ARG DOCKER_CLI_VERSION=27.3.1
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    ARCH="$(dpkg --print-architecture)" && \
    case "$ARCH" in \
      amd64) DARCH=x86_64 ;; \
      arm64) DARCH=aarch64 ;; \
      *) echo "지원하지 않는 아키텍처: $ARCH" >&2; exit 1 ;; \
    esac && \
    curl -fsSL "https://download.docker.com/linux/static/stable/${DARCH}/docker-${DOCKER_CLI_VERSION}.tgz" -o /tmp/docker.tgz && \
    tar -xzf /tmp/docker.tgz -C /tmp && \
    install -o root -g root -m 0755 /tmp/docker/docker /usr/local/bin/docker && \
    rm -rf /tmp/docker /tmp/docker.tgz && \
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
    chmod +x /usr/local/bin/kubectl && \
    rm -rf /var/lib/apt/lists/* && \
    docker --version && kubectl version --client

# Jenkins 플러그인 설치 (최소 구성)
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# 설정 자동화(JCasC) — 초기 설정 마법사 생략, 관리자 계정 자동 생성
COPY casc/jenkins.yaml /var/jenkins_home/casc.yaml
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV KUBECONFIG=/var/jenkins_home/.kube/config

# 이 실습 이미지는 root로 실행됩니다.
# (호스트 도커 소켓 권한 문제를 피하기 위한 의도적인 단순화이며, 로컬 학습용으로만 사용하세요.)
