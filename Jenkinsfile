pipeline {
  agent any

  environment {
    AWS_REGION       = 'ap-south-1'
    ECR_REGISTRY     = '686584420811.dkr.ecr.ap-south-1.amazonaws.com'
    ECR_REPO         = 'my-webapp'
    IMAGE_TAG        = "${ECR_REGISTRY}/${ECR_REPO}:${BUILD_NUMBER}"
    LATEST_TAG       = "${ECR_REGISTRY}/${ECR_REPO}:latest"
    K8S_CLUSTER      = 'webapp-cluster'
    AWS_CREDENTIALS  = 'aws-credentials'
  }

  tools {
    maven 'maven'
  }

  stages {

    // ─── STAGE 1: Code Checkout ───
    stage('1. Checkout') {
      steps {
        git branch: 'main',
          credentialsId: 'github-credentials',
          url: 'https://github.com/YOUR_USERNAME/my-webapp.git'
        echo 'Code GitHub se fetch ho gaya!'
      }
    }

    // ─── STAGE 2: Maven Build ───
    stage('2. Maven Build') {
      steps {
        sh 'mvn clean package -DskipTests'
        echo 'WAR file build ho gaya: target/my-webapp.war'
      }
    }

    // ─── STAGE 3: Unit Tests ───
    stage('3. Unit Tests') {
      steps {
        sh 'mvn test'
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
        }
      }
    }

    // ─── STAGE 4: Docker Build ───
    stage('4. Docker Build') {
      steps {
        sh "docker build -t ${IMAGE_TAG} -t ${LATEST_TAG} ."
        echo 'Docker image build ho gaya!'
      }
    }

    // ─── STAGE 5: ECR Push ───
    stage('5. Push to ECR') {
      steps {
        withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_REGION}") {
          sh '''
            aws ecr get-login-password --region $AWS_REGION | \
            docker login --username AWS --password-stdin $ECR_REGISTRY
          '''
          sh "docker push ${IMAGE_TAG}"
          sh "docker push ${LATEST_TAG}"
          echo 'Image ECR mein push ho gayi!'
        }
      }
    }

    // ─── STAGE 6: Kubernetes Deploy ───
    stage('6. Deploy to Kubernetes') {
      steps {
        withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_REGION}") {
          sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${K8S_CLUSTER}"

          // Image tag update karo
          sh "sed -i 's|IMAGE_PLACEHOLDER|${IMAGE_TAG}|g' k8s/deployment.yaml"

          // Apply Kubernetes manifests
          sh 'kubectl apply -f k8s/deployment.yaml'
          sh 'kubectl apply -f k8s/service.yaml'

          // Rollout wait karo
          sh 'kubectl rollout status deployment/my-webapp --timeout=300s'
          echo 'App Kubernetes mein deploy ho gayi!'
        }
      }
    }

    // ─── STAGE 7: Verify Deployment ───
    stage('7. Verify') {
      steps {
        withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_REGION}") {
          sh 'kubectl get pods -l app=my-webapp'
          sh 'kubectl get service my-webapp-service'
          echo 'Deployment successful! App live hai.'
        }
      }
    }

  }

  post {
    success {
      echo 'CI/CD Pipeline Successfully Completed!'
    }
    failure {
      echo 'Pipeline Failed! Check logs above.'
    }
    always {
      // Local Docker images clean karo
      sh "docker rmi ${IMAGE_TAG} || true"
      sh "docker rmi ${LATEST_TAG} || true"
    }
  }
}
