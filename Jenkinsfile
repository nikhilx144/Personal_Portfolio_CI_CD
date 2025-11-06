// pipeline {
//     agent any

//     environment {
//         IMAGE_NAME = "college-website-prac1"
//         ECR_REPO   = "661979762009.dkr.ecr.ap-south-2.amazonaws.com/devops_ci_cd_final_prac_6_clean"
//         REGION     = "ap-south-2"
//     }

//     stages {
//         stage('Clone Repository') {
//             steps {
//                 echo '📦 Cloning repository... '
//                 checkout scm
//                 // git branch: 'master', url: 'https://github.com/nikhilx144/Personal_Portfolio_CI_CD.git'
//             }
//         }

//         stage('Build Docker Image') {
//             steps {
//                 echo '🐳 Building Docker image..'
//                 sh '''
//                     docker build -t ${IMAGE_NAME}:latest .
//                 '''
//             }
//         }

//         stage('Push to AWS ECR') {
//             steps {
//                 echo '🚀 Pushing image to AWS ECR...'
//                 withCredentials([usernamePassword(credentialsId: 'aws-username-pass-access-key', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     sh '''
//                         export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
//                         export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

//                         aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

//                         docker tag ${IMAGE_NAME}:latest ${ECR_REPO}:latest
//                         docker push ${ECR_REPO}:latest
//                     '''
//                 }
//             }
//         }

//         stage('Deploy with Terraform') {
//             steps {
//                 echo '🏗️ Deploying EC2 instance and running Docker container...'
//                 withCredentials([usernamePassword(credentialsId: 'aws-username-pass-access-key', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     dir('terraform') {
//                         sh '''
//                             export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
//                             export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

//                             terraform init -reconfigure
//                             terraform apply -auto-approve
//                         '''
//                     }
//                 }
//             }
//         }

//         stage('Update App on EC2') {
//             steps {
//                 echo '♻️ Updating application container on EC2...'

//                 withCredentials([
//                     usernamePassword(credentialsId: 'aws-username-pass-access-key',
//                         usernameVariable: 'AWS_ACCESS_KEY_ID',
//                         passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
//                     sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'KEY_FILE')
//                 ]) {

//                     script {
//                         def EC2_IP = sh(
//                             script: "cd terraform && terraform output -raw ec2_public_ip",
//                             returnStdout: true
//                         ).trim()

//                         sh """
//                             ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '
//                                 echo "🛠 Logging into ECR..."
//                                 aws ecr get-login-password --region ${REGION} | sudo docker login --username AWS --password-stdin ${ECR_REPO}

//                                 echo "🛑 Stopping old container..."
//                                 sudo docker stop college-website || true
//                                 sudo docker rm college-website || true

//                                 echo "🐳 Pulling latest image..."
//                                 sudo docker pull ${ECR_REPO}:latest

//                                 echo "🚀 Running updated container..."
//                                 sudo docker run -d --name college-website -p 80:80 ${ECR_REPO}:latest

//                                 echo "✅ App updated successfully!"
//                             '
//                         """
//                     }
//                 }
//             }
//         }


//         stage('Deploy Prometheus EC2') {
//             steps {
//                 echo '📊 Deploying Prometheus EC2 instance...'
//                 withCredentials([usernamePassword(credentialsId: 'aws-username-pass-access-key', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     dir('terraform') {
//                         sh '''
//                             export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
//                             export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

//                             terraform init -reconfigure
//                             terraform apply -auto-approve -target=aws_instance.prometheus
//                         '''
//                     }
//                 }
//             }
//         }

//         stage('Setup Prometheus Server') {
//             steps {
//                 echo '⚙️ Setting up Prometheus EC2 and configuration...'
//                 withCredentials([
//                     usernamePassword(credentialsId: 'aws-username-pass-access-key', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
//                     sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'KEY_FILE')
//                 ]) {
//                     dir('terraform') {
//                         sh """
//                             export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
//                             export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

//                             PROMETHEUS_IP=\$(terraform output -raw prometheus_public_ip)
//                             echo "📂 Copying Prometheus configuration..."

//                             scp -i \$KEY_FILE -o StrictHostKeyChecking=no prometheus/prometheus.yml ec2-user@\${PROMETHEUS_IP}:/home/ec2-user/

//                             echo "🚀 Installing Docker & Starting Prometheus..."

//                             ssh -i \$KEY_FILE -o StrictHostKeyChecking=no ec2-user@\${PROMETHEUS_IP} '
//                                 echo "🛠 Installing Docker ..."
//                                 sudo yum update -y
//                                 sudo amazon-linux-extras install docker -y || sudo yum install docker -y
//                                 sudo systemctl start docker
//                                 sudo systemctl enable docker
//                                 sudo usermod -aG docker ec2-user

