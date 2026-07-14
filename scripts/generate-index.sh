#!/bin/bash

OUTPUT_FILE="/var/www/spidersoft/index.html"

HOSTNAME=$(hostname)
KERNEL=$(uname -r)
RAM=$(free -h | awk '/^Mem:/ {print $2}')
IP_ADDRESS=$(hostname -I | awk '{print $1}')

cat > "$OUTPUT_FILE" << EOF
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

echo "Web page generated successfully."
