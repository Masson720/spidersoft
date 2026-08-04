.PHONY: help dev prod core monitoring tools all down clean status logs rebuild force-clean

# ============================================
# ПЕРЕМЕННЫЕ
# ============================================

COMPOSE = docker compose -p spidersoft
COMPOSE_FILE_PATH = /opt/spidersoft/docker

# Цвета для вывода
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# ============================================
# КОМАНДЫ
# ============================================

help: ## Показать справку
	@echo "$(BLUE)=== SpiderSoft Docker Commands ===$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Примеры:$(NC)"
	@echo "  make dev      - Запуск разработки"
	@echo "  make prod     - Запуск production"
	@echo "  make status   - Проверка статуса"
	@echo "  make down     - Остановка"
	@echo "  make clean    - Полная очистка"
	@echo "  make force-clean - Принудительная очистка (если что-то сломалось)"

dev: ## Запуск в режиме разработки (core + tools)
	@echo "$(GREEN)▶ Запуск DEVELOPMENT окружения...$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) --profile core --profile tools up -d
	@echo "$(GREEN)✅ Готово!$(NC)"
	@echo "  Web:      http://localhost:8080"
	@echo "  API:      http://localhost:8080/api"
	@echo "  Adminer:  http://localhost:8081"

prod: ## Запуск в production режиме (core + monitoring)
	@echo "$(GREEN)▶ Запуск PRODUCTION окружения...$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) --profile core --profile monitoring up -d
	@echo "$(GREEN)✅ Готово!$(NC)"
	@echo "  Web:        http://localhost:8080"
	@echo "  API:        http://localhost:8080/api"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana:    http://localhost:3000 (admin/admin)"
	@echo "  cAdvisor:   http://localhost:8082"

core: ## Только ядро (web, api, db)
	@echo "$(GREEN)▶ Запуск CORE сервисов...$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) --profile core up -d

monitoring: ## Только мониторинг (cadvisor, prometheus)
	@echo "$(GREEN)▶ Запуск MONITORING сервисов...$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) --profile monitoring up -d

tools: ## Только инструменты (adminer)
	@echo "$(GREEN)▶ Запуск TOOLS сервисов...$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) --profile tools up -d

all: ## Запуск всех сервисов
	@echo "$(GREEN)▶ Запуск ВСЕХ сервисов...$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) --profile core --profile monitoring --profile tools up -d

down: ## Остановить все сервисы
	@echo "$(YELLOW)▶ Остановка всех сервисов...$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) down

clean: down ## Полная очистка (остановка + удаление volumes)
	@echo "$(RED)▶ Очистка данных...$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) down -v
	@echo "$(RED)⚠️  Все данные удалены!$(NC)"

force-clean: ## Принудительная очистка (если контейнеры не останавливаются)
	@echo "$(RED)▶ ПРИНУДИТЕЛЬНАЯ ОЧИСТКА...$(NC)"
	@echo "  Остановка через docker compose -p docker..."
	cd $(COMPOSE_FILE_PATH) && docker compose -p docker down 2>/dev/null || true
	@echo "  Остановка через docker compose -p spidersoft..."
	cd $(COMPOSE_FILE_PATH) && docker compose -p spidersoft down 2>/dev/null || true
	@echo "  Принудительная остановка контейнеров..."
	docker stop $$(docker ps -q --filter "name=spidersoft") 2>/dev/null || true
	docker rm $$(docker ps -aq --filter "name=spidersoft") 2>/dev/null || true
	@echo "$(GREEN)✅ Все контейнеры удалены!$(NC)"

status: ## Показать статус контейнеров
	@echo "$(BLUE)=== Статус контейнеров ===$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) ps

logs: ## Показать логи всех сервисов
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) logs -f --tail=50

rebuild: force-clean ## Пересобрать и запустить
	@echo "$(YELLOW)▶ Пересборка образов...$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) build --no-cache
	@echo "$(GREEN)✅ Готово! Запуск...$(NC)"
	cd $(COMPOSE_FILE_PATH) && $(COMPOSE) --profile core --profile tools up -d
	@echo "  Web:      http://localhost:8080"
	@echo "  API:      http://localhost:8080/api"
	@echo "  Adminer:  http://localhost:8081"
