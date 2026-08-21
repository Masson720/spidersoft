# SpiderSoft Infrastructure

Учебный DevOps-проект, имитирующий инфраструктуру небольшой компании **SpiderSoft**.

Проект развивается итеративно: каждый новый компонент добавляется на основе уже существующей инфраструктуры и интегрируется с остальными сервисами.

---

# Описание проекта

**SpiderSoft Infrastructure** — учебная инфраструктура уровня Junior DevOps, построенная на Debian, Docker и Docker Compose.

Проект включает:

* Linux-сервер на Debian 13;
* Docker CE;
* Docker Compose V2;
* Nginx;
* Flask API;
* PostgreSQL;
* Prometheus;
* Grafana;
* cAdvisor;
* Adminer;
* Docker Compose Profiles;
* Makefile для управления инфраструктурой;
* Git;
* GitHub Actions;
* CI/CD;
* мониторинг;
* логирование;
* резервное копирование.

Основная задача проекта — практически отработать навыки системного администрирования, контейнеризации, сетевого взаимодействия, мониторинга и автоматизации.

---

# Архитектура

Основное приложение построено по следующей схеме:

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
                 ┌──────────┴──────────┐
                 │                     │
                 ▼                     ▼
          Static content       spidersoft-api
                                  Flask :5000
                                      │
                                      ▼
                              spidersoft-db
                              PostgreSQL :5432


          ┌─────────────────────────────────────┐
          │             Monitoring              │
          │                                     │
          │  cAdvisor ──────► Prometheus       │
          │                       │             │
          │                       ▼             │
          │                    Grafana           │
          │                                     │
          │  API ─────────────► /metrics        │
          └─────────────────────────────────────┘
```

## Основной поток запросов

```text
Browser
   │
   ▼
Nginx :8080
   │
   ├──────────────► Static content
   │
   ▼
Flask API :5000
   │
   ▼
PostgreSQL :5432
```

## Поток мониторинга

```text
Docker containers
       │
       ▼
   cAdvisor
       │
       ▼
   Prometheus
       │
       ▼
    Grafana
