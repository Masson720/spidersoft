#!/bin/bash

# Скрипт деплоя API с автоматическим откатом

set -Eeuo pipefail

# --- Параметры ---

if [[ $# -ne 1 ]]; then
    printf 'Ошибка: не указан тег образа.\n' >&2
    printf 'Использование: %s <sha>\n' "$0" >&2
    exit 1
fi

TAG="$1"

# Проверяем, что тег похож на SHA
if [[ ! "$TAG" =~ ^[a-fA-F0-9]{7,64}$ ]]; then
    printf 'Ошибка: некорректный SHA-тег: %s\n' "$TAG" >&2
    exit 1
fi

# --- Конфигурация ---

readonly REGISTRY="ghcr.io/masson720"
readonly IMAGE_NAME="spidersoft-api"
readonly FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

readonly COMPOSE_DIR="/opt/spidersoft/docker"
readonly ENV_FILE="${COMPOSE_DIR}/.env"

readonly CURRENT_VERSION_FILE="/opt/spidersoft/app/current-version"
readonly LAST_GOOD_VERSION_FILE="/opt/spidersoft/app/last-good-version"

readonly CONTAINER_NAME="spidersoft-api"
readonly LOG_SCRIPT="/opt/spidersoft/scripts/log_message.sh"
readonly FALLBACK_LOG_FILE="/var/log/spidersoft/admin.log"

# Таймаут ожидания health в секундах
readonly MAX_WAIT=30
readonly INTERVAL=2


# ============================================================
# ЛОГИРОВАНИЕ
# ============================================================

log() {
    local level="$1"
    local message="$2"

    # Ошибка логирования НИКОГДА не должна ломать деплой.
    if [[ -x "$LOG_SCRIPT" ]]; then
        if ! "$LOG_SCRIPT" "$level" "deploy-api.sh: $message" 2>/dev/null; then
            # Пытаемся записать напрямую в лог.
            # Если и это невозможно из-за permission denied —
            # просто игнорируем ошибку.
            printf '%s [%s] deploy-api.sh: %s\n' \
                "$(date '+%Y-%m-%d %H:%M:%S')" \
                "$level" \
                "$message" >> "$FALLBACK_LOG_FILE" 2>/dev/null || true
        fi
    else
        printf '%s [%s] deploy-api.sh: %s\n' \
            "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$level" \
            "$message" >> "$FALLBACK_LOG_FILE" 2>/dev/null || true
    fi

    # log всегда возвращает 0.
    return 0
}


# ============================================================
# ПРОВЕРКА HEALTH
# ============================================================

wait_for_health() {
    local container="$1"
    local max_wait="$2"
    local interval="$3"

    local health_config
    local elapsed=0
    local health_status

    # Сначала убеждаемся, что контейнер существует.
    if ! docker inspect "$container" >/dev/null 2>&1; then
        printf 'Ошибка: контейнер %s не найден.\n' "$container" >&2
        log "ERROR" "Контейнер не найден: $container"
        return 1
    fi

    # Проверяем, настроен ли healthcheck.
    if ! health_config="$(
        docker inspect \
            --format='{{json .Config.Healthcheck}}' \
            "$container" 2>/dev/null
    )"; then
        printf 'Ошибка: не удалось получить конфигурацию healthcheck.\n' >&2
        log "ERROR" "Не удалось проверить healthcheck контейнера $container"
        return 1
    fi

    if [[ "$health_config" == "null" || -z "$health_config" ]]; then
        printf 'Предупреждение: healthcheck не настроен для контейнера %s.\n' \
            "$container"

        log "WARNING" "Healthcheck не настроен для контейнера $container"

        return 0
    fi

    # Ждём, пока контейнер станет healthy.
    while (( elapsed < max_wait )); do

        health_status="$(
            docker inspect \
                --format='{{.State.Health.Status}}' \
                "$container" 2>/dev/null || true
        )"

        case "$health_status" in
            healthy)
                printf 'Контейнер здоров.\n'
                return 0
                ;;

            unhealthy)
                printf 'Контейнер unhealthy.\n'
                return 1
                ;;

            starting)
                printf 'Контейнер запускается (status: starting)...\n'
                ;;

            none|"")
                printf 'Статус health ещё не появился...\n'
                ;;

            *)
                printf 'Неизвестный health status: %s\n' "$health_status"
                ;;
        esac

        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    printf 'Таймаут: контейнер не стал healthy за %s секунд.\n' \
        "$max_wait"

    return 1
}


