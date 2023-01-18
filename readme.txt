docker run \
    -e EXTRACTED_FILES_PATH=/extracted_files \
    -e CONFIG_PATH=/config \
    -e RCLONE_REMOTE=secure_backup_rw \
    -e RCLONE_PATH=plex_library_backup/meta \
    -v /mnt/c/Users/stuar/config:/config \
    -v /mnt/c/Users/stuar/libfiles:/extracted_files \
    incremental-folder-sync