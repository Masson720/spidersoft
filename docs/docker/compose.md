# Docker

Docker используется в SpiderSoft Infrastructure для контейнеризации приложения и его инфраструктурных компонентов.

Основные Docker-компоненты проекта:

```text
spidersoft-web
spidersoft-api
spidersoft-db
spidersoft-prometheus
spidersoft-grafana
spidersoft-cadvisor
spidersoft-adminer
```

---

# Docker-образы

## spidersoft-api

Назначение:

```text
Flask API
```

Dockerfile:

```text
docker/api/Dockerfile
```

Registry:

```text
ghcr.io/masson720/spidersoft-api
```

Статус:

```text
Публикуется в GHCR
```

---

## spidersoft-web

Назначение:

```text
Nginx
Web server
Static content
Reverse proxy
```

Dockerfile:

```text
docker/web/Dockerfile
```

Статус:

```text
Пока используется локально.
Публикация в GHCR планируется.
```

---

# Dockerfile API

Файл:

```text
docker/api/Dockerfile
```

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

## Основные этапы

```text
FROM
    Python 3.12 slim

WORKDIR
    /app

COPY requirements.txt
    Копирование зависимостей

RUN pip install
    Установка Python-зависимостей

COPY app.py
    Копирование приложения

EXPOSE
    5000

CMD
    python app.py
```

Использование `python:3.12-slim` позволяет уменьшить размер итогового образа.

---

# Docker Layer Cache

Зависимости устанавливаются до копирования исходного кода:

```dockerfile
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
```

Это позволяет Docker использовать существующий слой с зависимостями, если `requirements.txt` не изменился.

При изменении только `app.py` зависимости не устанавливаются заново.

---

# Локальная сборка

Перейти в директорию API:

```bash
cd /opt/spidersoft/docker/api
```

Собрать образ:

```bash
docker build -t spidersoft-api:local .
```

Проверить образ:

```bash
docker images | grep spidersoft-api
```

---

# Сборка через Docker Compose

Собрать API:

```bash
docker compose build spidersoft-api
```

Пересобрать без cache:

```bash
docker compose build --no-cache spidersoft-api
```

---

# Docker Compose

Основной файл:

```text
/opt/spidersoft/docker/docker-compose.yml
```

Compose используется для запуска и управления всеми сервисами проекта.

---

# Docker Compose Profiles

В проекте используются следующие profiles:

```text
core
monitoring
tools
development
production
```

## Core

```text
web
api
db
```

Запуск:

```bash
docker compose --profile core up -d
```

---

## Monitoring

```text
prometheus
grafana
cadvisor
```

Запуск:

```bash
docker compose --profile monitoring up -d
```

---

## Tools

```text
adminer
```

Запуск:

```bash
docker compose --profile tools up -d
```

---

## Development

```text
core + tools
```

Запуск:

```bash
docker compose --profile core --profile tools up -d
```

---

## Production

```text
core + monitoring
```

Запуск:

```bash
docker compose --profile core --profile monitoring up -d
```

---

# Docker Network

Основные контейнеры работают в Docker-сети:

```text
spidersoft-network
```

Проверить сеть:

```bash
docker network inspect spidersoft-network
```

Контейнеры могут обращаться друг к другу по Docker DNS-именам.

Например, API подключается к PostgreSQL:

```text
DB_HOST=spidersoft-db
DB_PORT=5432
```

Grafana подключается к Prometheus:

```text
http://spidersoft-prometheus:9090
```

---

# Docker Volumes

Для постоянного хранения данных используются volumes:

```text
spidersoft-web-data
spidersoft-db-data
spidersoft-prometheus-data
spidersoft-grafana-data
```

## Назначение

```text
spidersoft-web-data
    Статика Web

spidersoft-db-data
    Данные PostgreSQL

spidersoft-prometheus-data
    Данные Prometheus

spidersoft-grafana-data
    Данные и настройки Grafana
```

Посмотреть volumes:

```bash
docker volume ls | grep spidersoft
```

Удаление volume PostgreSQL приведёт к потере данных:

```bash
docker volume rm spidersoft-db-data
```

Использовать только если данные больше не нужны или существует backup.

---

# Docker Images

Посмотреть все образы:

```bash
docker images
```

Только SpiderSoft:

```bash
docker images | grep spidersoft
```

---

# Docker Containers

Запущенные контейнеры:

```bash
docker ps
```

Все контейнеры:

```bash
docker ps -a
```

---

# Container Logs

Посмотреть логи:

```bash
docker logs <container>
```

