#!/bin/bash

HOSTNAME=$(hostname)
SSH_STATUS=$(systemctl is-active ssh)
IP_ADDRESS=$(hostname -I | awk '{print $1}')
CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
CURRENT_USER=$(whoami)

/opt/spidersoft/scripts/log_message.sh INFO "server-info.sh executed by $CURRENT_USER"

echo "========================================="
echo "SpiderSoft Server Information"
echo "========================================="
echo

echo "Hostname:"
echo "$HOSTNAME"
echo

echo "Current User:"
echo "$CURRENT_USER"
echo

echo "Kernel:"
uname -r
echo

echo "Current date:"
echo "$CURRENT_DATE"
echo

echo "Uptime:"
uptime -p
echo

echo "CPU:"
lscpu | grep "Model name" | sed 's/Model name:[[:space:]]*//'
echo

echo "RAM:"
free -h | awk '/Mem:/ {print $3 " / " $2}'
echo

echo "Disk Usage:"
df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}'
echo

echo "IP Address:"
echo "$IP_ADDRESS"
echo


echo "SSH Status:"

if [ "$SSH_STATUS" = "active" ]; then
    echo -e "\e[32m$SSH_STATUS\e[0m"
else
    echo -e "\e[31m$SSH_STATUS\e[0m"
fi

echo

echo "Docker:"
if command -v docker >/dev/null 2>&1; then
    echo -e "\e[32mInstalled\e[0m"
else
    echo -e "\e[31mNot Installed\e[0m"
fi
echo

echo "Git:"
if command -v git >/dev/null 2>&1; then
    echo -e "\e[32mInstalled\e[0m"
else
    echo -e "\e[31mNot Installed\e[0m"
fi
echo

echo ""
echo "=== Текущая версия API ==="
if [ -f /opt/spidersoft/app/current-version ]; then
    echo "  $(cat /opt/spidersoft/app/current-version)"
else
    echo "  ⚠️ Неизвестно (файл current-version не найден)"
fi

echo "========================================="
