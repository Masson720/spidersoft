#!/bin/bash

set -euo pipefail

readonly CURRENT_VERSION_FILE="/opt/spidersoft/app/current-version"
readonly LOG_SCRIPT="/opt/spidersoft/scripts/log_message.sh"

HOSTNAME="$(hostname)"
CURRENT_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
CURRENT_USER="$(whoami)"
KERNEL="$(uname -r)"
UPTIME="$(uptime -p)"

# Get primary IP address
IP_ADDRESS="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"

if [[ -z "$IP_ADDRESS" ]]; then
    IP_ADDRESS="Unknown"
fi

# Get SSH service status.
# systemctl is-active returns non-zero when the service is not active,
# but this is expected and should not terminate the script.
if SSH_STATUS="$(systemctl is-active ssh 2>/dev/null)"; then
    :
else
    SSH_STATUS="${SSH_STATUS:-unknown}"
fi

# Get CPU model
CPU_MODEL="$(
    LC_ALL=C lscpu 2>/dev/null |
        awk -F: '/^Model name:/ {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
            print $2
            exit
        }' || true
)"

if [[ -z "$CPU_MODEL" ]]; then
    CPU_MODEL="Unknown"
fi

# Get RAM usage
RAM_USAGE="$(
    free -h 2>/dev/null |
        awk '/^Mem:/ {
            print $3 " / " $2
            exit
        }' || true
)"

if [[ -z "$RAM_USAGE" ]]; then
    RAM_USAGE="Unknown"
fi

# Get root filesystem usage
DISK_USAGE="$(
    df -hP / 2>/dev/null |
        awk 'NR == 2 {
            print $3 " / " $2 " (" $5 " used)"
            exit
        }' || true
)"

if [[ -z "$DISK_USAGE" ]]; then
    DISK_USAGE="Unknown"
fi

# Write execution log.
# Logging failure should not prevent server information from being displayed.
if [[ -x "$LOG_SCRIPT" ]]; then
    if ! "$LOG_SCRIPT" INFO "server-info.sh executed by $CURRENT_USER"; then
        printf 'Warning: failed to write execution log\n' >&2
    fi
else
    printf 'Warning: log script not found or not executable: %s\n' "$LOG_SCRIPT" >&2
fi

printf '%s\n' "========================================="
printf '%s\n' "SpiderSoft Server Information"
printf '%s\n' "========================================="
printf '\n'

printf '%s\n' "Hostname:"
printf '%s\n' "$HOSTNAME"
printf '\n'

printf '%s\n' "Current User:"
printf '%s\n' "$CURRENT_USER"
printf '\n'

printf '%s\n' "Kernel:"
printf '%s\n' "$KERNEL"
printf '\n'

printf '%s\n' "Current date:"
printf '%s\n' "$CURRENT_DATE"
printf '\n'

printf '%s\n' "Uptime:"
printf '%s\n' "$UPTIME"
printf '\n'

printf '%s\n' "CPU:"
printf '%s\n' "$CPU_MODEL"
printf '\n'

printf '%s\n' "RAM:"
printf '%s\n' "$RAM_USAGE"
printf '\n'

printf '%s\n' "Disk Usage:"
printf '%s\n' "$DISK_USAGE"
printf '\n'

printf '%s\n' "IP Address:"
printf '%s\n' "$IP_ADDRESS"
printf '\n'

printf '%s\n' "SSH Status:"

if [[ "$SSH_STATUS" == "active" ]]; then
    printf '\033[32m%s\033[0m\n' "$SSH_STATUS"
else
    printf '\033[31m%s\033[0m\n' "$SSH_STATUS"
fi

printf '\n'

printf '%s\n' "Docker:"
if command -v docker >/dev/null 2>&1; then
    printf '\033[32m%s\033[0m\n' "Installed"
else
    printf '\033[31m%s\033[0m\n' "Not Installed"
fi

printf '\n'

printf '%s\n' "Git:"
if command -v git >/dev/null 2>&1; then
    printf '\033[32m%s\033[0m\n' "Installed"
else
    printf '\033[31m%s\033[0m\n' "Not Installed"
fi

printf '\n'

printf '%s\n' "=== Текущая версия API ==="

if [[ -f "$CURRENT_VERSION_FILE" && -r "$CURRENT_VERSION_FILE" ]]; then
    API_VERSION="$(<"$CURRENT_VERSION_FILE")"

    if [[ -n "$API_VERSION" ]]; then
        printf '  %s\n' "$API_VERSION"
    else
        printf '  ⚠️ Неизвестно (файл current-version пуст)\n'
    fi
else
    printf '  ⚠️ Неизвестно (файл current-version не найден или недоступен)\n'
fi

printf '%s\n' "========================================="
