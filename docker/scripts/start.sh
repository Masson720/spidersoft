#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для показа справки
show_help() {
    echo -e "${BLUE}=== SpiderSoft Docker Launcher ===${NC}"
    echo ""
    echo "Использование:"
    echo "  ./start.sh [PROFILE] [COMMAND]"
    echo ""
    echo "Профили:"
    echo "  ${GREEN}development${NC}  - Запуск всех сервисов (core + tools)"
    echo "  ${GREEN}production${NC}   - Запуск production сервисов (core + monitoring)"
    echo "  ${GREEN}core${NC}         - Только основное приложение (web, api, db)"
    echo "  ${GREEN}monitoring${NC}   - Только мониторинг (cadvisor, prometheus)"
    echo "  ${GREEN}tools${NC}        - Только инструменты (adminer)"
    echo "  ${GREEN}all${NC}          - Все сервисы (core + monitoring + tools)"
    echo ""
    echo "Команды:"
    echo "  ${YELLOW}up${NC}        - Запустить сервисы (по умолчанию)"
    echo "  ${YELLOW}down${NC}      - Остановить сервисы"
    echo "  ${YELLOW}restart${NC}   - Перезапустить сервисы"
    echo "  ${YELLOW}logs${NC}      - Показать логи"
    echo "  ${YELLOW}ps${NC}        - Показать статус"
    echo "  ${YELLOW}build${NC}     - Пересобрать образы"
    echo ""
    echo "Примеры:"
    echo "  ./start.sh development up"
    echo "  ./start.sh production up"
    echo "  ./start.sh core down"
    echo "  ./start.sh monitoring logs"
}

# Проверка аргументов
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
    exit 0
fi

# Параметры по умолчанию
PROFILE=${1:-development}
COMMAND=${2:-up}

# Проверка профиля
case $PROFILE in
    development)
        PROFILES="core tools"
        DESC="Разработка (core + tools)"
        ;;
    production)
        PROFILES="core monitoring"
        DESC="Production (core + monitoring)"
        ;;
    core)
        PROFILES="core"
        DESC="Только ядро (web, api, db)"
        ;;
    monitoring)
        PROFILES="monitoring"
        DESC="Только мониторинг"
        ;;
    tools)
        PROFILES="tools"
        DESC="Только инструменты"
        ;;
    all)
        PROFILES="core monitoring tools"
        DESC="Все сервисы"
        ;;
    *)
        echo -e "${RED}❌ Неизвестный профиль: $PROFILE${NC}"
        show_help
        exit 1
        ;;
esac

# Сборка команды для docker compose
COMPOSE_CMD="docker compose"

# Добавляем все профили
for p in $PROFILES; do
    COMPOSE_CMD="$COMPOSE_CMD --profile $p"
done

# Добавляем команду
COMPOSE_CMD="$COMPOSE_CMD $COMMAND"

# Выполняем
echo -e "${BLUE}=== Запуск профиля: ${GREEN}$PROFILE${NC} (${DESC})${NC}"
echo -e "${YELLOW}Команда: $COMPOSE_CMD${NC}"
echo ""

# Если нужно добавить дополнительные параметры для разных команд
case $COMMAND in
    up)
        $COMPOSE_CMD -d
        ;;
    down)
        $COMPOSE_CMD
        ;;
    restart)
        $COMPOSE_CMD
        ;;
    logs)
        $COMPOSE_CMD --tail=50 -f
        ;;
    ps)
        $COMPOSE_CMD
        ;;
    build)
        $COMPOSE_CMD --no-cache
        ;;
    *)
        $COMPOSE_CMD
        ;;
esac

# Проверка статуса
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Команда выполнена успешно${NC}"
    
    # Показываем работающие контейнеры
    if [ "$COMMAND" == "up" ] || [ "$COMMAND" == "restart" ]; then
        echo -e "\n${BLUE}=== Работающие контейнеры: ===${NC}"
        docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
        
        echo -e "\n${GREEN}📌 Доступные сервисы:${NC}"
        echo "  - Web:      http://localhost:8080"
        echo "  - API:      http://localhost:8080/api"
        
        # Показываем дополнительные сервисы в зависимости от профиля
        if [[ "$PROFILES" == *"monitoring"* ]]; then
            echo "  - Prometheus: http://localhost:9090"
            echo "  - cAdvisor:   http://localhost:8082"
        fi
        if [[ "$PROFILES" == *"tools"* ]]; then
            echo "  - Adminer:    http://localhost:8081"
        fi
    fi
else
    echo -e "\n${RED}❌ Ошибка выполнения команды${NC}"
    exit 1
fi
