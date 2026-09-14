#!/bin/bash

set -Eeuo pipefail

readonly OUTPUT_FILE="/var/www/spidersoft/index.html"
readonly OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
readonly TEMP_FILE="${OUTPUT_FILE}.tmp"

HOSTNAME="$(hostname)"
KERNEL="$(uname -r)"

RAM="$(
    free -h 2>/dev/null |
        awk '/^Mem:/ {
            print $2
            exit
        }' ||
        true
)"

IP_ADDRESS="$(
    hostname -I 2>/dev/null |
        awk '{print $1}' ||
        true
)"

if [[ -z "$RAM" ]]; then
    RAM="Unknown"
fi

if [[ -z "$IP_ADDRESS" ]]; then
    IP_ADDRESS="Unknown"
fi

if [[ ! -d "$OUTPUT_DIR" ]]; then
    printf 'Error: output directory does not exist: %s\n' "$OUTPUT_DIR" >&2
    exit 1
fi

cleanup() {
    if [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
}

trap cleanup EXIT

cat > "$TEMP_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>SpiderSoft Infrastructure</title>
</head>
<body>

<h1>🕷 SpiderSoft Infrastructure</h1>

<p><strong>Hostname:</strong> $HOSTNAME</p>
<p><strong>Kernel:</strong> $KERNEL</p>
<p><strong>RAM:</strong> $RAM</p>
<p><strong>IP Address:</strong> $IP_ADDRESS</p>

</body>
</html>
EOF

if ! mv "$TEMP_FILE" "$OUTPUT_FILE"; then
    printf 'Error: failed to replace output file: %s\n' "$OUTPUT_FILE" >&2
    exit 1
fi

printf 'Web page generated successfully.\n'
printf 'Output: %s\n' "$OUTPUT_FILE"
