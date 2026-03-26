#!/bin/bash
# scmd (Simple Command)
# 자주 쓰지만 기억하기 어려운 Linux/macOS 명령어 모음

##############################################
# Version Info
##############################################
SCMD_VERSION="2026-03-26-160448"
SCMD_REMOTE_URL="https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/scmd.sh"

##############################################
# OS Detection
##############################################
OS_TYPE="unknown"
if [[ "$(uname)" == "Darwin" ]]; then
    OS_TYPE="macos"
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu) OS_TYPE="ubuntu" ;;
        debian) OS_TYPE="debian" ;;
        *)      OS_TYPE="linux"  ;;
    esac
else
    OS_TYPE="linux"
fi

##############################################
# Helpers
##############################################
VERBOSE='false'

log() {
    if [[ "${VERBOSE}" = 'true' ]]; then
        echo "$*"
    fi
}

section() {
    echo ""
    echo "========== $1 =========="
}

need_linux() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        echo "[ERROR] This command is only supported on Linux."
        return 1
    fi
    return 0
}

##############################################
# Usage
##############################################
usage_text() {
    cat <<'HELP'
scmd - Simple Command (자주 쓰지만 기억하기 어려운 명령어 모음)

Usage: scmd <command> [args...]

[System Info]
  sys-info              시스템 정보 요약 (OS, kernel, uptime, hostname)
  cpu-info              CPU 정보
  mem-info              메모리 사용량
  disk-info             디스크 사용량
  uptime                업타임

[Network]
  check-port            열린 포트 목록
  check-port-pid        특정 포트를 사용하는 프로세스 확인  (args: PORT)
  my-ip                 내부/외부 IP 주소
  check-host            /etc/hosts 내용 출력
  dns-lookup            DNS 조회                           (args: DOMAIN)
  check-conn            특정 호스트:포트 연결 테스트        (args: HOST PORT)

[Process]
  ps-top                CPU/MEM 상위 프로세스
  ps-find               프로세스 이름으로 검색              (args: NAME)
  kill-name             프로세스 이름으로 kill              (args: NAME)

[Docker]
  dk-ps                 실행 중인 컨테이너 목록
  dk-ps-all             전체 컨테이너 목록 (중지 포함)
  dk-images             Docker 이미지 목록
  dk-logs               컨테이너 로그 (tail)               (args: CONTAINER)
  dk-stats              컨테이너 리소스 사용량
  dk-clean              중지된 컨테이너 + dangling 이미지 정리
  dk-volume             Docker 볼륨 목록

[Service] (Linux only)
  svc-list              실행 중인 서비스 목록
  svc-status            서비스 상태 확인                    (args: SERVICE)
  svc-restart           서비스 재시작                       (args: SERVICE)
  svc-log               서비스 로그 (journalctl)            (args: SERVICE)

[File & Search]
  find-name             파일명으로 검색                     (args: PATTERN)
  find-text             파일 내용에서 텍스트 검색           (args: TEXT [PATH])
  find-large            큰 파일 찾기 (100MB+)              (args: [PATH])
  dir-size              디렉토리별 용량                     (args: [PATH])

[User & Permission]
  whoami-full           현재 사용자 + 그룹 정보
  perm-show             파일 권한 상세 표시                 (args: FILE)

[Git]
  git-config            git config 전체 출력 (scope 포함)
  git-log               최근 커밋 로그 (간결)
  git-branch            브랜치 목록 (로컬 + 리모트)
  git-size              git 저장소 크기

[Misc]
  timestamp             현재 시간 (UTC, KST, Unix timestamp)
  gen-password           랜덤 패스워드 생성                  (args: [LENGTH])
  encode-base64         Base64 인코딩                       (args: TEXT)
  decode-base64         Base64 디코딩                       (args: TEXT)

[Update]
  version               현재 scmd 버전(날짜) 표시
  update                최신 버전 확인 후 업데이트

[Options]
  -v, --verbose         상세 출력 모드
  -h, --help            이 도움말 표시
HELP
}

usage() {
    # 터미널이면 pager로, 파이프면 그냥 출력
    if [ -t 1 ] && command -v less &>/dev/null; then
        usage_text | less -R
    else
        usage_text
    fi
    exit 0
}

##############################################
# Commands
##############################################

# --- System Info ---

cmd_sys_info() {
    section "System Info"
    echo "OS       : $OS_TYPE"
    if [[ "$OS_TYPE" == "macos" ]]; then
        echo "Version  : $(sw_vers -productVersion)"
    elif [ -f /etc/os-release ]; then
        echo "Version  : $PRETTY_NAME"
    fi
    echo "Kernel   : $(uname -r)"
    echo "Hostname : $(hostname)"
    echo "Uptime   : $(uptime -p 2>/dev/null || uptime)"
}