```

API предоставляет endpoint `/metrics`, из которого Prometheus получает собственные прикладные метрики приложения.

---

# Сервисы

## Core

Основное ядро приложения:

```text
spidersoft-web
```

Nginx.

Порт:

```text
8080
```

Назначение:

* веб-сервер;
* отдача статического контента;
* reverse proxy;
* проксирование запросов к API.

---

```text
spidersoft-api
```

Flask API.

Порт:

```text
5000
```

Порт используется внутри Docker-сети.

Назначение:

* backend приложения;
* работа с PostgreSQL;
* health checks;
* выдача информации о версии;
* предоставление API metrics;
* тестовый endpoint с задержкой.

---

```text
spidersoft-db
```

PostgreSQL.

Порт:

```text
5432
```

Порт используется внутри Docker-сети.

Назначение:

* хранение данных приложения;
* предоставление PostgreSQL для Flask API.

---

# Monitoring

## spidersoft-prometheus

Prometheus.

Порт:

```text
9090
```

Назначение:

* сбор метрик;
* хранение метрик;
* выполнение PromQL-запросов;
* мониторинг API;
* мониторинг cAdvisor;
* мониторинг самого Prometheus.

Срок хранения данных:

```text
30 дней
```

---

## spidersoft-grafana

Grafana.

Порт:

```text
3000
```

Назначение:

* визуализация метрик;
* создание dashboard;
* построение графиков;
* анализ состояния инфраструктуры.

Учебные credentials:

```text
Login:    admin
Password: admin
```

Для production-окружения пароль необходимо изменить.

---

## spidersoft-cadvisor

cAdvisor.

Порт:

```text
8082
```

Назначение:

* мониторинг Docker-контейнеров;
* сбор CPU metrics;
* сбор memory metrics;
* сбор container-level metrics.

cAdvisor передаёт метрики в Prometheus.

---

# Tools

## spidersoft-adminer

Adminer.

Порт:

```text
8081
```

Назначение:

* Web UI для PostgreSQL;
* просмотр базы данных;
* выполнение SQL-запросов;
* администрирование базы данных.

---

# Docker Compose Profiles

Для управления различными окружениями используются Docker Compose Profiles.

## Доступные профили

```text
core
```

Сервисы:

```text
web
api
db
```

Назначение:

```text
Основа приложения
```

---

```text
monitoring
```

Сервисы:

```text
prometheus
grafana
cadvisor
```

Назначение:

```text
Мониторинг инфраструктуры
```

---

```text
tools
```

Сервис:

```text
adminer
```

Назначение:

```text
Инструменты разработки и администрирования
```

---

```text
development
```

Состав:

```text
core + tools
```

Назначение:

```text
Локальная разработка
```

---

```text
production
```

Состав:

```text
core + monitoring
```

Назначение:

```text
Production-окружение
```

---

# Запуск Docker Compose Profiles

## Только ядро

```bash
docker compose --profile core up -d
```

---

## Только мониторинг

```bash
docker compose --profile monitoring up -d
```

---

## Development

```bash
docker compose --profile core --profile tools up -d
```

---

## Production

```bash
docker compose --profile core --profile monitoring up -d
```

---

# Быстрый старт

Перейти в директорию Docker-инфраструктуры:

```bash
cd /opt/spidersoft/docker
```

## Development

Запуск:

```bash
make dev
```

Запускает:

```text
core + tools
```

То есть:

```text
web
api
db
adminer
```

---

## Production

Запуск:

```bash
make prod
```

Запускает:

```text
core + monitoring
```

То есть:

```text
web
api
db
prometheus
grafana
cadvisor
```

---

## Все сервисы

```bash
make all
```

Запускает все доступные сервисы.

---

## Остановка

```bash
make down
```

Останавливает инфраструктуру.

---

## Статус

```bash
make status
```

Показывает состояние контейнеров.

---

# Makefile

Доступные команды:

```text
make help
```

Показать все доступные команды.

---

```text
make dev
```

Запуск development-окружения:

```text
core + tools
```

---

```text
make prod
```

Запуск production-окружения:

```text
core + monitoring
```

---

```text
make core
```

Запуск только core-сервисов.

---

```text
make monitoring
```

Запуск только monitoring-сервисов.

---

```text
make tools
```

Запуск инструментов.

---

```text
make all
```

Запуск всех сервисов.

---

```text
make down
```

Остановка всех сервисов.

---

```text
make status
```

Просмотр статуса контейнеров.

---

```text
make logs
```

Просмотр логов всех сервисов.

---

```text
make clean
```

Полная очистка инфраструктуры с удалением данных.

Использовать осторожно.

---

```text
make rebuild
```

Пересборка и перезапуск сервисов.

---

# Volumes

Для постоянного хранения данных используются Docker volumes.

## spidersoft-web-data

Назначение:

```text
Статика веб-сервера
```

---

## spidersoft-db-data

Назначение:

```text
Данные PostgreSQL
```

Важно:

```text
Удаление volume приведёт к потере данных PostgreSQL.
```

---

## spidersoft-prometheus-data

Назначение:

```text
Данные Prometheus
```

---

## spidersoft-grafana-data

Назначение:

```text
Настройки и dashboards Grafana
```

---

# Доступные сервисы

## Web

```text
http://localhost:8080
```

---

## API

```text
http://localhost:8080/api
```

---

## Adminer

```text
http://localhost:8081
```

---

## cAdvisor

```text
http://localhost:8082
```

---

## Prometheus

```text
http://localhost:9090
```

---

## Grafana

```text
http://localhost:3000
```

Credentials:

```text
Login:    admin
Password: admin
```

---

# API

Backend приложения реализован на:

```text
Python 3.12
Flask
```

API предоставляет следующие endpoints:

```text
/
```

Метод:

```text
GET
```

Назначение:

```text
Информация о сервисе
```

---

```text
/health
```

Метод:

```text
GET
```

Назначение:

```text
Проверка здоровья приложения и подключения к базе данных
```

---

```text
/version
```

Метод:

```text
GET
```

Назначение:

```text
Получение версии приложения
```

---

```text
/db-info
```

Метод:

```text
GET
```

Назначение:

```text
Получение версии PostgreSQL
```

---

```text
/metrics
```

Метод:

```text
GET
```

Назначение:

```text
Метрики для Prometheus
```

---

```text
/slow
```

Метод:

```text
GET
```

Назначение:

```text
Тестовый endpoint с задержкой 3 секунды
```

Используется для тестирования мониторинга, latency и поведения API при медленных запросах.

---

# API — пример ответа /

Запрос:

```text
GET /
```

Ответ:

```json
{
    "service": "spidersoft-api",
    "version": "1.0.0",
    "environment": "production",
    "timestamp": "2026-08-04T10:30:00",
    "hostname": "spidersoft-api"
}
```

---

# API — пример ответа /health

Запрос:

```text
GET /health
```

Ответ:

```json
{
    "status": "healthy",
    "database": "connected",
    "timestamp": "2026-08-04T10:30:00"
}
```

Endpoint `/health` используется для проверки:

```text
API
 │
 └──► PostgreSQL
