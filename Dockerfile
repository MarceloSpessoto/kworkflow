FROM jenkins/jenkins:lts
USER root

RUN apt update -y \
    && apt install -y binutils-dev libssl-dev libcurl4-openssl-dev zlib1g-dev libdw-dev libiberty-dev cmake build-essential python3 
#    && cmake . \
#    && make \
#    && make install
#
#COPY /kworkflow/ /tests/ 
#WORKDIR /tests/
RUN apt install -y shunit2 bc sqlite3 bsdmainutils libxml-xpath-perl 
USER kworkflow
#    && ls \
#    && ./run_tests.sh prepare \
#    && mkdir kcov_out/ \
#    && git config --global user.email "kw@kworkflow.net" \
#    && git config --global user.name "Kworkflow" \
#    && ./run_tests.sh prepare \
#    && kcov --include-path=src,kw --exclude-pattern=src/bash_autocomplete.sh,src/help.sh kcov_out/ ./run_tests.sh
