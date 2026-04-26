pipeline {
  agent any

  environment {
    AWS_REGION       = 'ap-south-1'
    ECR_REGISTRY     = '686584420811.dkr.ecr.ap-south-1.amazonaws.com'
    ECR_REPO         = 'my-webapp'
    IMAGE_TAG        = "${ECR_REGISTRY}/${ECR_REPO}:${BUILD_NUMBER}"
    LATEST_TAG       = "${ECR_REGISTRY}/${ECR_REPO}:latest"
    K8S_CLUSTER      = 'my-webapp-cluster'
    AWS_CREDENTIALS  = 'aws-credentials'
  }

  tools {
    maven 'maven'
  }

  stages {

    stage('1. Checkout') {
      steps {
        git branch: 'master',
          credentialsId: 'github-credentials',
          url: 'https://github.com/Poojak134/myapp-project.git'
        echo 'Code fetched successfully!'
      }
    }

    stage('2. Maven Build') {
      steps {
        sh 'mvn clean package -DskipTests'
        echo 'WAR file built: target/my-webapp.war'
      }
    }

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

    stage('4. Docker Build') {
      steps {
        sh "docker build -t ${IMAGE_TAG} -t ${LATEST_TAG} ."
        echo 'Docker image built!'
      }
    }

    stage('5. Push to ECR') {
      steps {
        withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_REGION}") {
          sh '''
            aws ecr get-login-password --region $AWS_REGION | \
            docker login --username AWS --password-stdin $ECR_REGISTRY
          '''
          sh "docker push ${IMAGE_TAG}"
          sh "docker push ${LATEST_TAG}"
          echo 'Image pushed to ECR!'
        }
      }
    }

    stage('6. Deploy to Kubernetes') {
      steps {
        withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_REGION}") {
          sh """
            # Update kubeconfig
            aws eks update-kubeconfig --region ${AWS_REGION} --name ${K8S_CLUSTER}
            
            # Create/update ECR secret for image pull
            kubectl get secret ecr-secret || \
            aws ecr get-login-password --region ${AWS_REGION} | \
            kubectl create secret docker-registry ecr-secret \
              --docker-server=${ECR_REGISTRY} \
              --docker-username=AWS \
              --docker-password-stdin
            
            # Update image in deployment
            sed -i 's|IMAGE_PLACEHOLDER|${IMAGE_TAG}|g' k8s/deployment.yaml
            
            # Validate YAML before applying
            kubectl apply -f k8s/deployment.yaml --dry-run=client || exit 1
            
            # Apply manifests
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/service.yaml
            
            # Wait for rollout with diagnostics
            kubectl rollout status deployment/my-webapp --timeout=300s || {
              echo "=== Deployment Failed - Gathering Diagnostics ==="
              kubectl get pods
              kubectl describe pods -l app=my-webapp
              kubectl logs -l app=my-webapp --tail=50 || true
              kubectl logs -l app=my-webapp --previous --tail=50 || true
              exit 1
            }
            
            echo 'App deployed to Kubernetes!'
          """
        }
      }
    }

    stage('7. Verify Deployment') {
      steps {
        withAWS(credentials: "${AWS_CREDENTIALS}", region: "${AWS_REGION}") {
          sh """
            echo "=== Pods ==="
            kubectl get pods -l app=my-webapp
            echo "=== Services ==="
            kubectl get service
            echo "=== Deployment Status ==="
            kubectl get deployment my-webapp
          """
          echo 'Deployment successful! App is live.'
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
      script {
        sh "docker rmi ${IMAGE_TAG} || true"
        sh "docker rmi ${LATEST_TAG} || true"
      }
    }
  }
}