```

Если приложение может подключиться к базе данных, health check сообщает:

```text
database: connected
```

---

# Мониторинг

Monitoring stack построен на следующих компонентах:

```text
cAdvisor
    │
    ▼
Prometheus
    │
    ▼
Grafana
```

Одновременно API предоставляет:

```text
/metrics
```

который используется Prometheus для получения application-level metrics.

---

# Prometheus

URL:

```text
http://localhost:9090
```

Prometheus собирает метрики:

```text
Prometheus
cAdvisor
Flask API
```

Хранение метрик:

```text
30 дней
```

---

# Grafana

URL:

```text
http://localhost:3000
```

Credentials:

```text
Login:    admin
Password: admin
```

---

# Подключение Prometheus к Grafana

Открыть:

```text
http://localhost:3000
```

Войти:

```text
admin / admin
```

Перейти:

```text
Connections
    │
    ▼
Data Sources
    │
    ▼
Add data source
```

Выбрать:

```text
Prometheus
```

URL Prometheus внутри Docker-сети:

```text
http://spidersoft-prometheus:9090
```

Нажать:

```text
Save & Test
```

Ожидаемый результат:

```text
Data source is working
```

---

# PromQL

## Статус всех сервисов

```promql
up
```

Показывает состояние targets, которые опрашивает Prometheus.

---

## Использование памяти контейнерами

```promql
container_memory_usage_bytes
```

Показывает использование памяти Docker-контейнерами.

---

## Использование CPU

```promql
container_cpu_usage_seconds_total
```

Показывает накопленное CPU time контейнеров.

---

## Количество запросов к API

```promql
spidersoft_api_requests_total
```

Показывает количество обработанных API-запросов.

---

## Requests per second

```promql
rate(spidersoft_api_requests_total[5m])
```

Показывает приблизительное количество запросов в секунду за последние 5 минут.

---

## Ошибки API

Запрос для HTTP 5xx:

```promql
spidersoft_api_requests_total{status=~"5.."}
```

Позволяет отслеживать серверные ошибки API.

---

## Ошибки базы данных

```promql
spidersoft_api_db_errors_total
```

Показывает количество ошибок, связанных с базой данных.

---

# Переменные окружения

Файл:

```text
/opt/spidersoft/docker/.env
```

Содержимое:

```dotenv
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
```

## Application

```text
APP_NAME
```

Имя приложения:

```text
spidersoft-api
```

---

```text
APP_VERSION
```

Версия приложения:

```text
1.0.0
```

---

```text
APP_ENV
```

Окружение:

```text
development
```

---

# Database

## POSTGRES_DB

Имя базы данных:

```text
spidersoft
```

---

## POSTGRES_USER

Пользователь PostgreSQL:

```text
spidersoft
```

---

## POSTGRES_PASSWORD

Пароль PostgreSQL:

```text
spidersoft_password
```

---

# Application → Database

## DB_HOST

Hostname PostgreSQL-контейнера:

```text
spidersoft-db
```

---

## DB_PORT

Порт PostgreSQL:

```text
5432
```

---

## DB_NAME

Имя базы данных:

```text
spidersoft
```

---

## DB_USER

Пользователь:

```text
spidersoft
```

---

## DB_PASSWORD

Пароль:

```text
spidersoft_password
```

> В учебном проекте значения находятся в `.env`. Для production-среды реальные секреты не следует хранить непосредственно в Git-репозитории.

---

# Структура проекта

Полная структура:

```text
/opt/spidersoft/
│
├── docker/
│   │
│   ├── api/
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   │
│   ├── web/
│   │   ├── Dockerfile
│   │   ├── index.html
│   │   └── nginx/
│   │       └── default.conf
│   │
│   ├── prometheus/
│   │   └── prometheus.yml
│   │
│   ├── scripts/
│   │   ├── start.sh
│   │   └── force-clean.sh
│   │
│   ├── docker-compose.yml
│   ├── Makefile
│   └── .env
│
├── app/
│
├── backups/
│
├── docs/
│   ├── changes.md
│   ├── profiles.md
│   └── server.md
│
├── logs/
│
├── monitoring/
│
├── scripts/
│   ├── backup.sh
│   ├── log_message.sh
│   └── server-info.sh
│
└── README.md
```

---

# CI/CD

Проект использует **GitHub Actions** для автоматизации CI/CD.

---

# CI — Continuous Integration

**Continuous Integration (CI)** — практика автоматической проверки кода при каждом изменении.

В этом проекте CI настроен через:

```text
GitHub Actions
```

При каждом:

```bash
git push
```

в ветку:

```text
main
```

автоматически запускается pipeline.

---

# Что делает CI

Pipeline выполняет следующие действия:

```text
1. Запускает Ubuntu environment
2. Устанавливает Python 3.12
3. Устанавливает зависимости
4. Проверяет импорт приложения
5. Собирает Docker image API
```

Если хотя бы один шаг завершается с ошибкой:

```text
pipeline STOP
```

Docker image не собирается.

Это позволяет обнаруживать проблемы до попадания кода в production.

---

# CD — Continuous Delivery

**Continuous Delivery (CD)** — практика автоматической подготовки к доставке проверенного кода.

В этом проекте CD заключается в сборке Docker image с уникальным тегом.

Docker image создаётся только после успешного прохождения CI.

Используется тег:

```text
spidersoft-api:<commit-sha>
```

---

# Почему используется уникальный Docker tag

В pipeline используется:

```text
${{ github.sha }}
```

`github.sha` — уникальный SHA-хэш конкретного Git-коммита.

В результате Docker image получает вид:

```text
spidersoft-api:8f4a1c...
```

Это позволяет точно определить:

```text
какой commit
        │
        ▼
