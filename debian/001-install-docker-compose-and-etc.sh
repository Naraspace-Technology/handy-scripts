# 파싱용 필요 툴 설치
sudo apt install jq -y

#최신 버전 설치
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)
DESTINATION=/usr/bin/docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
sudo chmod 755 $DESTINATION

#설치 버전 확인
docker-compose -v

# github cli install
apt install gh

# 기타 툴 설치
apt install -y net-tools make