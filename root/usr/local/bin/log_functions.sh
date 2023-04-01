#!/usr/bin/with-contenv bash

logf() {
    message_or_tag="$1"
    message="$2"
    log_file="$3"
    if [ -z "$message_tag" ]; then
        log_message="$(date "$(printenv DATE_FORMAT)") INC_FOLDER_SYNC: $message_or_tag"
    else
        log_message="$(date "$(printenv DATE_FORMAT)") $message_or_tag: $message"
    fi
    echo $log_message
    if ! [ -z "$log_file" ]; then
        echo "$log_message" >> "$log_file"
    fi
}

errorf() {
    message_or_tag="$1"
    message="$2"
    log_file="$3"
    logf "ERROR: $message_or_tag" "$message" "$log_file"
}