# handy-scripts

## 0. purpose

- Debian/Ubuntu 기반의 새로운 PC나 컨테이너에서 환경을 설정
- 편의 기능 구성
- 필요한 각종 명령어 및 스크립트 모음


## 1. memo

### 1.1 download ./ubuntu/scmd.sh

- 다음과 같이 다운로드.
- 이외의 파일들도 다음을 응용해서 다운.

```bash
    wget https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/ubuntu/scmd.sh
```


## A. 자주 사용하는 것 모음

- ubuntu docker + docker-compose 설치 스크립트
```bash
    #설치 안받고 바로 실행
    curl -fsSL https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/ubuntu/001-install-docker-and-docker-compose-and-etc.sh | bash
```

- debian docker-compose 설치 스크립트
```bash
    #설치 안받고 바로 실행
    curl -fsSL https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/debian/001-install-docker-compose-and-etc.sh | bash
```
