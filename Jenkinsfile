pipeline {
    agent {
        label 'docker-capable'
    }
    
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_BUILDKIT = '1'
        DOCKER_IMAGE = 'vutd22uit/cicd-youtube'
        DOCKER_TAG = 'latest'
        RAPID_API_KEY = credentials('rapid-api-key')
        SONAR_PROJECT_NAME = 'Youtube-CICD'
        SONAR_PROJECT_KEY = 'Youtube-CICD'
    }
    
    options {
        timeout(time: 1, unit: 'HOURS')
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    stages {
        stage('Setup') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/vutd22uit/CICD.git',
                    shallow: true
                stash includes: '**/*', excludes: 'node_modules/**', name: 'source'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                unstash 'source'
                script {
                    def npmCacheKey = "npm-${env.BRANCH_NAME}-${sha1 file: 'package-lock.json'}"
                    cache(path: '.npm', key: npmCacheKey, restoreKeys: ['npm-']) {
                        sh '''
                            npm ci --prefer-offline --no-audit
                            npm prune --production
                        '''
                    }
                }
                stash includes: 'node_modules/**', name: 'node_modules'
            }
        }
        
        stage('Tests') {
            parallel {
                stage('Code Analysis') {
                    steps {
                        unstash 'source'
                        withSonarQubeEnv('SonarQube-Server') {
                            sh """
                                ${SCANNER_HOME}/bin/sonar-scanner \\
                                -Dsonar.projectName=${SONAR_PROJECT_NAME} \\
                                -Dsonar.projectKey=${SONAR_PROJECT_KEY} \\
                                -Dsonar.scm.disabled=true \\
                                -Dsonar.coverage.exclusions=**/*.test.js \\
                                -Dsonar.sourceEncoding=UTF-8 \\
                                -Dsonar.nodejs.executable=\$(which node) \\
                                -Dsonar.javascript.node.maxspace=4096
                            """
                        }
                        timeout(time: 2, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }
                
                stage('Build and Push') {
                    steps {
                        unstash 'source'
                        unstash 'node_modules'
                        script {
                            withDockerRegistry([credentialsId: 'dockerhub', url: 'https://index.docker.io/v1/']) {
                                sh """
                                    DOCKER_BUILDKIT=1 docker build \\
                                    --build-arg REACT_APP_RAPID_API_KEY=\${RAPID_API_KEY} \\
                                    --cache-from ${DOCKER_IMAGE}:${DOCKER_TAG} \\
                                    --build-arg BUILDKIT_INLINE_CACHE=1 \\
                                    --tag ${DOCKER_IMAGE}:${DOCKER_TAG} \\
                                    --tag ${DOCKER_IMAGE}:\${BUILD_NUMBER} \\
                                    .
                                    
                                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                                    docker push ${DOCKER_IMAGE}:\${BUILD_NUMBER}
                                """
                            }
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        unstash 'source'
                        sh """
                            mkdir -p .trivycache/
                            trivy image \\
                            --cache-dir .trivycache/ \\
                            --no-progress \\
                            --exit-code 1 \\
                            --severity HIGH,CRITICAL \\
                            --vuln-type os,library \\
                            --ignore-unfixed \\
                            --light \\
                            ${DOCKER_IMAGE}:${DOCKER_TAG} | tee trivy-results.txt
                        """
                        archiveArtifacts artifacts: 'trivy-results.txt', fingerprint: true
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {
                    dir('Kubernetes') {
                        withKubeConfig(credentialsId: 'kubernetes') {
                            sh """
                                kubectl apply -f deployment.yml --record
                                kubectl rollout status deployment/youtube-app
                                kubectl apply -f service.yml
                            """
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
            sh '''
                docker system prune -af --volumes
                rm -rf .trivycache/
                rm -rf .npm/
            '''
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