# ============================================================
# PULL ОБРАЗА
# ============================================================

pull_image() {
    local full_image="$1"
    local desc="$2"

    printf 'Скачиваем образ %s (%s)\n' "$full_image" "$desc"

    if docker pull "$full_image" > /dev/null 2>&1; then
        printf 'Образ скачан успешно (%s)\n' "$desc"
        return 0
    fi

    printf 'Не удалось скачать образ %s (%s)\n' \
        "$full_image" \
        "$desc" >&2

    log "ERROR" "Pull failed для ${desc}: ${full_image}"

    return 1
}


# ============================================================
# ДЕПЛОЙ КОНКРЕТНОЙ ВЕРСИИ
# ============================================================

deploy_version() {
    local sha="$1"
    local desc="$2"

    local full_image="${REGISTRY}/${IMAGE_NAME}:${sha}"

    printf 'Деплой %s: %s\n' "$desc" "$sha"

    # --------------------------------------------------------
    # 1. Скачиваем образ
    # --------------------------------------------------------

    if ! pull_image "$full_image" "$desc"; then
        printf 'Невозможно продолжить: образ %s недоступен.\n' "$desc" >&2

        return 2
    fi

    # --------------------------------------------------------
    # 2. Проверяем compose directory и .env
    # --------------------------------------------------------

    if [[ ! -d "$COMPOSE_DIR" ]]; then
        printf 'Ошибка: каталог Compose не существует: %s\n' \
            "$COMPOSE_DIR" >&2

        log "ERROR" "Compose directory не найден: $COMPOSE_DIR"

        return 1
    fi

    if [[ ! -f "$ENV_FILE" ]]; then
        printf 'Ошибка: .env файл не найден: %s\n' "$ENV_FILE" >&2

        log "ERROR" "ENV_FILE не найден: $ENV_FILE"

        return 1
    fi

    # --------------------------------------------------------
    # 3. Обновляем API_IMAGE
    # --------------------------------------------------------

    if grep -q '^API_IMAGE=' "$ENV_FILE"; then
        if ! sed -i "s|^API_IMAGE=.*|API_IMAGE=${full_image}|" "$ENV_FILE"; then
            printf 'Ошибка: не удалось обновить API_IMAGE.\n' >&2

            log "ERROR" "Не удалось обновить API_IMAGE в $ENV_FILE"

            return 1
        fi
    else
        if ! printf 'API_IMAGE=%s\n' "$full_image" >> "$ENV_FILE"; then
            printf 'Ошибка: не удалось добавить API_IMAGE в .env.\n' >&2

            log "ERROR" "Не удалось добавить API_IMAGE в $ENV_FILE"

            return 1
        fi
    fi

    # --------------------------------------------------------
    # 4. Перезапускаем контейнер
    # --------------------------------------------------------

    cd "$COMPOSE_DIR"

    if ! docker compose \
        -p spidersoft \
        up -d \
        --force-recreate \
        --no-deps \
        --no-build \
        "$CONTAINER_NAME"; then

        printf 'Ошибка: не удалось запустить контейнер %s.\n' \
            "$CONTAINER_NAME" >&2

        log "ERROR" "docker compose up завершился ошибкой для $desc"

        return 1
    fi

    # --------------------------------------------------------
    # 5. Проверяем health
    # --------------------------------------------------------

    if wait_for_health "$CONTAINER_NAME" "$MAX_WAIT" "$INTERVAL"; then
        printf 'Контейнер здоров (%s).\n' "$desc"

        log "INFO" "Контейнер успешно поднялся (${desc})"

        return 0
    fi

    printf 'Контейнер не стал healthy (%s).\n' "$desc" >&2

    log "ERROR" "Контейнер не стал healthy (${desc})"

    return 1
}


