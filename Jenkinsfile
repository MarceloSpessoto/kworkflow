pipeline {
  agent any
  stages {

    stage('Build'){
      steps{
        sh '''
          apt update -y
          apt install -y kcov shunit2 bc sqlite3 bsdmainutils libxml-xpath-perl
          ./run_tests.sh prepare
          mkdir kcov_out/
          git config --global user.email "kw@kworkflow.net"
          git config --global user.name "Kworkflow"
          ./run_tests.sh
          kcov --include-path=src,kw \
          --exclude-pattern=src/bash_autocomplete.sh,src/help.sh \
          kcov_out/ ./run_tests.sh 
        '''
        cobertura autoUpdateHealth: false, autoUpdateStability: false, coberturaReportFile: 'kcov_out/', conditionalCoverageTargets: '70, 0, 0', failUnhealthy: false, failUnstable: false, lineCoverageTargets: '80, 0, 0', maxNumberOfBuilds: 0, methodCoverageTargets: '80, 0, 0', onlyStable: false, sourceEncoding: 'ASCII', zoomCoverageChart: false
      }
    }

  }
}