какому Docker image
        │
        ▼
соответствует
```

Таким образом, разные версии приложения не перезаписывают друг друга.

---

# Что происходит после git push

```text
git push origin main
        │
        ▼
GitHub получает новый commit
        │
        ▼
GitHub Actions запускает workflow
        │
        ▼
       test
        │
        ├── Python 3.12
        │
        ├── requirements.txt
        │
        └── import app.py
        │
        ▼
   Tests passed
        │
        ▼
   docker-build
        │
        ├── Docker Buildx
        │
        └── spidersoft-api:<commit-sha>
        │
        ▼
    Workflow complete
```

Если тесты завершились ошибкой:

```text
test
 │
 ▼
FAILED
 │
 ▼
docker-build НЕ запускается
```

---

# Git

Основная ветка проекта:

```text
main
```

Ветка `master` больше не используется.

---

# Проверка текущей ветки

```bash
git branch
```

---

# Переключение на main

```bash
git switch main
```

---

# Получение изменений

```bash
git pull origin main
```

---

# Отправка изменений

```bash
git push origin main
```

---

# Проверка remote

```bash
git remote -v
```

---

# Переименование master в main

Если локальная ветка всё ещё называется `master`:

```bash
git branch -m master main
```

Отправить новую ветку:

```bash
git push -u origin main
```

После этого на GitHub необходимо установить:

```text
main
```

как Default branch.

Только после смены Default branch можно удалить старую ветку:

```bash
git push origin --delete master
```

---

# GitHub Actions и main

Workflow должен запускаться для ветки:

```yaml
on:
  push:
    branches:
      - main
```

Для Pull Request:

```yaml
on:
  pull_request:
    branches:
      - main