# ============================================================
# ОБНОВЛЕНИЕ LAST-GOOD-VERSION
# ============================================================

update_last_good() {
    local sha="$1"

    local directory
    directory="$(dirname "$LAST_GOOD_VERSION_FILE")"

    if ! mkdir -p "$directory"; then
        printf 'Ошибка: не удалось создать каталог %s.\n' \
            "$directory" >&2

        log "ERROR" "Не удалось создать каталог $directory"

        return 1
    fi

    if ! printf '%s\n' "$sha" > "$LAST_GOOD_VERSION_FILE"; then
        printf 'Ошибка: не удалось сохранить last-good-version.\n' >&2

        log "ERROR" "Не удалось записать $LAST_GOOD_VERSION_FILE"

        return 1
    fi

    # Если chown недоступен — это не ломает основной процесс.
    chown devops:devops "$LAST_GOOD_VERSION_FILE" 2>/dev/null || true

    log "INFO" "Сохранена last-good-version: $sha"

    return 0
}


# ============================================================
# ОСНОВНАЯ ЛОГИКА
# ============================================================

printf 'Запуск деплоя с автоматическим откатом.\n'

log "INFO" "Запуск деплоя версии ${TAG}"


# ------------------------------------------------------------
# 1. Определяем текущую версию
# ------------------------------------------------------------

if ! mkdir -p "$(dirname "$CURRENT_VERSION_FILE")"; then
    printf 'Ошибка: не удалось создать каталог для current-version.\n' >&2
    log "ERROR" "Не удалось создать каталог для current-version"
    exit 1
fi

if ! mkdir -p "$(dirname "$LAST_GOOD_VERSION_FILE")"; then
    printf 'Ошибка: не удалось создать каталог для last-good-version.\n' >&2
    log "ERROR" "Не удалось создать каталог для last-good-version"
    exit 1
fi


if [[ -f "$CURRENT_VERSION_FILE" ]]; then

    CURRENT_SHA="$(<"$CURRENT_VERSION_FILE")"

    if [[ -n "$CURRENT_SHA" ]]; then
        printf 'Текущая версия: %s\n' "$CURRENT_SHA"

        if ! update_last_good "$CURRENT_SHA"; then
            printf 'Ошибка: не удалось сохранить предыдущую рабочую версию.\n' >&2
            exit 1
        fi
    else
        printf 'Предупреждение: current-version пуст.\n'
        log "WARNING" "Файл current-version пуст"

        CURRENT_SHA="unknown"
    fi

else

    # Если current-version отсутствует,
    # пытаемся определить образ непосредственно из контейнера.
    CURRENT_IMAGE="$(
        docker inspect \
            --format='{{.Config.Image}}' \
            "$CONTAINER_NAME" 2>/dev/null || true
    )"

    if [[ "$CURRENT_IMAGE" =~ ^${REGISTRY}/${IMAGE_NAME}:([a-fA-F0-9]{7,64})$ ]]; then
        CURRENT_SHA="${BASH_REMATCH[1]}"

        printf 'Текущая версия (из контейнера): %s\n' "$CURRENT_SHA"

        if ! update_last_good "$CURRENT_SHA"; then
            printf 'Ошибка: не удалось сохранить предыдущую рабочую версию.\n' >&2
            exit 1
        fi
    else
        CURRENT_SHA="unknown"

        printf 'Текущая версия: неизвестна.\n'

        log "WARNING" "Не удалось определить текущую версию"
    fi
fi


# ------------------------------------------------------------
# 2. Пытаемся задеплоить новую версию
# ------------------------------------------------------------

printf '\n'
printf 'Шаг 1: Деплой новой версии %s\n' "$TAG"


# Важно:
# deploy_version может вернуть 1 или 2.
# Поэтому вызываем её внутри if — set -e здесь не должен
# преждевременно завершить весь скрипт.

if deploy_version "$TAG" "новая версия"; then
    DEPLOY_RESULT=0
else
    DEPLOY_RESULT=$?
fi


