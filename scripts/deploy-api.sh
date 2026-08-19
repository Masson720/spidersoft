#!/bin/bash
# Скрипт деплоя API с указанным тегом

set -e  # Остановка при ошибке

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
CONTAINER_NAME="spidersoft-api"

# Таймаут ожидания health (в секундах)
MAX_WAIT=30
INTERVAL=2

echo "🚀 Начинаем деплой версии ${TAG}"

# --- Проверка .env ---
if [ ! -f "${ENV_FILE}" ]; then
    echo "⚠️ Файл .env не найден, создаём"
    mkdir -p "$(dirname "${ENV_FILE}")"
    touch "${ENV_FILE}"
fi

# --- 1. Скачивание образа ---
echo "📦 Скачиваем образ ${FULL_IMAGE}"
docker pull "${FULL_IMAGE}"

# --- 2. Обновление .env с новым тегом ---
echo "✏️ Обновляем переменную API_IMAGE в .env"
sed -i "s|^API_IMAGE=.*|API_IMAGE=${FULL_IMAGE}|" "${ENV_FILE}"
if ! grep -q "^API_IMAGE=" "${ENV_FILE}"; then
    echo "API_IMAGE=${FULL_IMAGE}" >> "${ENV_FILE}"
fi

# --- 3. Перезапуск контейнера через docker compose ---
echo "🔄 Перезапускаем сервис ${CONTAINER_NAME}"
cd "${COMPOSE_DIR}"
docker compose -p spidersoft up -d --force-recreate --no-deps "${CONTAINER_NAME}"

# --- 4. Проверка статуса health ---
echo "⏳ Ожидаем статус healthy для контейнера ${CONTAINER_NAME} (макс. ${MAX_WAIT} сек.)"

ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Получаем статус health
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "none")
    
    case "$HEALTH_STATUS" in
        healthy)
            echo "✅ Контейнер здоров!"
            break
            ;;
        unhealthy)
            echo "❌ Контейнер в статусе unhealthy. Логи:"
            docker logs "${CONTAINER_NAME}" --tail 20
            exit 1
            ;;
        starting)
            echo "⏳ Контейнер ещё запускается (status: starting)..."
            ;;
        none|"")
            echo "⚠️ Healthcheck не настроен или недоступен. Пропускаем проверку."
            break
            ;;
        *)
            echo "⚠️ Неизвестный статус: ${HEALTH_STATUS}"
            ;;
    esac
    
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $MAX_WAIT ] && [ "$HEALTH_STATUS" != "healthy" ]; then
    echo "❌ Таймаут: контейнер не стал healthy за ${MAX_WAIT} секунд."
    echo "Последние логи:"
    docker logs "${CONTAINER_NAME}" --tail 20
    exit 1
fi

# --- 5. Дополнительная проверка через curl (если нужно) ---
# Можно закомментировать, если уже полагаемся на healthcheck
# echo "🏥 Проверяем healthcheck через curl..."
# if docker exec "${CONTAINER_NAME}" curl -s -f http://localhost:5000/health > /dev/null; then
#     echo "✅ Healthcheck пройден"
# else
#     echo "⚠️ Healthcheck не прошёл, но контейнер запущен (проверьте вручную)"
# fi

# --- 6. Сохранение текущей версии ---
echo "💾 Сохраняем текущую версию (${TAG}) в ${CURRENT_VERSION_FILE}"
mkdir -p "$(dirname "${CURRENT_VERSION_FILE}")"
echo "${TAG}" > "${CURRENT_VERSION_FILE}"

echo "✅ Деплой успешно завершён, версия: ${TAG}"