cmd_cpu_info() {
    section "CPU Info"
    if [[ "$OS_TYPE" == "macos" ]]; then
        sysctl -n machdep.cpu.brand_string
        echo "Cores: $(sysctl -n hw.ncpu)"
    else
        lscpu | grep -E "^(Architecture|CPU\(s\)|Model name|Thread|Core)"
    fi
}

cmd_mem_info() {
    section "Memory Info"
    if [[ "$OS_TYPE" == "macos" ]]; then
        local total
        total=$(sysctl -n hw.memsize)
        echo "Total: $((total / 1024 / 1024)) MB"
        vm_stat | head -10
    else
        free -h
    fi
}

cmd_disk_info() {
    section "Disk Info"
    if [[ "$OS_TYPE" == "macos" ]]; then
        df -h | grep -E "^/dev|^Filesystem"
    else
        df -h --type=ext4 --type=xfs --type=btrfs --type=tmpfs 2>/dev/null || df -h
    fi
}

cmd_uptime() {
    uptime
}

# --- Network ---

cmd_check_port() {
    section "Listening Ports"
    if [[ "$OS_TYPE" == "macos" ]]; then
        lsof -iTCP -sTCP:LISTEN -n -P
    else
        ss -tlnp 2>/dev/null || netstat -tlnp
    fi
}

cmd_check_port_pid() {
    local port="$1"
    if [[ -z "$port" ]]; then
        echo "Usage: scmd check-port-pid <PORT>"
        return 1
    fi
    section "Process on port $port"
    if [[ "$OS_TYPE" == "macos" ]]; then
        lsof -iTCP:"$port" -sTCP:LISTEN -n -P
    else
        ss -tlnp "sport = :$port" 2>/dev/null || netstat -tlnp | grep ":$port"
    fi
}

cmd_my_ip() {
    section "IP Address"
    echo "[Internal]"
    if [[ "$OS_TYPE" == "macos" ]]; then
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print "  " $2}'
    else
        ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print "  " $2}'
    fi
    echo "[External]"
    echo "  $(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo 'N/A')"
}

cmd_check_host() {
    section "/etc/hosts"
    cat /etc/hosts
}

cmd_dns_lookup() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "Usage: scmd dns-lookup <DOMAIN>"
        return 1
    fi
    section "DNS Lookup: $domain"
    if command -v dig &>/dev/null; then
        dig +short "$domain"
    elif command -v nslookup &>/dev/null; then
        nslookup "$domain"
    else
        echo "dig/nslookup not found. Install dnsutils."
    fi
}

cmd_check_conn() {
    local host="$1"
    local port="$2"
    if [[ -z "$host" || -z "$port" ]]; then
        echo "Usage: scmd check-conn <HOST> <PORT>"
        return 1
    fi
    section "Connection Test: $host:$port"
    if command -v nc &>/dev/null; then
        nc -zv -w3 "$host" "$port" 2>&1
    elif [[ -e /dev/tcp ]]; then
        (echo >/dev/tcp/"$host"/"$port") 2>/dev/null && echo "OK" || echo "FAIL"
    else
        echo "nc not found. Install netcat."
    fi
}

# --- Process ---

cmd_ps_top() {
    section "Top Processes (CPU)"
    ps aux --sort=-%cpu 2>/dev/null | head -11 || ps aux -r | head -11
    section "Top Processes (MEM)"
    ps aux --sort=-%mem 2>/dev/null | head -11 || ps aux -m | head -11
}

cmd_ps_find() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: scmd ps-find <NAME>"
        return 1
    fi
    section "Processes matching: $name"
    ps aux | grep -i "$name" | grep -v "grep"
}

cmd_kill_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: scmd kill-name <NAME>"
        return 1
    fi
    echo "Killing processes matching: $name"
    pkill -f "$name" && echo "Done." || echo "No matching process found."
}

# --- Docker ---

