FROM jenkins/jenkins:lts
USER root

RUN apt update -y \
    && apt install -y binutils-dev libssl-dev libcurl4-openssl-dev zlib1g-dev libdw-dev libiberty-dev cmake build-essential python3 wget


RUN mkdir kcov_build \
    && cd kcov_build \ 
    && wget https://github.com/SimonKagstrom/kcov/archive/master.tar.gz \
    && tar -xzf master.tar.gz \
    && cd kcov-master \
    && cmake . \
    && make \
    && make install \
    && cd / \
    && rm -rf kcov_build

RUN wget https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz \
    && tar -xf shellcheck-v0.10.0.linux.x86_64.tar.xz \
    && cp shellcheck-v0.10.0/shellcheck /usr/bin/ \
    && rm -rf shellcheck-v0.10.0

RUN apt install -y shunit2 bc sqlite3 bsdmainutils libxml-xpath-perl software-properties-common python3-launchpadlib \
    python3-venv python3-pip
#USER kworkflow
