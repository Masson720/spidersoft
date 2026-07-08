#!/bin/bash

LOG_FILE="/var/log/spidersoft/admin.log"

LEVEL="$1"
MESSAGE="$2"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

case "$LEVEL" in 
	INFO|WARNING|ERROR|DEBUG)
	;;
	*)
	echo "invalid log level: $LEVEL"
	echo "Allowed levels: INFO WARNING ERROR DEBUG"
	exit 1
	;;
esac

if [ -n "$LEVEL" ] && [ -n "$MESSAGE" ]; then
	echo "$TIMESTAMP [$LEVEL] $MESSAGE" >> "$LOG_FILE"
else
	printf "Usage: log_message.sh LEVEL \"MESSAGE\""
	exit 1
fi
