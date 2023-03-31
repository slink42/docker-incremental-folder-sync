#!/usr/bin/with-contenv bash

logf() {
    if [ -z "$2" ]; then
        log_message="$(date "$(printenv DATE_FORMAT)") INC_FOLDER_SYNC: $1"
    else
        log_message="$(date "$(printenv DATE_FORMAT)") $1: $2"
    fi
    echo $log_message
    if ! [ -z "$3" ]; then
        echo $log_message >> $3
    fi
}

errorf() {
    logf " ERROR: $1: $2"
}