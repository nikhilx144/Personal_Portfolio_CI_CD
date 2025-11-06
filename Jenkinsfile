pipeline {
    agent any

    environment {
        IMAGE_NAME = "college-website-prac1"
        ECR_REPO   = "661979762009.dkr.ecr.ap-south-2.amazonaws.com/devops_ci_cd_final_prac_6_clean"
        REGION     = "ap-south-2"
    }

    stages {

        stage('Clone Repository') {
            steps {
                echo '📦 Cloning repository...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh '''
                    docker build -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Push to AWS ECR') {
            steps {
                echo '🚀 Pushing Docker image to ECR...'
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-username-pass-access-key',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {

                    sh '''
                        export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                        export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                        aws ecr get-login-password --region ${REGION} \
                             | docker login --username AWS --password-stdin ${ECR_REPO}

                        docker tag ${IMAGE_NAME}:latest ${ECR_REPO}:latest
                        docker push ${ECR_REPO}:latest
                    '''
                }
            }
        }

        stage('Terraform Deploy EC2') {
            steps {
                echo '🏗️ Running Terraform to provision/update EC2...'
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-username-pass-access-key',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {

                    dir('terraform') {
                        sh '''
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                            terraform init -reconfigure
                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Update App on EC2') {
            steps {
                echo '♻️ Updating Application Container inside EC2...'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-username-pass-access-key',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    ),
                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh-key',
                        keyFileVariable: 'KEY_FILE'
                    )
                ]) {

                    script {
                        def EC2_IP = sh(
                            script: "cd terraform && terraform output -raw ec2_public_ip",
                            returnStdout: true
                        ).trim()

                        sh """
                            ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '
                                echo "🔐 Logging into ECR..."
                                aws ecr get-login-password --region ${REGION} \
                                    | sudo docker login --username AWS --password-stdin ${ECR_REPO}

                                echo "🛑 Removing old containers & images..."
                                sudo docker stop college-website || true
                                sudo docker rm college-website || true
                                sudo docker rmi ${ECR_REPO}:latest || true
                                sudo docker image prune -af || true

                                echo "🐳 Pulling NEW image..."
                                sudo docker pull ${ECR_REPO}:latest

                                echo "🚀 Starting updated container..."
                                sudo docker run -d --name college-website -p 80:80 ${ECR_REPO}:latest

                                echo "✅ Application updated successfully!"
                            '
                        """
                    }
                }
            }
        }

        stage('Deploy Prometheus EC2') {
            steps {
                echo '📊 Deploying Prometheus EC2...'
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-username-pass-access-key',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {

                    dir('terraform') {
                        sh '''
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                            terraform init -reconfigure
                            terraform apply -auto-approve -target=aws_instance.prometheus
                        '''
                    }
                }
            }
        }

        stage('Setup Prometheus Server') {
            steps {
                echo '⚙️ Configuring Prometheus EC2...'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-username-pass-access-key',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    ),
                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh-key',
                        keyFileVariable: 'KEY_FILE'
                    )
                ]) {

                    dir('terraform') {
                        sh """
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                            PROM_IP=\$(terraform output -raw prometheus_public_ip)

                            echo "📂 Copying Prometheus config..."
                            scp -i \$KEY_FILE -o StrictHostKeyChecking=no \
                                  prometheus/prometheus.yml ec2-user@\${PROM_IP}:/home/ec2-user/

                            ssh -i \$KEY_FILE -o StrictHostKeyChecking=no ec2-user@\${PROM_IP} '
                                sudo mkdir -p /etc/prometheus
                                sudo mv /home/ec2-user/prometheus.yml /etc/prometheus/prometheus.yml

                                sudo docker rm -f prometheus || true

                                sudo docker run -d --name prometheus -p 9090:9090 \
                                    -v /etc/prometheus:/etc/prometheus prom/prometheus
                            '
                        """
                    }
                }
            }
        }

        stage('Deploy Grafana EC2') {
            steps {
                echo '📈 Deploying Grafana EC2...'
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-username-pass-access-key',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {

                    dir('terraform') {
                        sh '''
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                            terraform init -reconfigure
                            terraform apply -auto-approve -target=aws_instance.grafana
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment Completed Successfully!"

            withCredentials([
                usernamePassword(
                    credentialsId: 'aws-username-pass-access-key',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )
            ]) {

                dir('terraform') {
                    sh '''
                        APP_IP=$(terraform output -raw ec2_public_ip)
                        PROM_IP=$(terraform output -raw prometheus_public_ip)
                        GRAF_IP=$(terraform output -raw grafana_public_ip)

                        echo "=========================="
                        echo "📌 Application:  http://$APP_IP"
                        echo "📊 Prometheus:   http://$PROM_IP:9090"
                        echo "📈 Grafana:      http://$GRAF_IP:3000"
                        echo "=========================="
                    '''
                }
            }
        }

        failure {
            echo '❌ Build failed!'
        }
    }
}
