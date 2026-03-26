# handy-scripts

## 0. Purpose

- Debian/Ubuntu 기반의 새로운 PC나 컨테이너에서 환경을 빠르게 설정
- 편의 기능 구성 (scmd)
- 필요한 각종 명령어 및 스크립트 모음

### 왜 scmd인가?

tldr, navi, cheat.sh 같은 훌륭한 도구들이 이미 있지만, 각각 Node.js, Rust, Python 등 별도 런타임이 필요합니다.

scmd는 다른 문제를 풉니다:
- **OS 프로비저닝 직후 서버** — npm/pip/cargo가 없는 환경에서 `curl` 한 줄로 즉시 사용
- **단일 명령어가 아닌 워크플로우 캡슐화** — `scmd my-ip`는 내부/외부 IP를 동시 조회하고, `scmd dk-clean`은 중지된 컨테이너 + dangling 이미지를 한번에 정리
- **팀 서버 운영 SOP의 코드화** — 팀 전체가 동일한 진단/운영 명령어 세트를 공유

범용 치트시트 도구가 아닌, **팀 내 서버 운영 표준 도구**가 목표입니다.


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
- OS 자동 감지 (Ubuntu, Debian, macOS) 후 해당 OS에 맞는 명령어로 실행
- 30개+ 명령어 지원: 시스템 정보, 네트워크, 프로세스, Docker, 서비스 관리, 파일 검색, Git 등
- 사용법: `scmd --help`
- 업데이트: `scmd update` (자동 버전 비교) 또는 `scmd update --force` (강제)
- 수동 업데이트 (구버전 scmd를 사용 중이라면):
```bash
sudo curl -fsSL https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/scmd.sh -o /usr/local/bin/scmd && sudo chmod 755 /usr/local/bin/scmd
```


## 3. 지원 OS

- Ubuntu (24.04+)
- Debian (12+)


## 4. 프로젝트 구조

```
handy-scripts/
├── setup.sh    # 통합 설치 스크립트 (Docker, Compose, Python3, scmd 등)
├── scmd.sh     # 자주 쓰는 명령어 모음 (Simple Command)
├── LICENSE
└── README.md
```