```

Если в `.github/workflows/` остались ссылки на `master`, их необходимо заменить на `main`.

---

# Установка зависимостей

Для Debian/Ubuntu:

```bash
sudo apt update
sudo apt install -y make docker.io docker-compose-plugin
```

---

# Docker group

Чтобы запускать Docker без `sudo`, добавить пользователя в группу:

```bash
sudo usermod -aG docker $USER
```

Применить изменение:

```bash
newgrp docker
```

Проверить Docker:

```bash
docker --version
```

Проверить Docker Compose:

```bash
docker compose version
```

---

# Устранение неполадок

## Контейнеры не останавливаются

Остановить инфраструктуру:

```bash
make down
```

Если контейнеры не останавливаются штатно:

```bash
make force-clean
```

---

# Ошибка "port already in use"

Проверить занятые порты:

```bash
sudo netstat -tlnp | grep -E ":(8080|8081|8082|9090|3000)"
```

Или:

```bash
sudo ss -tlnp | grep -E ':(8080|8081|8082|9090|3000)'
```

После этого:

```bash
make down
```

---

# Grafana не видит Prometheus

Проверить состояние контейнеров:

```bash
make status
```

Проверить Docker network:

```bash
docker network inspect spidersoft-network
```

URL Prometheus внутри Docker-сети:

```text
http://spidersoft-prometheus:9090
```

Важно:

```text
http://localhost:9090
```

используется для доступа к Prometheus с хоста.

А:

```text
http://spidersoft-prometheus:9090
```

используется для обращения к Prometheus из другого контейнера в Docker network.

---

# Volumes конфликтуют

Посмотреть существующие volumes:

```bash
docker volume ls | grep spidersoft
```

Если данные больше не нужны, удалить volumes:

```bash
docker volume rm \
  spidersoft-web-data \
  spidersoft-db-data \
  spidersoft-prometheus-data \
  spidersoft-grafana-data
```

> Удаление `spidersoft-db-data` удалит данные PostgreSQL.

---

# Полная очистка

Для полной очистки используется:

```bash
make clean
```

или при необходимости:

```bash
make force-clean
```

Перед очисткой необходимо убедиться, что важные данные сохранены в backup.

---

# Backup

В проекте присутствует директория:

```text
/opt/spidersoft/backups/
```

Скрипт резервного копирования:

```text
/opt/spidersoft/scripts/backup.sh
```

---

# Logging

Для работы с логами используется:

```text
/opt/spidersoft/scripts/log_message.sh
```

Основная директория логов:

```text
/opt/spidersoft/logs/
```

---

# Server information

Скрипт:

```text
/opt/spidersoft/scripts/server-info.sh
```

Используется для получения информации о сервере и состоянии основных компонентов инфраструктуры.

---

# Конфигурация Docker

Основной Docker Compose файл:

```text
/opt/spidersoft/docker/docker-compose.yml
```

Dockerfile API:

```text
/opt/spidersoft/docker/api/Dockerfile
```

Dockerfile Web:

```text
/opt/spidersoft/docker/web/Dockerfile
```

Nginx configuration:

```text
/opt/spidersoft/docker/web/nginx/default.conf
```

Prometheus configuration:

```text
/opt/spidersoft/docker/prometheus/prometheus.yml
```

---

# Основные директории

## docker/

Основная Docker-инфраструктура проекта:

```text
/opt/spidersoft/docker/
```

Содержит:

```text
docker-compose.yml
Makefile
.env
api/
web/
prometheus/
scripts/
```

---

## app/

Директория приложения:

```text
/opt/spidersoft/app/
```

---

## backups/

Резервные копии:

```text
/opt/spidersoft/backups/
```

---

## docs/

Документация:

```text
/opt/spidersoft/docs/
```

Содержит:

```text
changes.md
profiles.md
server.md
```

---

## logs/

Логи проекта:

```text
/opt/spidersoft/logs/
```

---

## monitoring/

Материалы и конфигурация, связанные с мониторингом:

```text
/opt/spidersoft/monitoring/
```

---

## scripts/

Административные Bash-скрипты:

```text
/opt/spidersoft/scripts/
```

Содержит:

```text
backup.sh
log_message.sh
server-info.sh
```

---

# Полезные команды

## Статус Docker

```bash
docker ps
```

---

## Все контейнеры

```bash
docker ps -a
```

---

## Docker images

```bash
docker images
```

---

## Docker volumes

```bash
docker volume ls
```

---

## Docker networks

```bash
docker network ls
```

---

## Логи контейнера

```bash
docker logs <container>
```

---

## Следить за логами

```bash
docker logs -f <container>
```

---

## Статус через Makefile

```bash
make status
```

---

## Логи через Makefile

```bash
make logs
```

---

# Статус проекта

Текущий стек:

```text
============================================================
                 SPIDERSOFT INFRASTRUCTURE