Следить за логами:

```bash
docker logs -f <container>
```

Например:

```bash
docker logs -f spidersoft-api
```

---

# Container Inspect

Получить подробную информацию:

```bash
docker inspect <container>
```

Для image:

```bash
docker inspect spidersoft-api:local
```

---

# Docker Registry

Для API используется:

```text
GitHub Container Registry
```

Image:

```text
ghcr.io/masson720/spidersoft-api
```

Получить image:

```bash
docker pull ghcr.io/masson720/spidersoft-api:latest
```

Добавить registry tag:

```bash
docker tag spidersoft-api:local \
    ghcr.io/masson720/spidersoft-api:latest
```

Опубликовать:

```bash
docker push \
    ghcr.io/masson720/spidersoft-api:latest
```

---

# Теги Docker-образов

Используются следующие типы тегов:

```text
<SHA>
main
latest
v1.0.0
```

## SHA

Пример:

```text
spidersoft-api:a1b2c3d4
```

Используется для точной идентификации конкретной версии образа.

SHA-тег должен оставаться immutable.

---

## main

```text
spidersoft-api:main
```

Последняя сборка из основной ветки.

---

## latest

```text
spidersoft-api:latest
```

Указатель на последнюю стабильную версию.

Удобен для разработки и staging.

---

## Version

Например:

```text
spidersoft-api:v1.0.0
```

Используется для версий приложения.

---

# Dockerfile Web

Файл:

```text
docker/web/Dockerfile
```

Образ используется для:

```text
Nginx
Static content
Reverse proxy
```

Конфигурация Nginx:

```text
docker/web/nginx/default.conf
```

Web-контейнер работает на:

```text
8080
```

---

# Основные команды проекта

Перейти в Docker-директорию:

```bash
cd /opt/spidersoft/docker
```

Запустить development:

```bash
make dev
```

Запустить production:

```bash
make prod
```

Запустить всё:

```bash
make all
```

Остановить:

```bash
make down
```

Проверить статус:

```bash
make status
```

Посмотреть логи:

```bash
make logs
```

Пересобрать:

```bash
make rebuild
```

Полностью очистить Docker-инфраструктуру:

```bash
make clean
```

---

# Проверка Docker

Версия Docker:

```bash
docker --version
```

Версия Compose:

```bash
docker compose version
```

Проверить работающие контейнеры:

```bash
docker ps
```

Проверить Docker network:

```bash
docker network ls
```

Проверить volumes:

```bash
docker volume ls
```

---

# Docker Architecture

```text
                         Browser
                            │
                            ▼
                  ┌───────────────────┐
                  │ spidersoft-web    │
                  │      Nginx        │
                  │      :8080        │
                  └─────────┬─────────┘
                            │
                    ┌───────┴───────┐
                    │               │
                    ▼               ▼
             Static content   spidersoft-api
                                  :5000
                                    │
                                    ▼
                              spidersoft-db
                                  :5432


             ┌─────────────────────────────┐
             │        Monitoring           │
             │                             │
             │ cAdvisor → Prometheus      │
             │                  │          │
             │                  ▼          │
             │               Grafana       │
             └─────────────────────────────┘

             spidersoft-network
                       │
       ┌───────────────┼────────────────┐
       │               │                │
       ▼               ▼                ▼
      Web              API              DB
       │               │
       │               └──────► Prometheus
       │
       └──────► Static content
```

---

# Docker Principles

В проекте используются следующие принципы:

```text
1. Контейнеризация сервисов
2. Docker Compose для управления инфраструктурой
3. Profiles для разных окружений
4. Docker volumes для persistent data
5. Отдельная Docker network
6. Минимальные base images
7. Layer caching
8. Immutable SHA tags
9. GHCR как Container Registry
10. Разделение application и infrastructure containers
```

---

# План развития Docker-инфраструктуры

В дальнейшем планируется:

- Сканирование Docker images на уязвимости. 

- Подпись Docker images. 

- Улучшение Dockerfile. 

- Оптимизация размера images. 

- Расширение health checks. 

- Улучшение Docker Compose production-конфигурации.

---

# SpiderSoft Docker

```text
============================================================
                 🕷 SPIDERSOFT DOCKER 🕷
============================================================

Runtime
    Docker CE

Orchestration
    Docker Compose V2

Network
    spidersoft-network

Images
    spidersoft-api
    spidersoft-web

Registry
    ghcr.io/masson720/spidersoft-api

Profiles
    core
    monitoring
    tools
    development
    production

Persistent data
    Docker volumes

============================================================
```