cmd_dk_ps()      { docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"; }
cmd_dk_ps_all()  { docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}"; }
cmd_dk_images()  { docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"; }
cmd_dk_stats()   { docker stats --no-stream; }
cmd_dk_volume()  { docker volume ls; }

cmd_dk_logs() {
    local container="$1"
    if [[ -z "$container" ]]; then
        echo "Usage: scmd dk-logs <CONTAINER>"
        return 1
    fi
    docker logs --tail 100 -f "$container"
}

cmd_dk_clean() {
    echo "Removing stopped containers..."
    docker container prune -f
    echo "Removing dangling images..."
    docker image prune -f
    echo "Done."
}

# --- Service (Linux only) ---

cmd_svc_list() {
    need_linux || return
    systemctl list-units --type=service --state=running --no-pager
}

cmd_svc_status() {
    need_linux || return
    local svc="$1"
    if [[ -z "$svc" ]]; then
        echo "Usage: scmd svc-status <SERVICE>"
        return 1
    fi
    systemctl status "$svc" --no-pager
}

cmd_svc_restart() {
    need_linux || return
    local svc="$1"
    if [[ -z "$svc" ]]; then
        echo "Usage: scmd svc-restart <SERVICE>"
        return 1
    fi
    sudo systemctl restart "$svc"
    systemctl status "$svc" --no-pager
}

cmd_svc_log() {
    need_linux || return
    local svc="$1"
    if [[ -z "$svc" ]]; then
        echo "Usage: scmd svc-log <SERVICE>"
        return 1
    fi
    journalctl -u "$svc" --no-pager -n 50
}

# --- File & Search ---

cmd_find_name() {
    local pattern="$1"
    if [[ -z "$pattern" ]]; then
        echo "Usage: scmd find-name <PATTERN>"
        return 1
    fi
    find . -iname "*${pattern}*" 2>/dev/null | head -50
}

cmd_find_text() {
    local text="$1"
    local path="${2:-.}"
    if [[ -z "$text" ]]; then
        echo "Usage: scmd find-text <TEXT> [PATH]"
        return 1
    fi
    grep -rn --color=auto "$text" "$path" 2>/dev/null | head -50
}

cmd_find_large() {
    local path="${1:-.}"
    section "Files > 100MB in $path"
    find "$path" -type f -size +100M -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}'
}

cmd_dir_size() {
    local path="${1:-.}"
    du -sh "$path"/* 2>/dev/null | sort -rh | head -20
}

# --- User & Permission ---

cmd_whoami_full() {
    section "User Info"
    echo "User   : $(whoami)"
    echo "UID    : $(id -u)"
    echo "Groups : $(id -Gn)"
    if [[ "$OS_TYPE" != "macos" ]]; then
        echo "Shell  : $(getent passwd "$(whoami)" | cut -d: -f7)"
    else
        echo "Shell  : $SHELL"
    fi
}

cmd_perm_show() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: scmd perm-show <FILE>"
        return 1
    fi
    if [[ "$OS_TYPE" == "macos" ]]; then
        ls -la "$file"
        stat -f "Mode: %Sp (%Mp%Lp)  Owner: %Su  Group: %Sg" "$file"
    else
        ls -la "$file"
        stat -c "Mode: %A (%a)  Owner: %U  Group: %G" "$file"
    fi
}

# --- Git ---

cmd_git_config() {
    git config --list --show-scope
}

cmd_git_log() {
    git log --oneline --graph --decorate -20
}

cmd_git_branch() {
    section "Local Branches"
    git branch
    section "Remote Branches"
    git branch -r
}

cmd_git_size() {
    section "Git Repo Size"
    local size
    size=$(du -sh .git 2>/dev/null | awk '{print $1}')
    echo ".git directory: $size"
}

# --- Misc ---

cmd_timestamp() {
    section "Timestamp"
    echo "UTC   : $(TZ=UTC date '+%Y-%m-%d %H:%M:%S')"
    echo "KST   : $(TZ=Asia/Seoul date '+%Y-%m-%d %H:%M:%S')"
    echo "Unix  : $(date +%s)"
}

cmd_gen_password() {
    local length="${1:-32}"
    if command -v openssl &>/dev/null; then
        openssl rand -base64 48 | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c "$length"
    else
        cat /dev/urandom | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c "$length"
    fi
    echo ""
}

cmd_encode_base64() {
    local text="$1"
    if [[ -z "$text" ]]; then
        echo "Usage: scmd encode-base64 <TEXT>"
        return 1
    fi
    echo -n "$text" | base64
}

cmd_decode_base64() {
    local text="$1"
    if [[ -z "$text" ]]; then
        echo "Usage: scmd decode-base64 <TEXT>"
        return 1
    fi
    echo "$text" | base64 -d 2>/dev/null || echo "$text" | base64 -D
    echo ""
}

# --- Update ---

cmd_version() {
    echo "scmd version: $SCMD_VERSION"
}

cmd_update() {
    section "scmd update"
    echo "Current version : $SCMD_VERSION"

    # 임시 파일에 먼저 다운로드
    local tmp_file
    tmp_file=$(mktemp /tmp/scmd-update.XXXXXX)

    echo "Downloading latest version..."
    if ! curl -fsSL "$SCMD_REMOTE_URL" -o "$tmp_file" 2>/dev/null; then
        rm -f "$tmp_file"
        echo "[ERROR] Download failed. Check network connection."
        return 1
    fi

    # remote 파일에서 버전 파싱
    local remote_version
    remote_version=$(grep -m1 '^SCMD_VERSION=' "$tmp_file" | cut -d'"' -f2)

    if [[ -z "$remote_version" ]]; then
        rm -f "$tmp_file"
        echo "[ERROR] Failed to parse remote version."
        return 1
    fi

    echo "Latest version  : $remote_version"

    # 날짜 비교 (YYYY-MM-DD 형식이므로 문자열 비교로 충분)
    if [[ "$remote_version" > "$SCMD_VERSION" ]]; then
        echo ""
        echo "New version available! Updating..."

        local install_path
        install_path=$(command -v scmd 2>/dev/null || echo "/usr/local/bin/scmd")

        if sudo cp "$tmp_file" "$install_path" && sudo chmod 755 "$install_path"; then
            rm -f "$tmp_file"
            echo "[OK] Updated: $SCMD_VERSION -> $remote_version"
            echo "Run 'scmd version' to confirm."
        else
            rm -f "$tmp_file"
            echo "[ERROR] Failed to install. Check permissions."
            return 1
        fi
    else
        rm -f "$tmp_file"
        echo ""
        echo "Already up to date."
    fi
}

##############################################
# Parse global options first
##############################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE='true'
            log "Verbose mode: [on]"
            log "OS: $OS_TYPE"
            shift
            ;;
        *)
            break
            ;;
    esac
done

##############################################
# Route command
##############################################
if [[ $# -eq 0 ]]; then
    usage
fi

COMMAND="$1"
shift

case "$COMMAND" in
    # System
    sys-info)        cmd_sys_info ;;
    cpu-info)        cmd_cpu_info ;;
    mem-info)        cmd_mem_info ;;
    disk-info)       cmd_disk_info ;;
    uptime)          cmd_uptime ;;

    # Network
    check-port)      cmd_check_port ;;
    check-port-pid)  cmd_check_port_pid "$@" ;;
    my-ip)           cmd_my_ip ;;
    check-host)      cmd_check_host ;;
    dns-lookup)      cmd_dns_lookup "$@" ;;
    check-conn)      cmd_check_conn "$@" ;;

    # Process
    ps-top)          cmd_ps_top ;;
    ps-find)         cmd_ps_find "$@" ;;
    kill-name)       cmd_kill_name "$@" ;;

    # Docker
    dk-ps)           cmd_dk_ps ;;
    dk-ps-all)       cmd_dk_ps_all ;;
    dk-images)       cmd_dk_images ;;
    dk-logs)         cmd_dk_logs "$@" ;;
    dk-stats)        cmd_dk_stats ;;
    dk-clean)        cmd_dk_clean ;;
    dk-volume)       cmd_dk_volume ;;

    # Service
    svc-list)        cmd_svc_list ;;
    svc-status)      cmd_svc_status "$@" ;;
    svc-restart)     cmd_svc_restart "$@" ;;
    svc-log)         cmd_svc_log "$@" ;;

    # File & Search
    find-name)       cmd_find_name "$@" ;;
    find-text)       cmd_find_text "$@" ;;
    find-large)      cmd_find_large "$@" ;;
    dir-size)        cmd_dir_size "$@" ;;

    # User & Permission
    whoami-full)     cmd_whoami_full ;;
    perm-show)       cmd_perm_show "$@" ;;

    # Git
    git-config)      cmd_git_config ;;
    git-log)         cmd_git_log ;;
    git-branch)      cmd_git_branch ;;
    git-size)        cmd_git_size ;;

    # Misc
    timestamp)       cmd_timestamp ;;
    gen-password)    cmd_gen_password "$@" ;;
    encode-base64)   cmd_encode_base64 "$@" ;;
    decode-base64)   cmd_decode_base64 "$@" ;;

    # Update
    version)         cmd_version ;;
    update)          cmd_update ;;

    # Help
    --help|-h)       usage ;;

    *)
        echo "Unknown command: $COMMAND"
        echo "Run 'scmd --help' for available commands."
        exit 1
        ;;
esac
