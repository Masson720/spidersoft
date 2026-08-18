# SpiderSoft Infrastructure

## Описание

Учебный проект уровня Junior DevOps, имитирующий инфраструктуру небольшой компании SpiderSoft.

Проект развивается итеративно, каждый новый компонент добавляется на основе уже существующей инфраструктуры.

---

## Быстрый старт

```bash
cd /opt/spidersoft/docker

# Разработка (core + tools)
make dev

# Production (core + monitoring)
make prod

# Все сервисы
make all

# Остановка
make down

# Статус
make status
Архитектура
text
                   Browser
                      │
                      ▼
              spidersoft-web (nginx:8080)
                      │
          ┌───────────┴────────────┐
          ▼                        ▼
  static content          spidersoft-api (Flask:5000)
                                    │
                                    ▼
                             spidersoft-db (PostgreSQL)

    cAdvisor ──────► Prometheus ◄────── Grafana
                           │
                           ▼
                   API Metrics (/metrics)
Сервисы
Core (ядро)
spidersoft-web — веб-сервер (nginx), порт 8080

spidersoft-api — Flask API, порт 5000 (внутренний)

spidersoft-db — PostgreSQL, порт 5432 (внутренний)

Monitoring (мониторинг)
spidersoft-prometheus — сбор и хранение метрик, порт 9090

spidersoft-grafana — визуализация метрик, порт 3000

spidersoft-cadvisor — мониторинг контейнеров, порт 8082

Tools (инструменты)
spidersoft-adminer — UI для PostgreSQL, порт 8081

Docker Compose Profiles
Профиль	Сервисы	Назначение
core	web, api, db	Основа приложения
monitoring	prometheus, grafana, cadvisor	Мониторинг
tools	adminer	Инструменты разработки
development	core + tools	Локальная разработка
production	core + monitoring	Production окружение
Команды с профилями
bash
# Только ядро
docker compose --profile core up -d

# Только мониторинг
docker compose --profile monitoring up -d

# Разработка
docker compose --profile core --profile tools up -d

# Production
docker compose --profile core --profile monitoring up -d
Volumes
Volume	Назначение
spidersoft-web-data	Статика веб-сервера
spidersoft-db-data	Данные PostgreSQL
spidersoft-prometheus-data	Данные Prometheus
spidersoft-grafana-data	Настройки и дашборды Grafana
Мониторинг
Prometheus
URL: http://localhost:9090

Собирает метрики с cAdvisor, API и самого себя

Хранение данных: 30 дней

Grafana
URL: http://localhost:3000

Логин: admin

Пароль: admin

Подключение Prometheus в Grafana
Открыть http://localhost:3000

Войти: admin / admin

Connections → Data Sources → Add data source

Выбрать Prometheus

URL: http://spidersoft-prometheus:9090

Save & Test → "Data source is working"

Полезные запросы в Explore
text
# Статус всех сервисов
up

# Использование памяти контейнерами
container_memory_usage_bytes

# Использование CPU
container_cpu_usage_seconds_total

# Количество запросов к API
spidersoft_api_requests_total

# RPS (запросов в секунду)
rate(spidersoft_api_requests_total[5m])

# Ошибки API (статус 5xx)
spidersoft_api_requests_total{status=~"5.."}

# Ошибки базы данных
spidersoft_api_db_errors_total
API Endpoints
Endpoint	Метод	Описание
/	GET	Информация о сервисе
/health	GET	Проверка здоровья (БД)
/version	GET	Версия приложения
/db-info	GET	Версия PostgreSQL
/metrics	GET	Метрики для Prometheus
/slow	GET	Тестовый эндпоинт (3 сек задержки)
Пример ответа
json
// GET /
{
    "service": "spidersoft-api",
    "version": "1.0.0",
    "environment": "production",
    "timestamp": "2026-08-04T10:30:00",
    "hostname": "spidersoft-api"
}

// GET /health
{
    "status": "healthy",
    "database": "connected",
    "timestamp": "2026-08-04T10:30:00"
}
Переменные окружения (.env)
Файл: /opt/spidersoft/docker/.env

bash
# Application
APP_NAME=spidersoft-api
APP_VERSION=1.0.0
APP_ENV=development

# Database
POSTGRES_DB=spidersoft
POSTGRES_USER=spidersoft
POSTGRES_PASSWORD=spidersoft_password

DB_HOST=spidersoft-db
DB_PORT=5432
DB_NAME=spidersoft
DB_USER=spidersoft
DB_PASSWORD=spidersoft_password
Make команды
Команда	Описание
make help	Показать все команды
make dev	Запуск разработки (core + tools)
make prod	Запуск production (core + monitoring)
make core	Только ядро
make monitoring	Только мониторинг
make tools	Только инструменты
make all	Все сервисы
make down	Остановка всех сервисов
make status	Статус контейнеров
make logs	Логи всех сервисов
make clean	Полная очистка (удаление данных)
make rebuild	Пересборка и перезапуск
Структура проекта
text
/opt/spidersoft/
├── docker/
│   ├── api/
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── web/
│   │   ├── Dockerfile
│   │   ├── index.html
│   │   └── nginx/
│   │       └── default.conf
│   ├── prometheus/
│   │   └── prometheus.yml
│   ├── scripts/
│   │   ├── start.sh
│   │   └── force-clean.sh
│   ├── docker-compose.yml
│   ├── Makefile
│   └── .env
├── app/
├── backups/
├── docs/
│   ├── changes.md
│   ├── server.md
│   └── profiles.md
├── logs/
├── monitoring/
├── scripts/
│   ├── backup.sh
│   ├── log_message.sh
│   └── server-info.sh
└── README.md
Доступные сервисы
Web: http://localhost:8080

API: http://localhost:8080/api

Adminer (DB UI): http://localhost:8081

cAdvisor: http://localhost:8082

Prometheus: http://localhost:9090

Grafana: http://localhost:3000 (admin/admin)

Установка зависимостей
bash
# Debian/Ubuntu
sudo apt update
sudo apt install -y make docker.io docker-compose-plugin

# Добавить пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker
Устранение неполадок
Контейнеры не останавливаются
bash
make force-clean
Ошибка "port already in use"
bash
# Проверить занятые порты
sudo netstat -tlnp | grep -E ":(8080|8081|8082|9090|3000)"

# Остановить все
make down
Grafana не видит Prometheus
Проверить, что Prometheus запущен: make status

Проверить URL в Grafana: http://spidersoft-prometheus:9090

Проверить сеть: docker network inspect spidersoft-network

Volumes конфликтуют
bash
# Посмотреть существующие volumes
docker volume ls | grep spidersoft

# Удалить (если данные не нужны)
docker volume rm spidersoft-web-data spidersoft-db-data spidersoft-prometheus-data spidersoft-grafana-data

## CI/CD

### Что такое CI?

**CI (Continuous Integration)** — это практика автоматической проверки кода при каждом изменении. В этом проекте CI настроен через **GitHub Actions**.

При каждом `git push` в ветку `master` автоматически запускается пайплайн, который:

1. Проверяет, что Python-приложение импортируется без ошибок.
2. Устанавливает зависимости из `requirements.txt`.
3. Собирает Docker-образ API.

Если хотя бы один шаг завершается с ошибкой — пайплайн останавливается, и разработчик видит проблему сразу, до того как код попадёт в production.

---

### Что такое CD?

**CD (Continuous Delivery)** — это практика автоматической доставки кода после успешной проверки. В нашем случае CD заключается в сборке Docker-образа с уникальным тегом.

Образ собирается **только если** тесты прошли успешно. Это гарантирует, что в реестр образов не попадёт сломанный код.

---

### Зачем нужен GitHub Actions?

**GitHub Actions** — это встроенный инструмент автоматизации на GitHub. Он позволяет выполнять любые задачи в ответ на события репозитория (push, pull request, schedule и др.).

В этом проекте GitHub Actions используется для:

- изолированного запуска проверок (на чистом Ubuntu-окружении);
- автоматической сборки Docker-образа;
- предотвращения попадания сломанного кода в основную ветку.

---

### Что происходит после `git push`?

git push origin master
│
▼
GitHub получает новый код
│
▼
GitHub Actions запускает workflow (CI Pipeline)
│
▼
Job "test"
├── Устанавливает Python 3.12
├── Устанавливает зависимости из requirements.txt
└── Проверяет, что модуль app.py импортируется без ошибок
│
▼ (если успешно)
Job "docker-build"
├── Клонирует код
├── Настраивает Docker Buildx
└── Собирает образ spidersoft-api:<commit-sha>
│
▼
Workflow завершён ✅

Если тесты упали — сборка Docker-образа не начинается, и workflow завершается с ошибкой.

---

### Почему Docker image должен иметь уникальный тег?

В пайплайне используется тег:

```bash
spidersoft-api:${{ github.sha }}

где ${{ github.sha }} — это SHA-хэш коммита (уникальный идентификатор).





Статус проекта
Компонент	Версия
Debian		13
Docker		CE
Docker Compose	V2
nginx		Latest
Python/Flask	3.12
PostgreSQL	16
Prometheus	Latest
Grafana		Latest
cAdvisor	Latest
Adminer		Latest
