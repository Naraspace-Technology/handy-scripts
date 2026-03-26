# handy-scripts

## 0. Purpose

- Debian/Ubuntu 기반의 새로운 PC나 컨테이너에서 환경을 빠르게 설정
- 편의 기능 구성 (scmd)
- 필요한 각종 명령어 및 스크립트 모음


## 1. Quick Start

통합 설치 스크립트 `setup.sh` 하나로 모든 설정을 처리합니다.

### 대화형 (메뉴에서 선택)

```bash
curl -fsSL https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/setup.sh | bash
```

### 옵션으로 바로 실행

```bash
# 기본 설치 (Docker + Compose + Python3 + git-cli + vim + 유틸리티 + KST)
curl -fsSL https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/setup.sh | bash -s -- --install

# scmd 유틸리티만 설치
curl -fsSL https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/setup.sh | bash -s -- --scmd

# 전부 설치 (기본 설치 + scmd)
curl -fsSL https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/setup.sh | bash -s -- --all
```


## 2. 설치 항목

### Base install (`--install`)

| 항목 | 설명 |
|------|------|
| Docker Engine | `get.docker.com` 스크립트로 설치 |
| Docker Compose | 최신 릴리즈 자동 감지 및 설치 |
| Python3 | python3 + pip + venv |
| Git + GitHub CLI | git, gh |
| 유틸리티 | vim, make, wget, net-tools, iputils-ping, iproute2, jq |
| 시간대 | Asia/Seoul (KST) |

### scmd install (`--scmd`)

- `scmd` 명령어를 `/usr/local/bin/scmd`에 설치
- 포트 확인, 호스트 확인, git config 등 자주 쓰는 명령어 모음
- 사용법: `scmd --help`


## 3. 지원 OS

- Ubuntu (24.04+)
- Debian (12+)


## A. Legacy (개별 스크립트)

> `setup.sh` 통합 스크립트 사용을 권장합니다.

- ubuntu docker + docker-compose 설치 스크립트
```bash
curl -fsSL https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/ubuntu/001-install-docker-and-docker-compose-and-etc.sh | bash
```

- debian docker-compose 설치 스크립트
```bash
curl -fsSL https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/debian/001-install-docker-compose-and-etc.sh | bash
```
