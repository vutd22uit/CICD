pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    stages {
        // Các stage cần chạy tuần tự đầu tiên
        stage('Initial Setup') {
            stages {
                stage('clean workspace') {
                    steps {
                        cleanWs()
                    }
                }
                stage('Checkout from Git') {
                    steps {
                        git branch: 'main', url: 'https://github.com/vutd22uit/CICD.git'
                    }
                }
            }
        }

        // Các stage có thể chạy song song
        stage('Parallel Stages') {
            parallel {
                // Branch 1: Code Analysis
                stage('Code Analysis') {
                    stages {
                        stage("Sonarqube Analysis") {
                            steps {
                                withSonarQubeEnv('SonarQube-Server') {
                                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Youtube-CICD \
                                    -Dsonar.projectKey=Youtube-CICD '''
                                }
                            }
                        }
                        stage("quality gate") {
                            steps {
                                script {
                                    waitForQualityGate abortPipeline: false, credentialsId: 'SonarQube-Token'
                                }
                            }
                        }
                    }
                }

                // Branch 2: Build và Dependencies
                stage('Build Process') {
                    stages {
                        stage('Install Dependencies') {
                            steps {
                                sh "npm install"
                            }
                        }
                        stage("Docker Build & Push") {
                            steps {
                                script {
                                    withDockerRegistry([credentialsId: 'dockerhub', url: 'https://index.docker.io/v1/']) {   
                                        sh "docker build --build-arg REACT_APP_RAPID_API_KEY=789733726cmsh6cdce418f9e535ep1c343fjsn62b1b3b24128 -t cicd-youtube ."
                                        sh "docker tag cicd-youtube vutd22uit/cicd-youtube:latest"
                                        sh "docker push vutd22uit/cicd-youtube:latest"
                                    }
                                }
                            }
                        }
                    }
                }

                // Branch 3: Security Scan
                stage('Security Checks') {
                    steps {
                        sh """
                            trivy image --cache-dir .trivycache/ \
                            --exit-code 0 \
                            --no-progress \
                            --severity HIGH,CRITICAL \
                            --vuln-type os,library \
                            --ignore-unfixed \
                            vutd22uit/cicd-youtube:latest > trivyimage.txt
                        """
                        archiveArtifacts artifacts: 'trivyimage.txt', fingerprint: true
                    }
                }
            }
        }

        // Stage cuối cùng cần chạy tuần tự
        stage('Deploy to Kubernets') {
            steps {
                script {
                    dir('Kubernetes') {
                        withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'kubernetes', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                            sh 'kubectl delete --all pods'
                            sh 'kubectl apply -f deployment.yml'
                            sh 'kubectl apply -f service.yml'
                        }   
                    }
                }
            }
        }
    }
}
