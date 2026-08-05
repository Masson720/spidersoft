# Docker Compose Profiles

## Описание

Проект использует Docker Compose Profiles для гибкого управления сервисами.

## Профили

### core
- spidersoft-web (nginx)
- spidersoft-api (Flask)
- spidersoft-db (PostgreSQL)
- **Использование:** Базовые сервисы, всегда нужны

### monitoring
- spidersoft-cadvisor (мониторинг контейнеров)
- spidersoft-prometheus (сбор метрик)
- **Использование:** Для наблюдения за системой

### tools
- spidersoft-adminer (UI для БД)
- **Использование:** Только для разработки

### development (core + tools)
- Все сервисы из core и tools
- **Использование:** Локальная разработка

### production (core + monitoring)
- Все сервисы из core и monitoring
- **Использование:** Production окружение

## Команды

### Через скрипт start.sh
```bash
./scripts/start.sh development up    # Запуск разработки
./scripts/start.sh production up     # Запуск production
./scripts/start.sh core up           # Только ядро
./scripts/start.sh monitoring up     # Только мониторинг
./scripts/start.sh tools up          # Только инструменты
./scripts/start.sh development down  # Остановка
