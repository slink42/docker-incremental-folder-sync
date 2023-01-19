FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    rclone  \
    tar     \
    pv

ENV EXTRACTED_FILES_PATH=/extracted_files
ENV CONFIG_PATH=/config
ENV RCLONE_REMOTE=SECURE_BACKUP
ENV RCLONE_PATH=

ADD scripts /scripts
RUN chmod +x -R /scripts
RUN echo rclone version

CMD ["/scripts/incremental_folder_sync.sh"] 
# ENTRYPOINT ["/scripts/incremental_folder_sync.sh"]