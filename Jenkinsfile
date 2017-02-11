#!groovy

defaultProperties(branches: ["master"])

node('panjit') {
    stage("Checkout") {
        checkout scm
    }
    stage("Build Image") {
        sh "docker build -t devregistry.wongnai.com/jenkins-slave:latest ."
    }
    stage("Push Image") {
        sh "docker push devregistry.wongnai.com/jenkins-slave:latest"
    }
}
