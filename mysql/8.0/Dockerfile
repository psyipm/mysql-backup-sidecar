FROM ubuntu:noble

LABEL maintainer="Wolfgang Gassler"
LABEL description="XtraBackup based MySQL / MariaDB backup docker image to create incremental backups periodically"

# installing xtrabackup according to https://docs.percona.com/percona-xtrabackup/8.0/apt-repo.html

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update \
    && apt install -y curl cron tini \
    && curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb \
    && apt install -y gnupg2 lsb-release ./percona-release_latest.generic_all.deb \
    && apt update \
    && percona-release setup pxb-80 \
    && apt install -y percona-xtrabackup-80 \
    && apt clean \
    && rm -rf ./percona-release_latest.generic_all.deb /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/cron.*/*

COPY scripts /scripts

VOLUME /backup /var/lib/mysql
WORKDIR /backup

ENTRYPOINT ["tini", "--"]

CMD ["/scripts/start.sh"]
