#!/bin/bash
# Скрипт деплоя API с автоматическим откатом

set -e  # Остановка при критической ошибке

# --- Параметры ---
TAG="$1"
if [ -z "$TAG" ]; then
    echo "❌ Ошибка: не указан тег образа"
    echo "Использование: $0 <sha>"
    exit 1
fi

# --- Конфигурация ---
REGISTRY="ghcr.io/masson720"
IMAGE_NAME="spidersoft-api"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"
COMPOSE_DIR="/opt/spidersoft/docker"
ENV_FILE="${COMPOSE_DIR}/.env"
CURRENT_VERSION_FILE="/opt/spidersoft/app/current-version"
LAST_GOOD_VERSION_FILE="/opt/spidersoft/app/last-good-version"
CONTAINER_NAME="spidersoft-api"
LOG_SCRIPT="/opt/spidersoft/scripts/log_message.sh"

# Таймаут ожидания health (в секундах)
MAX_WAIT=30
INTERVAL=2

# --- Функция логирования ---
log() {
    local level="$1"
    local message="$2"
    if [ -f "$LOG_SCRIPT" ]; then
        "$LOG_SCRIPT" "$level" "deploy-api.sh: $message"
    else
        echo "[$level] $message" >> /var/log/spidersoft/admin.log
    fi
}

# --- Функция проверки health ---
wait_for_health() {
    local container="$1"
    local max_wait="$2"
    local interval="$3"
    local elapsed=0

    while [ $elapsed -lt $max_wait ]; do
        HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")
        case "$HEALTH_STATUS" in
            healthy)
                return 0
                ;;
            unhealthy)
                return 1
                ;;
            starting)
                ;;
            none|"")
                echo "⚠️  Healthcheck не настроен, считаем что всё ок"
                return 0
                ;;
        esac
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    return 1
}

# --- Функция деплоя конкретного SHA ---
deploy_version() {
    local sha="$1"
    local full_image="${REGISTRY}/${IMAGE_NAME}:${sha}"
    local desc="$2"

    echo "📦 Деплой ${desc}: ${sha}"
    log "INFO" "Начало деплоя ${desc}: ${sha}"

    # Скачиваем образ
    echo "  Скачиваем образ ${full_image}"
    docker pull "${full_image}"

    # Обновляем .env
    sed -i "s|^API_IMAGE=.*|API_IMAGE=${full_image}|" "${ENV_FILE}"
    if ! grep -q "^API_IMAGE=" "${ENV_FILE}"; then
        echo "API_IMAGE=${full_image}" >> "${ENV_FILE}"
    fi

    # Перезапускаем контейнер
    cd "$COMPOSE_DIR"
    docker compose -p spidersoft up -d --force-recreate --no-deps --no-build "$CONTAINER_NAME"

    # Ждём health
    if wait_for_health "$CONTAINER_NAME" "$MAX_WAIT" "$INTERVAL"; then
        echo "✅ Контейнер здоров (${desc})"
        log "INFO" "Контейнер успешно поднялся (${desc})"
        return 0
    else
        echo "❌ Контейнер не стал healthy (${desc})"
        log "ERROR" "Контейнер не стал healthy (${desc})"
        return 1
    fi
}

# ============================================
# ОСНОВНАЯ ЛОГИКА
# ============================================

echo "🚀 Запуск деплоя с автоматическим откатом"
log "INFO" "Запуск деплоя версии ${TAG}"

# --- 1. Сохраняем текущий SHA как last-good-version ---
mkdir -p "$(dirname "$CURRENT_VERSION_FILE")"
mkdir -p "$(dirname "$LAST_GOOD_VERSION_FILE")"

if [ -f "$CURRENT_VERSION_FILE" ]; then
    CURRENT_SHA=$(cat "$CURRENT_VERSION_FILE")
    echo "🔹 Текущая версия: $CURRENT_SHA"
    echo "$CURRENT_SHA" > "$LAST_GOOD_VERSION_FILE"
    echo "💾 Сохранена last-good-version: $CURRENT_SHA"
    log "INFO" "Сохранена last-good-version: $CURRENT_SHA"
else
    # Если файла нет — значит, деплой впервые, берём из контейнера
    CURRENT_SHA=$(docker inspect "$CONTAINER_NAME" 2>/dev/null | grep -o 'ghcr.io/masson720/spidersoft-api:[a-f0-9]*' | head -1 | cut -d':' -f2 || echo "unknown")
    echo "🔹 Текущая версия (из контейнера): $CURRENT_SHA"
    echo "$CURRENT_SHA" > "$LAST_GOOD_VERSION_FILE"
fi

# --- 2. Пытаемся задеплоить новую версию ---
echo ""
echo "📌 Шаг 1: Деплой новой версии ${TAG}"
if deploy_version "$TAG" "новая версия"; then
    # Успешный деплой
    echo "$TAG" > "$CURRENT_VERSION_FILE"
    echo "✅ Деплой успешно завершён. Текущая версия: $TAG"
    log "INFO" "Деплой успешно завершён. Новая версия: $TAG"
    exit 0
fi

# --- 3. Если новая версия не поднялась — откат ---
echo ""
echo "⚠️  Новая версия не поднялась. Начинаем откат..."
log "WARNING" "Новая версия ${TAG} не поднялась. Начинаем откат"

LAST_GOOD_SHA=$(cat "$LAST_GOOD_VERSION_FILE" 2>/dev/null || echo "")

if [ -z "$LAST_GOOD_SHA" ] || [ "$LAST_GOOD_SHA" = "$TAG" ]; then
    echo "❌ Нет предыдущей рабочей версии для отката!"
    log "ERROR" "Откат невозможен: нет предыдущей рабочей версии"
    exit 1
fi

echo "🔹 Откатываемся на версию: $LAST_GOOD_SHA"
log "INFO" "Начинаем откат на версию ${LAST_GOOD_SHA}"

if deploy_version "$LAST_GOOD_SHA" "старая версия (откат)"; then
    # Откат успешен
    echo "$LAST_GOOD_SHA" > "$CURRENT_VERSION_FILE"
    echo "✅ Откат успешно выполнен. Текущая версия: $LAST_GOOD_SHA"
    log "INFO" "Откат успешно выполнен на версию ${LAST_GOOD_SHA}"
    exit 0
else
    # Двойной сбой: и новая, и старая версия не работают
    echo "❌ КРИТИЧЕСКАЯ ОШИБКА: и новая, и старая версия не поднялись!"
    log "ERROR" "Двойной сбой: новая версия ${TAG} и старая версия ${LAST_GOOD_SHA} не поднялись"
    echo "📌 Требуется ручное вмешательство!"
    exit 1
fi
