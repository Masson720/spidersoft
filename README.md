============================================================
                 🕷 SPIDERSOFT INFRASTRUCTURE 🕷
============================================================

Учебный Junior DevOps-проект инфраструктуры небольшой компании
SpiderSoft.

Проект построен на Docker и Docker Compose и включает:

    Nginx
    Flask / Python 3.12
    PostgreSQL 16
    Prometheus
    Grafana
    cAdvisor
    Adminer
    GitHub Actions
    GitHub Container Registry

============================================================
                    🚀 БЫСТРЫЙ СТАРТ
============================================================

Перейти в Docker-директорию:

    cd /opt/spidersoft/docker


Запустить Production:

    make prod


Запустить Development:

    make dev


Проверить состояние:

    make status


Посмотреть логи:

    make logs


Остановить сервисы:

    make down


Пересобрать:

    make rebuild


Показать доступные команды:

    make help


============================================================
                    🌐 ДОСТУП К СЕРВИСАМ
============================================================

Web:

    http://localhost:8080


API:

    http://localhost:8080/api


Adminer:

    http://localhost:8081


cAdvisor:

    http://localhost:8082


Prometheus:

    http://localhost:9090


Grafana:

    http://localhost:3000

    Login:    admin
    Password: admin


============================================================
                    🐳 DOCKER PROFILES
============================================================

core:

    web
    api
    db


monitoring:

    prometheus
    grafana
    cadvisor


tools:

    adminer


development:

    core + tools


production:

    core + monitoring


Запуск Core:

    docker compose --profile core up -d


Запуск Monitoring:

    docker compose --profile monitoring up -d


Запуск Tools:

    docker compose --profile tools up -d


Запуск Development:

    docker compose --profile core --profile tools up -d


Запуск Production:

    docker compose --profile core --profile monitoring up -d


============================================================
                    📁 СТРУКТУРА ПРОЕКТА
============================================================

    /opt/spidersoft/
    │
    ├── docker/
    │   ├── api/
    │   ├── web/
    │   ├── prometheus/
    │   ├── scripts/
    │   ├── docker-compose.yml
    │   ├── Makefile
    │   └── .env
    │
    ├── app/
    ├── backups/
    ├── docs/
    ├── logs/
    ├── monitoring/
    ├── scripts/
    │
    └── README.md


============================================================
                    📚 ДОКУМЕНТАЦИЯ
============================================================

Подробная документация находится в:

    /opt/spidersoft/docs/


Основные документы:

    server.md

        Серверная инфраструктура и системная настройка.


    profiles.md

        Docker Compose Profiles.


    docker.md

        Docker-инфраструктура проекта.


    docker-build.md

        Сборка и публикация Docker-образов.


============================================================
                    🔐 ENVIRONMENT
============================================================

Файл:

    /opt/spidersoft/docker/.env


Основные переменные:

    APP_NAME
    APP_VERSION
    APP_ENV

    POSTGRES_DB
    POSTGRES_USER
    POSTGRES_PASSWORD

    DB_HOST
    DB_PORT
    DB_NAME
    DB_USER
    DB_PASSWORD


ВНИМАНИЕ:

    Не хранить реальные credentials в Git.


============================================================
                    📊 MONITORING
============================================================

Prometheus собирает метрики с:

    spidersoft-api
    cAdvisor
    Prometheus


Основные PromQL-запросы:

    up


    container_memory_usage_bytes


    container_cpu_usage_seconds_total


    spidersoft_api_requests_total


    rate(spidersoft_api_requests_total[5m])


    spidersoft_api_requests_total{status=~"5.."}


    spidersoft_api_db_errors_total


Grafana использует Prometheus:

    http://spidersoft-prometheus:9090


============================================================
                    🔌 API ENDPOINTS
============================================================

    GET  /          Информация о сервисе

    GET  /health    Проверка здоровья

    GET  /version   Версия приложения

    GET  /db-info   Версия PostgreSQL

    GET  /metrics   Метрики Prometheus

    GET  /slow      Тестовый endpoint


API внутри Docker-сети:

    spidersoft-api:5000


============================================================
                    🔄 CI/CD
============================================================

Каждый push в ветку:

    main


запускает GitHub Actions.


Pipeline:

    Git push
       │
       ▼
    Test
       │
       ▼
    Docker Build
       │
       ▼
    GHCR


Docker image API:

    ghcr.io/masson720/spidersoft-api


Основные теги:

    <SHA>
    main
    latest
    vX.Y.Z


Для Production рекомендуется использовать
конкретный SHA.


============================================================
                    💾 DOCKER VOLUMES
============================================================

    spidersoft-web-data

        Статика Web.


    spidersoft-db-data

        Данные PostgreSQL.


    spidersoft-prometheus-data

        Данные Prometheus.


    spidersoft-grafana-data

        Данные и настройки Grafana.


ВНИМАНИЕ:

    Удаление Docker volumes может привести
    к потере данных.


============================================================
                    🐳 DOCKER NETWORK
============================================================

Основная сеть:

    spidersoft-network


Основные контейнеры:

    spidersoft-web
    spidersoft-api
    spidersoft-db
    spidersoft-prometheus
    spidersoft-grafana
    spidersoft-cadvisor
    spidersoft-adminer


Контейнеры взаимодействуют друг с другом
через Docker DNS.


Примеры:

    spidersoft-db:5432

    spidersoft-api:5000

    spidersoft-prometheus:9090


============================================================
                    🛠 ОСНОВНЫЕ КОМАНДЫ
============================================================

Запуск:

    make dev
    make prod
    make core
    make monitoring
    make tools
    make all


Управление:

    make status
    make logs
    make down
    make rebuild
    make clean


Справка:

    make help


============================================================
                    📌 ТЕКУЩИЙ СТАТУС
============================================================

    OS:

        Debian 13


    Container Runtime:

        Docker CE


    Orchestration:

        Docker Compose V2


    Web:

        Nginx


    API:

        Flask / Python 3.12


    Database:

        PostgreSQL 16


    Monitoring:

        Prometheus
        Grafana
        cAdvisor


    Database UI:

        Adminer


    CI/CD:

        GitHub Actions


    Container Registry:

        GitHub Container Registry


    Git:

        main


============================================================
                    🕷 SPIDERSOFT
============================================================

    Infrastructure as Code
    Containerization
    Monitoring
    CI/CD
    Linux
    Docker

============================================================