case "$DEPLOY_RESULT" in

    0)
        # ----------------------------------------------------
        # Успешный деплой
        # ----------------------------------------------------

        if ! printf '%s\n' "$TAG" > "$CURRENT_VERSION_FILE"; then
            printf 'Ошибка: не удалось сохранить current-version.\n' >&2
            log "ERROR" "Не удалось записать current-version"
            exit 1
        fi

        chown devops:devops "$CURRENT_VERSION_FILE" 2>/dev/null || true

        printf 'Деплой успешно завершён.\n'
        printf 'Текущая версия: %s\n' "$TAG"

        log "INFO" "Деплой успешно завершён. Новая версия: $TAG"

        exit 0
        ;;


    2)
        # ----------------------------------------------------
        # Pull новой версии не удался
        # ----------------------------------------------------

        printf 'Не удалось скачать образ новой версии.\n'
        printf 'Откат не требуется.\n'

        log "ERROR" "Pull новой версии ${TAG} не удался. Деплой отменён."

        exit 2
        ;;


    1)
        # ----------------------------------------------------
        # Образ скачан, но контейнер не поднялся
        # ----------------------------------------------------

        printf '\n'
        printf 'Новая версия не поднялась. Начинаем откат...\n'

        log "WARNING" "Новая версия ${TAG} не поднялась. Начинаем откат"
        ;;


    *)
        printf 'Неизвестный код результата деплоя: %s\n' \
            "$DEPLOY_RESULT" >&2

        log "ERROR" "Неизвестный код результата deploy_version: $DEPLOY_RESULT"

        exit 1
        ;;

esac


# ------------------------------------------------------------
# 3. Получаем последнюю рабочую версию
# ------------------------------------------------------------

LAST_GOOD_SHA="$(
    cat "$LAST_GOOD_VERSION_FILE" 2>/dev/null || true
)"

if [[ -z "$LAST_GOOD_SHA" || "$LAST_GOOD_SHA" == "$TAG" ]]; then

    printf 'Нет предыдущей рабочей версии для отката.\n' >&2

    log "ERROR" "Откат невозможен: нет предыдущей рабочей версии"

    exit 1
fi


printf 'Откатываемся на версию: %s\n' "$LAST_GOOD_SHA"

log "INFO" "Начинаем откат на версию ${LAST_GOOD_SHA}"


# ------------------------------------------------------------
# 4. Выполняем откат
# ------------------------------------------------------------

if deploy_version "$LAST_GOOD_SHA" "старая версия (откат)"; then
    ROLLBACK_RESULT=0
else
    ROLLBACK_RESULT=$?
fi


case "$ROLLBACK_RESULT" in

    0)
        # ----------------------------------------------------
        # Откат успешен
        # ----------------------------------------------------

        if ! printf '%s\n' "$LAST_GOOD_SHA" > "$CURRENT_VERSION_FILE"; then
            printf 'Ошибка: не удалось сохранить current-version после отката.\n' >&2
            log "ERROR" "Не удалось обновить current-version после отката"
            exit 1
        fi

        chown devops:devops "$CURRENT_VERSION_FILE" 2>/dev/null || true

        printf 'Откат успешно выполнен.\n'
        printf 'Текущая версия: %s\n' "$LAST_GOOD_SHA"

        log "INFO" "Откат успешно выполнен на версию ${LAST_GOOD_SHA}"

        exit 0
        ;;


    2)
        # ----------------------------------------------------
        # Не удалось скачать старую версию
        # ----------------------------------------------------

        printf 'Не удалось скачать образ старой версии.\n' >&2
        printf 'Откат невозможен. Требуется ручное вмешательство.\n' >&2

        log "ERROR" \
            "Pull старой версии ${LAST_GOOD_SHA} не удался. Критическая ситуация!"

        exit 3
        ;;


    *)
        # ----------------------------------------------------
        # Новая и старая версии не поднялись
        # ----------------------------------------------------

        printf 'КРИТИЧЕСКАЯ ОШИБКА: и новая, и старая версия не поднялись.\n' >&2
        printf 'Требуется ручное вмешательство.\n' >&2

        log "ERROR" \
            "Двойной сбой: новая версия ${TAG} и старая версия ${LAST_GOOD_SHA} не поднялись"

        exit 1
        ;;

esac
