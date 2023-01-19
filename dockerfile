ARG UBUNTU_VER=20.04
ARG UBUNTU_VER_SHA=@sha256:6cad3b09aa963b47380bbf0053980f22d27bb4b575ff5b171bb9c00a239ad018
FROM ubuntu:${UBUNTU_VER} AS ubuntu
FROM ghcr.io/by275/base:ubuntu${UBUNTU_VER}${UBUNTU_VER_SHA} AS prebuilt

# 
# BUILD
# 
FROM ubuntu AS builder

ARG RCLONE_TYPE="latest"
ARG DEBIAN_FRONTEND="noninteractive"

# add go-cron
COPY --from=prebuilt /go/bin/go-cron /bar/usr/local/bin/

# add s6 overlay
COPY --from=prebuilt /s6/ /bar/

RUN \
    echo "**** add rclone ****" && \
    apt-get update -qq && \
    apt-get install -yq --no-install-recommends \
        ca-certificates \
        curl \
        tar \
        pv \
        unzip && \
    if [ "${RCLONE_TYPE}" = "latest" ]; then \
        rclone_install_script_url="https://rclone.org/install.sh"; \
    elif [ "${RCLONE_TYPE}" = "mod" ]; then \
        rclone_install_script_url="https://raw.githubusercontent.com/wiserain/rclone/mod/install.sh"; fi && \
    curl -fsSL $rclone_install_script_url | bash && \
    mv /usr/bin/rclone /bar/usr/bin/rclone

# add local files
COPY scripts/ /scripts/
RUN chmod +x -R /scripts

ENV EXTRACTED_FILES_PATH=/extracted_files
ENV CONFIG_PATH=/config
ENV RCLONE_REMOTE=SECURE_BACKUP
ENV RCLONE_PATH=

CMD ["/scripts/incremental_folder_sync.sh"] 
# ENTRYPOINT ["/scripts/incremental_folder_sync.sh"]