============================================================

Operating System
    Debian 13

Container Runtime
    Docker CE

Container Orchestration
    Docker Compose V2

Web Server
    Nginx Latest

Backend
    Python 3.12
    Flask

Database
    PostgreSQL 16

Monitoring
    Prometheus Latest

Visualization
    Grafana Latest

Container Monitoring
    cAdvisor Latest

Database Administration
    Adminer Latest

CI/CD
    GitHub Actions

Version Control
    Git
    Main branch: main

============================================================
```

---

# Основные технологии

```text
Linux
Debian
Docker
Docker Compose
Nginx
Python
Flask
PostgreSQL
Prometheus
Grafana
cAdvisor
Adminer
Git
GitHub Actions
Make
Bash
```

---

# Цели проекта

SpiderSoft Infrastructure используется для практического изучения:

```text
Linux administration
Docker
Docker Compose
Networking
Nginx
PostgreSQL
Python / Flask
Bash scripting
Monitoring
Prometheus
Grafana
cAdvisor
Logging
Backups
Git
GitHub Actions
CI/CD
Infrastructure management
Production-like environments
```

Проект развивается постепенно. Каждый новый компонент должен интегрироваться с уже существующей инфраструктурой и добавлять новый практический DevOps-навык.

---

# Финальная схема проекта

```text
                              ┌─────────────────┐
                              │     Browser     │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │ spidersoft-web  │
                              │      Nginx      │
                              │      :8080      │
                              └────────┬────────┘
                                       │
                              ┌────────┴────────┐
                              │                 │
                              ▼                 ▼
                       Static content    ┌───────────────┐
                                        │ spidersoft-api │
                                        │ Flask :5000    │
                                        └───────┬───────┘
                                                │
                                                ▼
                                        ┌───────────────┐
                                        │ spidersoft-db │
                                        │ PostgreSQL    │
                                        │ :5432         │
                                        └───────────────┘


              ┌─────────────────────────────────────────┐
              │              Monitoring                 │
              │                                         │
              │   ┌─────────────┐                       │
              │   │  cAdvisor   │                       │
              │   │    :8082    │                       │
              │   └──────┬──────┘                       │
              │          │                              │
              │          ▼                              │
              │   ┌─────────────┐                       │
              │   │ Prometheus  │                       │
              │   │    :9090    │                       │
              │   └──────┬──────┘                       │
              │          │                              │
              │          ▼                              │
              │   ┌─────────────┐                       │
              │   │   Grafana   │                       │
              │   │    :3000    │                       │
              │   └─────────────┘                       │
              │                                         │
              │   Flask API ───────► /metrics           │
              └─────────────────────────────────────────┘


              ┌─────────────────────────────────────────┐
              │                 Tools                   │
              │                                         │
              │   ┌─────────────┐                       │
              │   │   Adminer   │                       │
              │   │    :8081    │                       │
              │   └──────┬──────┘                       │
              │          │                              │
              │          ▼                              │
              │      PostgreSQL                         │
              └─────────────────────────────────────────┘
```

---

# SpiderSoft Infrastructure

```text
============================================================
             🕷 SpiderSoft Infrastructure 🕷
============================================================

Environment : Production
OS          : Debian 13
Runtime     : Docker CE
Compose     : V2

Backend     : Flask / Python 3.12
Database    : PostgreSQL 16
Web         : Nginx
Monitoring  : Prometheus + Grafana
Containers  : cAdvisor
DB UI       : Adminer

Git branch  : main
CI/CD       : GitHub Actions

============================================================
```
