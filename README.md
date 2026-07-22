# SpiderSoft Infrastructure

## Description

Infrastructure automation and administration files.

## Server

Hostname: spider-app-01
OS: Debian 13
Role:

## Structure

- scripts - administrative scripts
- backups - backup storage
- logs - application and system logs
- monitoring - monitoring configuration
- app - application data
- docs - documentation

## Environment variables (.env)

### Зачем используется .env

Файл `.env` используется для хранения переменных окружения проекта.

Он позволяет отделить настройки приложения от основного файла `docker-compose.yml`. 
Благодаря этому можно менять параметры запуска контейнеров без изменения конфигурации Compose.

Docker Compose автоматически загружает файл `.env`, если он находится рядом с `docker-compose.yml`.

---

### Текущие переменные

Сейчас используются следующие переменные:

| Переменная | Значение | Назначение |
|------------|----------|------------|
| APP_NAME | SpiderSoft | Название приложения |
| APP_VERSION | 1.1 | Версия приложения |
| APP_ENV | production | Окружение запуска |

Переменные передаются в контейнер `spidersoft-web` через секцию `environment` в `docker-compose.yml`.

Пример:

```yaml
environment:
  APP_NAME: ${APP_NAME}
  APP_VERSION: ${APP_VERSION}
  APP_ENV: ${APP_ENV}
