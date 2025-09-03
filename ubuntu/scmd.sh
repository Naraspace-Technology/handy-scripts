#!/bin/bash
# scmd (Simple Command)

##############################################

execute_os_mode=0
# execute_os_mode: 0:ubuntu, 1:mac

##############################################

## Print usage
usage() {
    echo 'Simple Command'
    # echo '  -l, --length  LENGTH   Parameter Test'
    # echo '  -s                     Option Test'
    echo '  -v, --verbose          Increase verbosity'
    exit 1
}

log() {
    local MESSAGE="${@}"
    if [[ "${VERBOSE}" = 'true' ]]
    then
        echo "${MESSAGE}"
    fi
}

option_os_check(){
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "OS: macOS - o"
        echo " - This script command is only supported on Ubuntu."
        echo ''
        execute_os_mode=1
    else
        echo "OS: macOS - x"
        echo " - This script command is only supported on Ubuntu."
        echo ''
    fi
}

##############################################

## Print Args
TOTAL_ARGS=$#
ALL_ARGS=("$@")

log "Number of args: [${TOTAL_ARGS}]"
log "All args: [${ALL_ARGS[*]}]"

##############################################

option_os_check

if [ $execute_os_mode = 1 ]; then
    exit 1
fi

##############################################
## Parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        hello)
            log '> Hello' 
            shift
            ;;
        test)
            TEST=true
            shift
            ;;
        check-port)
            netstat -tnlp
            # netstat -tnlp | grep 포트번호
            
            shift
            ;;
        check-host)
            cat /etc/hosts
            shift
            ;;
        git-config)
            #git config --list
            #git config --list --global
            #git config --list --local
            #git config --list --show-origin
            git config --list --show-scope
            shift
            ;;
       
            
        --help|-h)
            usage
            shift
            ;;
        --verbose|-v)
            VERBOSE='true'
            log 'Verbose mode: [on]'
            shift
            ;;

        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

log '> Start script...'