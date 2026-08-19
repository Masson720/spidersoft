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

echo "🚀 Начинаем деплой версии ${TAG}"

# --- 1. Логин в GHCR (если приватный) ---
# Для публичных репозиториев можно пропустить
# Если приватный, нужно добавить логин через токен.
# В учебном проекте репозиторий публичный, поэтому пропускаем.

# --- 2. Скачивание образа ---
echo "📦 Скачиваем образ ${FULL_IMAGE}"
docker pull "${FULL_IMAGE}"

# --- 3. Обновление .env с новым тегом ---
echo "✏️ Обновляем переменную API_IMAGE в .env"
sed -i "s|^API_IMAGE=.*|API_IMAGE=${FULL_IMAGE}|" "${ENV_FILE}"
# Если переменной нет, добавляем
grep -q "^API_IMAGE=" "${ENV_FILE}" || echo "API_IMAGE=${FULL_IMAGE}" >> "${ENV_FILE}"

# --- 4. Перезапуск контейнера через docker compose ---
echo "🔄 Перезапускаем сервис spidersoft-api"
cd "${COMPOSE_DIR}"
docker compose -p spidersoft up -d --force-recreate --no-deps spidersoft-api

# --- 5. Проверка состояния ---
echo "⏳ Ожидаем запуск контейнера..."
sleep 5
CONTAINER_NAME="spidersoft-api"
if docker ps --filter "name=${CONTAINER_NAME}" --filter "status=running" | grep -q "${CONTAINER_NAME}"; then
    echo "✅ Контейнер успешно запущен"
else
    echo "❌ Ошибка: контейнер не запущен"
    docker logs "${CONTAINER_NAME}" --tail 20
    exit 1
fi

# --- 6. Проверка healthcheck (если есть) ---
# Выполняем проверку через curl внутри контейнера
echo "🏥 Проверяем healthcheck..."
if docker exec "${CONTAINER_NAME}" curl -s -f http://localhost:5000/health > /dev/null; then
    echo "✅ Healthcheck пройден"
else
    echo "⚠️ Healthcheck не прошёл, но контейнер запущен (проверьте вручную)"
fi

# --- 7. Сохранение текущей версии ---
echo "💾 Сохраняем текущую версию (${TAG}) в ${CURRENT_VERSION_FILE}"
mkdir -p "$(dirname "${CURRENT_VERSION_FILE}")"
echo "${TAG}" > "${CURRENT_VERSION_FILE}"

echo "✅ Деплой успешно завершён, версия: ${TAG}"
