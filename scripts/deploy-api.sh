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

# --- Функция проверки health (исправленная) ---
wait_for_health() {
    local container="$1"
    local max_wait="$2"
    local interval="$3"

    # 1. Проверяем, настроен ли healthcheck вообще
    local has_healthcheck
    has_healthcheck=$(docker inspect --format='{{json .Config.Healthcheck}}' "$container" 2>/dev/null)
    
    if [ "$has_healthcheck" = "null" ] || [ -z "$has_healthcheck" ]; then
        echo "⚠️  Healthcheck не настроен для контейнера $container. Пропускаем ожидание."
        log "WARNING" "Healthcheck не настроен для контейнера $container"
        return 0
    fi

    # 2. Ждём, пока статус появится и станет healthy
    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")
        
        case "$health_status" in
            healthy)
                echo "✅ Контейнер здоров"
                return 0
                ;;
            unhealthy)
                echo "❌ Контейнер unhealthy"
                return 1
                ;;
            starting)
                echo "⏳ Контейнер запускается (status: starting)..."
                ;;
            none|"")
                echo "⏳ Статус ещё не появился..."
                ;;
        esac
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    echo "❌ Таймаут: контейнер не стал healthy за $max_wait секунд"
    return 1
}

# --- Функция pull образа с проверкой ---
pull_image() {
    local full_image="$1"
    local desc="$2"
    
    echo "📦 Скачиваем образ ${full_image} (${desc})"
    if docker pull "$full_image" > /dev/null 2>&1; then
        echo "✅ Образ скачан успешно (${desc})"
        return 0
    else
        echo "❌ Не удалось скачать образ ${full_image} (${desc})"
        log "ERROR" "Pull failed для ${desc}: ${full_image}"
        return 1
    fi
}

# --- Функция деплоя конкретного SHA (исправленная) ---
deploy_version() {
    local sha="$1"
    local full_image="${REGISTRY}/${IMAGE_NAME}:${sha}"
    local desc="$2"

    echo "📦 Деплой ${desc}: ${sha}"

    # Явная проверка pull
    if ! pull_image "$full_image" "$desc"; then
        echo "❌ Невозможно продолжить: образ ${desc} не доступен"
        return 2  # Код 2 = ошибка pull
    fi

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

# --- Функция обновления last-good-version ---
update_last_good() {
    local sha="$1"
    mkdir -p "$(dirname "$LAST_GOOD_VERSION_FILE")"
    echo "$sha" > "$LAST_GOOD_VERSION_FILE"
    chown devops:devops "$LAST_GOOD_VERSION_FILE" 2>/dev/null || true
    log "INFO" "Сохранена last-good-version: $sha"
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
    update_last_good "$CURRENT_SHA"
else
    # Если файла нет — берём из контейнера
    # Исправлено: используем переменные и явную проверку пустоты
    CURRENT_SHA=$(docker inspect "$CONTAINER_NAME" 2>/dev/null | grep -o "${REGISTRY}/${IMAGE_NAME}:[a-f0-9]*" | head -1 | cut -d':' -f2)
    CURRENT_SHA="${CURRENT_SHA:-unknown}"
    echo "🔹 Текущая версия (из контейнера): $CURRENT_SHA"
    if [ "$CURRENT_SHA" != "unknown" ]; then
        update_last_good "$CURRENT_SHA"
    else
        log "WARNING" "Не удалось определить текущую версию"
    fi
fi

# --- 2. Пытаемся задеплоить новую версию ---
echo ""
echo "📌 Шаг 1: Деплой новой версии ${TAG}"

# Исправлено: обёрнуто в if, чтобы set -e не убивал скрипт
if deploy_version "$TAG" "новая версия"; then
    DEPLOY_RESULT=0
else
    DEPLOY_RESULT=$?
fi

case $DEPLOY_RESULT in
    0)
        # Успешный деплой
        echo "$TAG" > "$CURRENT_VERSION_FILE"
        chown devops:devops "$CURRENT_VERSION_FILE" 2>/dev/null || true
        echo "✅ Деплой успешно завершён. Текущая версия: $TAG"
        log "INFO" "Деплой успешно завершён. Новая версия: $TAG"
        exit 0
        ;;
    2)
        # Pull failed — не пытаемся откатываться, просто выходим с ошибкой
        echo "❌ Не удалось скачать образ новой версии. Откат не требуется."
        log "ERROR" "Pull новой версии ${TAG} не удался. Деплой отменён."
        exit 2
        ;;
    1)
        # Деплой провалился, но образ скачан — пытаемся откат
        echo ""
        echo "⚠️  Новая версия не поднялась. Начинаем откат..."
        log "WARNING" "Новая версия ${TAG} не поднялась. Начинаем откат"
        ;;
esac

# --- 3. Откат ---
LAST_GOOD_SHA=$(cat "$LAST_GOOD_VERSION_FILE" 2>/dev/null || echo "")

if [ -z "$LAST_GOOD_SHA" ] || [ "$LAST_GOOD_SHA" = "$TAG" ]; then
    echo "❌ Нет предыдущей рабочей версии для отката!"
    log "ERROR" "Откат невозможен: нет предыдущей рабочей версии"
    exit 1
fi

echo "🔹 Откатываемся на версию: $LAST_GOOD_SHA"
log "INFO" "Начинаем откат на версию ${LAST_GOOD_SHA}"

# Исправлено: обёрнуто в if, чтобы set -e не убивал скрипт
if deploy_version "$LAST_GOOD_SHA" "старая версия (откат)"; then
    ROLLBACK_RESULT=0
else
    ROLLBACK_RESULT=$?
fi

case $ROLLBACK_RESULT in
    0)
        echo "$LAST_GOOD_SHA" > "$CURRENT_VERSION_FILE"
        chown devops:devops "$CURRENT_VERSION_FILE" 2>/dev/null || true
        echo "✅ Откат успешно выполнен. Текущая версия: $LAST_GOOD_SHA"
        log "INFO" "Откат успешно выполнен на версию ${LAST_GOOD_SHA}"
        exit 0
        ;;
    2)
        echo "❌ Не удалось скачать образ старой версии (откат невозможен!)"
        log "ERROR" "Pull старой версии ${LAST_GOOD_SHA} не удался. Критическая ситуация!"
        exit 3
        ;;
    *)
        echo "❌ КРИТИЧЕСКАЯ ОШИБКА: и новая, и старая версия не поднялись!"
        log "ERROR" "Двойной сбой: новая версия ${TAG} и старая версия ${LAST_GOOD_SHA} не поднялись"
        echo "📌 Требуется ручное вмешательство!"
        exit 1
        ;;
esac
