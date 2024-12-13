#!/bin/bash

# MySQL server data directory
MYSQL_DATA_DIR=${MYSQL_DATA_DIR:-/var/lib/mysql}
# Wipe the MySQL data directory before restoring the backup
WIPE_DATA_DIR=${WIPE_DATA_DIR:-true}

# Load backup-sidecar configuration and functions
source $(dirname "$0")/config.sh
source $(dirname "$0")/functions.sh

###

LAST_FULL_BACKUP=$(find_newest_backup $(full_backups))
FULL_BACKUP_DIR=$(dirname $LAST_FULL_BACKUP)
FULL_BACKUP_LSN=$(get_lsn $LAST_FULL_BACKUP)

echo "Last full backup: $FULL_BACKUP_DIR"

# Find incremental backups that are based on the last full backup
INCREMENTAL_BACKUPS=""

for inc_backup in $(inc_backups); do
  inc_backup_dir=$(dirname $inc_backup)

  if [ "$(get_lsn $inc_backup)" -ge $FULL_BACKUP_LSN ]
  then
    echo "Found incremental backup based on the last full backup: $inc_backup_dir"
    INCREMENTAL_BACKUPS="$INCREMENTAL_BACKUPS $inc_backup_dir"
  fi
done

# Prepare the full backup
echo "Decompressing full backup $FULL_BACKUP_DIR..."
${xtrabackup} --decompress --target-dir=$FULL_BACKUP_DIR

echo "Preparing full backup $FULL_BACKUP_DIR..."
${xtrabackup} --prepare --apply-log-only --target-dir=$FULL_BACKUP_DIR

# Prepare incremental backups
for inc_backup in "${INCREMENTAL_BACKUPS[@]}"; do
  echo "Decompressing incremental backup $inc_backup..."
  ${xtrabackup} --decompress --target-dir=$inc_backup

  echo "Preparing incremental backup $inc_backup..."
  ${xtrabackup} --prepare --apply-log-only --target-dir=$FULL_BACKUP_DIR --incremental-dir=$inc_backup
done

# Prepare the final backup
echo "Preparing the final backup..."
${xtrabackup} --prepare --target-dir=$FULL_BACKUP_DIR

# Make sure the MySQL data directory is empty
if [ "$WIPE_DATA_DIR" == true ]; then
  echo "Wiping MySQL data directory..."
  rm -rf $MYSQL_DATA_DIR/*
fi

if [ "$(ls -A $MYSQL_DATA_DIR)" ]; then
  echo "Error: MySQL data directory is not empty"
  exit 1
fi

# Restore the backup
echo "Restoring the backup..."
${xtrabackup} --copy-back --datadir=$MYSQL_DATA_DIR --target-dir=$FULL_BACKUP_DIR
