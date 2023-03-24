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
        ca-certificates curl unzip && \
    if [ "${RCLONE_TYPE}" = "latest" ]; then \
        rclone_install_script_url="https://rclone.org/install.sh"; \
    elif [ "${RCLONE_TYPE}" = "mod" ]; then \
        rclone_install_script_url="https://raw.githubusercontent.com/wiserain/rclone/mod/install.sh"; fi && \
    curl -fsSL $rclone_install_script_url | bash && \
    mv /usr/bin/rclone /bar/usr/bin/rclone

# add local files
COPY root/ /bar/

ADD https://raw.githubusercontent.com/by275/docker-base/main/_/etc/cont-init.d/adduser /bar/etc/cont-init.d/10-adduser
ADD https://raw.githubusercontent.com/by275/docker-base/main/_/etc/cont-init.d/install-pkg /bar/etc/cont-init.d/20-install-pkg

# 
# RELEASE
# 
FROM ubuntu
LABEL maintainer="slink42"
LABEL org.opencontainers.image.source https://github.com/slink42/docker-mergerfs

ARG DEBIAN_FRONTEND="noninteractive"
ARG APT_MIRROR="archive.ubuntu.com"

# add build artifacts
COPY --from=builder /bar/ /

# install packages
RUN \
    echo "**** apt source change for local build ****" && \
    sed -i "s/archive.ubuntu.com/$APT_MIRROR/g" /etc/apt/sources.list && \
    echo "**** install runtime packages ****" && \
    apt-get update && \
    apt-get install -yq --no-install-recommends apt-utils && \
    apt-get install -yq --no-install-recommends \
        bc \
        ca-certificates \
        fuse3 \
        jq \
        lsof \
        openssl \
        tzdata \
        unionfs-fuse \
        pv \
        tar \
        wget && \
    update-ca-certificates && \
    sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf && \
    echo "**** create abc user ****" && \
    useradd -u 911 -U -d /config -s /bin/false abc && \
    usermod -G users abc && \
    echo "**** permissions ****" && \
    chmod a+x /usr/local/bin/* && \
    echo "**** cleanup ****" && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /tmp/* /var/lib/{apt,dpkg,cache,log}/

# environment settings
ENV \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_KILL_FINISH_MAXTIME=7000 \
    S6_SERVICES_GRACETIM=5000 \
    S6_KILL_GRACETIME=5000 \
    LANG=C.UTF-8 \
    PS1="\u@\h:\w\\$ " \
    EXTRACTED_FILES_PATH=/extracted_files \
    CONFIG_PATH=/config \
    RCLONE_REMOTE=SECURE_BACKUP \
    RCLONE_PATH= \
    RCLONE_CONFIG=/config/rclone.conf \
    DATE_FORMAT="+%4Y/%m/%d %H:%M:%S"

VOLUME /config /log
WORKDIR /${CONFIG_PATH}

ENTRYPOINT ["/init"]