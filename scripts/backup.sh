#!/bin/bash

SOURCE_DIR="${1:-/opt/spidersoft/app}"
BACKUP_DIR="/opt/spidersoft/backups"

PARENT_DIR=$(dirname "$SOURCE_DIR")
DIR_NAME=$(basename "$SOURCE_DIR")

TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="${DIR_NAME}-${TIMESTAMP}.tar.gz"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Directory '$SOURCE_DIR' does not exist."

    /opt/spidersoft/scripts/log_message.sh ERROR "Backup failed. Directory not found: $SOURCE_DIR"

    exit 1
fi

if tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$PARENT_DIR" "$DIR_NAME"; then
	/opt/spidersoft/scripts/log_message.sh INFO "Backup created: $BACKUP_NAME"
	echo "Backup created:"
	echo "$BACKUP_DIR/$BACKUP_NAME"
else
	/opt/spidersoft/scripts/log_message.sh ERROR "Backup failed."
	echo "Backup failed. See /var/log/spidersoft/admin.log for details."
	exit 1
fi



