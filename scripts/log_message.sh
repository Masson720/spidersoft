#!/bin/bash

set -Eeuo pipefail

readonly LOG_FILE="/var/log/spidersoft/admin.log"

if [[ $# -ne 2 ]]; then
    printf 'Usage: %s LEVEL "MESSAGE"\n' "$0" >&2
    printf 'Allowed levels: INFO WARNING ERROR DEBUG\n' >&2
    exit 1
fi

LEVEL="$1"
MESSAGE="$2"

case "$LEVEL" in
    INFO|WARNING|ERROR|DEBUG)
        ;;
    *)
        printf 'Error: invalid log level: %s\n' "$LEVEL" >&2
        printf 'Allowed levels: INFO WARNING ERROR DEBUG\n' >&2
        exit 1
        ;;
esac

if [[ -z "$MESSAGE" ]]; then
    printf 'Error: message cannot be empty.\n' >&2
    exit 1
fi

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Keep each log entry on a single line.
MESSAGE="${MESSAGE//$'\n'/ }"

if ! printf '%s [%s] %s\n' \
    "$TIMESTAMP" \
    "$LEVEL" \
    "$MESSAGE" >> "$LOG_FILE"; then

    printf 'Error: failed to write to log file: %s\n' "$LOG_FILE" >&2
    exit 1
fi
