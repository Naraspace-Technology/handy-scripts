#!/bin/bash
# 2025.02.04 기준.
# - 아래 명령어 사용 했던 타켓 OS 기록
#   : Ubuntu 24.04.1 LTS


############################################
# 도커 설치
############################################
sudo apt-get -y install apt-transport-https ca-certificates curl gnupg lsb-release
sudo apt-get -y update

cd ~/
mkdir temp
cd temp

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh


############################################
# 도커 컴포즈 설치 설치
############################################
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
DESTINATION=/usr/local/bin/docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
sudo chmod 755 $DESTINATION
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version


############################################
# 자주 사용하는 패키지 설치
############################################
sudo apt install -y net-tools iputils-ping iproute2 git wget vim make


############################################
# git-cli 설치
############################################
sudo  apt install -y gh