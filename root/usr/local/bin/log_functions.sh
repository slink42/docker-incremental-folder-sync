#!/usr/bin/with-contenv bash

logf() {
    if [ -z "$2" ]; then
        echo "$(date "$(printenv DATE_FORMAT)") INC_FOLDER_SYNC: $1"
    else
        echo "$(date "$(printenv DATE_FORMAT)") $1: $2"
    fi
}

errorf() {
    logf " ERROR: $1: $2"
}