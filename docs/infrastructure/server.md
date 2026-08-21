В этом документе описывается базовое состояние сервера, на котором работает инфраструктура SpiderSoft: ОС, пользователи, SSH, системные настройки и базовые утилиты.

markdown
# Серверная инфраструктура

В проекте используется **один выделенный сервер** (виртуальная машина), на котором развёрнуты все сервисы.

---

## 🖥️ Общая информация

| Параметр | Значение |
|----------|----------|
| **ОС** | Debian GNU/Linux 13 (trixie) |
| **Кодовая база** | `/opt/spidersoft` |
| **Хостнейм** | `spider-app-01` |
| **Архитектура** | x86_64 |
| **Ядро** | 6.12.90+deb13.1-amd64 |
| **Часовой пояс** | Europe/Moscow (UTC+3) |
| **Локаль** | ru_RU.UTF-8 (при необходимости) |

---

## 👤 Пользователи

| Пользователь | Роль | Домашняя папка | Shell |
|--------------|------|----------------|-------|
| `devops` | Основной пользователь | `/home/devops` | `/bin/bash` |
| `root` | Администратор | `/root` | `/bin/bash` |

**Рекомендация:** не использовать `root` для повседневных задач, только `devops` с `sudo`.

---

## 🔐 SSH-доступ

**Конфигурация:** `/etc/ssh/sshd_config`

| Параметр | Значение | Причина |
|----------|----------|---------|
| `PasswordAuthentication` | `no` | Защита от брутфорса |
| `PermitRootLogin` | `no` | Безопасность — вход под root запрещён |
| `PubkeyAuthentication` | `yes` | Используются SSH-ключи |
| `Port` | `22` | (по умолчанию, рекомендуется менять в продакшене) |

**Используемый ключ:**  
Публичный ключ пользователя `devops` добавлен в `~/.ssh/authorized_keys`.

---

## 📦 Установленные пакеты

Базовый набор:

```bash
# Системные
sudo apt update
sudo apt install -y \
    curl wget git vim htop \
    net-tools tree jq \
    apt-transport-https ca-certificates gnupg
Docker и Docker Compose:

bash
# Docker
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Docker Compose
sudo apt install -y docker-compose-plugin
Make — для управления проектом:

bash
sudo apt install -y make
📂 Структура проекта
text
/opt/spidersoft/
├── docker/             # Docker Compose и конфиги
├── scripts/            # Скрипты администрирования
├── backups/            # Резервные копии
├── app/                # Данные приложения
├── docs/               # Документация
├── logs/               # Логи системы и приложений
└── README.md
📝 Системные логи
Основные логи, которые могут пригодиться:

bash
# Логи системы
journalctl -xe

# Логи Docker-контейнеров
docker logs spidersoft-api
docker logs spidersoft-web

# Логи демонов
/var/log/syslog
/var/log/auth.log
🔄 Мониторинг состояния сервера
Используются:

Node Exporter (spidersoft-node-exporter) — для сбора метрик хоста.

cAdvisor (spidersoft-cadvisor) — для мониторинга контейнеров.

Команды для быстрой проверки:

bash
# Загрузка CPU
uptime
top -bn1 | head -5

# Свободная память
free -h

# Занятость диска
df -h

# Активные порты
sudo netstat -tlnp
🔧 Регулярные задачи (cron)
Примеры задач, которые могут быть настроены:

bash
# Ежедневный бэкап (если реализован)
0 2 * * * /opt/spidersoft/scripts/backup.sh

# Очистка старых логов (ротация)
0 0 * * * /usr/bin/journalctl --vacuum-time=7d
✅ Чек-лист готовности сервера
□ Установлена ОС Debian 13.
□ Настроен hostname spider-app-01.
□ Создан пользователь devops с sudo-доступом.
□ Отключена авторизация по паролю для SSH.
□ Docker и Docker Compose установлены.
□ Скопированы файлы проекта в /opt/spidersoft.
□ Создана сеть spidersoft-network.
□ Установлены базовые утилиты (curl, git, make, jq).
📌 Важные файлы конфигурации
Файл	Назначение
/etc/ssh/sshd_config	SSH-сервер
/opt/spidersoft/docker/.env	Переменные окружения
/opt/spidersoft/docker/docker-compose.yml	Описание сервисов
/opt/spidersoft/scripts/deploy-api.sh	Скрипт деплоя
/opt/spidersoft/app/current-version	Текущий SHA
