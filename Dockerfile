# Jenkins + Docker CLI + kubectl 이미지
# 로컬 실습(Docker Desktop) 전용 이미지입니다. 프로덕션에는 사용하지 마세요.
FROM jenkins/jenkins:lts

USER root

# Docker CLI (호스트 도커 소켓을 마운트해서 사용 — Docker-outside-of-Docker 방식)
# kubectl (Docker Desktop Kubernetes에 접속하기 위함)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      docker.io \
      curl \
      ca-certificates \
      gnupg && \
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm -f kubectl && \
    rm -rf /var/lib/apt/lists/*

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
