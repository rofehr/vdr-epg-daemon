pipeline {
	environment {
		registry = "lapicidae/vdr-epg-daemon"
		registryCredential = 'dockerhub'
		registryTag = 'latest'
		gitURL = 'https://github.com/lapicidae/vdr-epg-daemon.git'
		dockerImage = ''
	}
	agent any
	stages {
		stage('Clone') {
			steps{
				echo 'Cloning....'
				checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[url: gitURL]]])
			}
		}
		stage('Build') {
			steps{
				echo 'Building....'
				script {
					dockerImage = docker.build registry + ":$BUILD_NUMBER"
				}
			}
		}
		stage('Publish') {
			steps{
				echo 'Publishing....'
				script {
					docker.withRegistry( '', registryCredential ) {
						dockerImage.push(registryTag)
					}
				}
			}
		}
		stage('Clean') {
			steps{
				echo 'Cleaning....'
				sh "docker rmi $registry:$BUILD_NUMBER"
				sh "docker rmi $registry:$registryTag"
			}
		}
	}
}
