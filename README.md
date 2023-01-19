# docker-mergerfs

[![buildx](https://github.com/slink42/docker-incremental-folder-sync/actions/workflows/buildx.yml/badge.svg?branch=master)](https://github.com/slink42/docker-incremental-folder-sync/actions/workflows/buildx.yml)

Docker image for syncing folders containing large numbers of files with a central master using incremental backups to a rclone remote, with

- Ubuntu 20.04
- some useful scripts

## Usage

```yaml
version: '3'

services:
  rclone:
    container_name: mergerfs
    image: slink42/mergerfs
    restart: always
    network_mode: "bridge"
    volumes:
      - /path/to/config/folder:/config
      - /path/to/target/folder:/extracted_files
    devices:
      - /dev/fuse
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=Australia/Sydney
      - MODE=RESTORE
      - RCLONE_REMOTE=rclone_remote_name
      - RCLONE_PATH=path/in/rclone/remote
```



equivalently,

```bash
docker run -d \
    --name incremental-sync \
    -e MODE=RESTORE \
    -e RCLONE_REMOTE=rclone_remote_name \
    -e RCLONE_PATH=path/in/rclone/remote \
    -e CONFIG_PATH=/config \
    -v /path/to/config/folder:/config \
    -e EXTRACTED_FILES_PATH=/extracted_files \
    -v /path/to/target/folder:/extracted_files \
    slink42/incremental-folder-sync
```

First, you setup your rclone config.

```bash
commands example for setting up rclone config
```

Then, setup and run your container with environment variables configured to refrence a location within the configured rclone remote which can be used as location for incremental tar backup files

```bash
docker logs <container name or sha1, e.g. incremental-sync>
```


## Credit

- [docker-rclone](https://github.com/wiserain/docker-rclone)