//                                 echo "🐳 Docker installed. Setting up Prometheus..."

//                                 sudo mkdir -p /etc/prometheus
//                                 sudo rm -f /etc/prometheus/prometheus.yml
//                                 sudo cp /home/ec2-user/prometheus.yml /etc/prometheus/prometheus.yml
//                                 sudo chown -R root:root /etc/prometheus
//                                 sudo chmod 644 /etc/prometheus/prometheus.yml

//                                 echo "🔁 Removing old Prometheus container"
//                                 sudo docker rm -f prometheus || true

//                                 echo "🚀 Running Prometheus"
//                                 sudo docker run -d --name prometheus -p 9090:9090 \\
//                                     -v /etc/prometheus:/etc/prometheus prom/prometheus \\
//                                     --config.file=/etc/prometheus/prometheus.yml

//                                 echo "✅ Prometheus is running!"
//                             '
//                         """
//                     }
//                 }
//             }
//         }

//         stage('Deploy Grafana EC2') {
//             steps {
//                 echo '📊 Deploying Grafana EC2...'
//                 withCredentials([usernamePassword(credentialsId: 'aws-username-pass-access-key', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
//                     dir('terraform') {
//                         sh '''
//                             export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
//                             export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

//                             terraform init -reconfigure
//                             terraform apply -auto-approve -target=aws_instance.grafana
//                         '''
//                     }
//                 }
//             }
//         }


//     }

//     post {
//         success {
//             echo "✅ Deployment Completed Successfully!"

//             withCredentials([
//             usernamePassword(
//                 credentialsId: 'aws-username-pass-access-key',
//                 usernameVariable: 'AWS_ACCESS_KEY_ID',
//                 passwordVariable: 'AWS_SECRET_ACCESS_KEY'
//             )
//             ]) {
//             dir('terraform') {
//                 sh '''
//                 echo "🔎 Fetching Public IPs..."

//                 APP_IP=$(terraform output -raw ec2_public_ip)
//                 PROM_IP=$(terraform output -raw prometheus_public_ip)
//                 GRAF_IP=$(terraform output -raw grafana_public_ip)

//                 echo "=========================="
//                 echo "📌 Application Public IP:   $APP_IP"
//                 echo "📊 Prometheus Public IP:    $PROM_IP:9090"
//                 echo "📈 Grafana Public IP:       http://$GRAF_IP:3000"
//                 echo "=========================="
//                 '''
//             }
//             }
//         }
//         failure {
//             echo '❌ Build or deployment failed!'
//         }
//     }
// }


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
                sh 'docker build -t ${IMAGE_NAME}:latest .'
            }
        }

        stage('Push to AWS ECR') {
            steps {
                echo '🚀 Pushing image to AWS ECR...'
                withCredentials([usernamePassword(credentialsId: 'aws-username-pass-access-key',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {

                    sh '''
                        export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                        export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                        aws ecr get-login-password --region ${REGION} | \
                           docker login --username AWS --password-stdin ${ECR_REPO}

                        docker tag ${IMAGE_NAME}:latest ${ECR_REPO}:latest
                        docker push ${ECR_REPO}:latest
                    '''
                }
            }
        }

        stage('Deploy with Terraform') {
            steps {
                echo '🏗️ Applying Terraform (EC2 + updates)...'
                withCredentials([usernamePassword(credentialsId: 'aws-username-pass-access-key',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {

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

        stage('Deploy Prometheus EC2') {
            steps {
                echo '📊 Deploying Prometheus...'
                withCredentials([usernamePassword(credentialsId: 'aws-username-pass-access-key',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {

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
                    usernamePassword(credentialsId: 'aws-username-pass-access-key',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
                    sshUserPrivateKey(credentialsId: 'ec2-ssh-key',
                        keyFileVariable: 'KEY_FILE')
                ]) {

                    dir('terraform') {
                        sh """
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                            PROM_IP=\$(terraform output -raw prometheus_public_ip)

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
                withCredentials([usernamePassword(credentialsId: 'aws-username-pass-access-key',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {

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

            withCredentials([usernamePassword(
                credentialsId: 'aws-username-pass-access-key',
                usernameVariable: 'AWS_ACCESS_KEY_ID',
                passwordVariable: 'AWS_SECRET_ACCESS_KEY'
            )]) {

                dir('terraform') {
                    sh '''
                    echo "🔎 Fetching Public IPs..."

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
