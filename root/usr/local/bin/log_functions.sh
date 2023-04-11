#!/usr/bin/with-contenv bash

logf() {
    message_or_tag="$1"
    message="$2"
    logf_log_file="$3"
    if [ -z "$message" ]; then
        message=$message_or_tag
        tag="INC_FOLDER_SYNC"
    else
        tag=$message_or_tag
    fi
    
    log_message="$(date "$(printenv DATE_FORMAT)") $tag: $message"
    
    echo $log_message
    if ! [ -z "$logf_log_file" ]; then
        echo "$log_message" >> "$logf_log_file"
    fi
}

errorf() {
    message_or_tag="$1"
    message="$2"
    logf_log_file="$3"
    logf "ERROR: $message_or_tag" "$message" "$logf_log_file"
}