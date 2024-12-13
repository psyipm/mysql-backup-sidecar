#!/bin/bash

CRON_PATTERN=${CRON_SCHEDULE:-"5 5 * * *"}

CRON_FILE=/etc/crontab

echo -e "${CRON_PATTERN} root \
/scripts/backup.sh > /proc/1/fd/1 2>/proc/1/fd/2 \
&& /scripts/rotate.sh > /proc/1/fd/1 2>/proc/1/fd/2 \n" > ${CRON_FILE}

env > /etc/environment

echo "starting cron to execute xtrabackup periodically (${CRON_PATTERN})"

crontab -n $CRON_FILE && cron -f -l 2
