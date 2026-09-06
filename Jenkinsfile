pipeline {
  agent any

  parameters {
    choice(name: 'TARGET_ENV', choices: ['dev', 'staging', 'production'], description: '배포할 환경을 선택하세요')
  }

  environment {
    IMAGE = "sample-app:${env.BUILD_NUMBER}"
    NAMESPACE = "sample-app-${params.TARGET_ENV}"
    KCTL = "kubectl --context docker-desktop"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Docker Build') {
      // Docker Desktop Kubernetes는 호스트와 동일한 Docker 엔진을 사용하므로,
      // 여기서 빌드한 이미지는 레지스트리에 push하지 않아도 클러스터에서 바로 사용할 수 있습니다.
      steps {
        sh "docker build -t ${IMAGE} ./app"
      }
    }

    stage('Namespace 준비') {
      steps {
        sh "${KCTL} apply -f k8s/namespaces.yaml"
      }
    }

    stage('Deploy') {
      steps {
        sh "sed 's|__IMAGE__|${IMAGE}|' k8s/deployment.yaml | ${KCTL} apply -n ${NAMESPACE} -f -"
        sh "${KCTL} rollout status deployment/sample-app -n ${NAMESPACE} --timeout=90s"
      }
    }

    stage('결과 확인 안내') {
      steps {
        echo "배포 완료: ${NAMESPACE} 네임스페이스에 ${IMAGE} 배포됨"
        echo "확인 명령: kubectl --context docker-desktop port-forward svc/sample-app 8081:80 -n ${NAMESPACE}"
        echo "브라우저에서 http://localhost:8081 접속"
      }
    }
  }

  post {
    failure {
      echo "❌ 빌드 실패 — 콘솔 로그를 확인하세요: ${env.BUILD_URL}console"
    }
    success {
      echo "✅ 빌드 성공 — ${NAMESPACE}"
    }
  }
}
