#!/bin/bash

set -euo pipefail

readonly BACKUP_DIR="/opt/spidersoft/backups"
readonly LOG_SCRIPT="/opt/spidersoft/scripts/log_message.sh"

SOURCE_DIR="${1:-/opt/spidersoft/app}"

PARENT_DIR="$(dirname "$SOURCE_DIR")"
DIR_NAME="$(basename "$SOURCE_DIR")"

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_NAME="${DIR_NAME}-${TIMESTAMP}.tar.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
TEMP_BACKUP="${BACKUP_PATH}.tmp"


log() {
    local level="$1"
    local message="$2"

    if [[ -x "$LOG_SCRIPT" ]]; then
        if ! "$LOG_SCRIPT" "$level" "$message"; then
            printf 'Warning: failed to write log message\n' >&2
        fi
    else
        printf 'Warning: log script not found or not executable: %s\n' \
            "$LOG_SCRIPT" >&2
    fi
}


cleanup() {
    if [[ -f "$TEMP_BACKUP" ]]; then
        rm -f "$TEMP_BACKUP"
    fi
}

trap cleanup EXIT


if [[ ! -d "$SOURCE_DIR" ]]; then
    printf "Directory '%s' does not exist.\n" "$SOURCE_DIR"

    log ERROR "Backup failed. Directory not found: $SOURCE_DIR"

    exit 1
fi


if ! mkdir -p "$BACKUP_DIR"; then
    printf "Failed to create backup directory: '%s'\n" "$BACKUP_DIR" >&2

    log ERROR "Backup failed. Cannot create backup directory: $BACKUP_DIR"

    exit 1
fi


printf "Creating backup...\n"
printf "Source: %s\n" "$SOURCE_DIR"
printf "Destination: %s\n" "$BACKUP_PATH"


if tar -czf "$TEMP_BACKUP" -C "$PARENT_DIR" "$DIR_NAME"; then

    if ! tar -tzf "$TEMP_BACKUP" >/dev/null; then
        printf "Backup verification failed.\n" >&2

        log ERROR "Backup verification failed: $BACKUP_NAME"

        exit 1
    fi

    if ! mv "$TEMP_BACKUP" "$BACKUP_PATH"; then
        printf "Failed to finalize backup: '%s'\n" "$BACKUP_PATH" >&2

        log ERROR "Backup failed. Cannot finalize: $BACKUP_NAME"

        exit 1
    fi

    log INFO "Backup created: $BACKUP_NAME"

    printf "Backup created successfully:\n"
    printf "%s\n" "$BACKUP_PATH"

else
    printf "Backup failed. See /var/log/spidersoft/admin.log for details.\n" >&2

    log ERROR "Backup failed: $BACKUP_NAME"

    exit 1
fi

