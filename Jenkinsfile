pipeline {
    agent any 

    stages {
        stage('Build') { 
            steps { 
                sh './setup.sh --install' 
            }
        }
        stage('Test'){
            steps {
                sh './run_tests.sh'
            }
        }
    }
}
