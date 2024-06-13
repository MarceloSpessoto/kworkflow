FROM jenkins/jenkins:lts
USER root

RUN apt update -y \
    && apt install -y binutils-dev libssl-dev libcurl4-openssl-dev zlib1g-dev libdw-dev libiberty-dev cmake build-essential python3 

RUN apt install -y shunit2 bc sqlite3 bsdmainutils libxml-xpath-perl 
USER kworkflow
