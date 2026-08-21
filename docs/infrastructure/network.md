============================================================
                    🕷 SPIDERSOFT NETWORK 🕷
============================================================

SpiderSoft использует изолированную Docker-сеть
для коммуникации между контейнерами.

Внешний доступ осуществляется через Nginx,
который выступает в роли reverse proxy.


============================================================
                    🌐 ТОПОЛОГИЯ
============================================================

                         Browser
                            │
                            ▼
                    ┌───────────────┐
                    │ spidersoft-web │
                    │     Nginx      │
                    │      :80      │
                    └───────┬───────┘
                            │
                     /api/  │
                            ▼
                    ┌───────────────┐
                    │ spidersoft-api │
                    │    Flask      │
                    │     :5000     │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │ spidersoft-db │
                    │  PostgreSQL   │
                    │     :5432     │
                    └───────────────┘


Статика:

    Browser
       │
       ▼
    spidersoft-web
       │
       ▼
    Static content


Мониторинг:

    cAdvisor
        │
        ▼
    Prometheus
        │
        ▼
    Grafana


============================================================
                    🐳 DOCKER NETWORK
============================================================

Имя:

    spidersoft-network


Тип:

    bridge


Docker Compose:

    networks:
      spidersoft-network:
        external: true


Создание:

    docker network create spidersoft-network


Проверка:

    docker network inspect spidersoft-network


============================================================
                    📡 DOCKER DNS
============================================================

Контейнеры обращаются друг к другу
по именам сервисов.

IP-адреса контейнеров вручную не используются.


Примеры:

    spidersoft-api
        │
        └──► spidersoft-db:5432


    spidersoft-prometheus
        │
        └──► spidersoft-api:5000


    spidersoft-grafana
        │
        └──► spidersoft-prometheus:9090


Docker автоматически разрешает имена
контейнеров через встроенный DNS.


Проверить DNS внутри контейнера:

    docker exec spidersoft-api \
        ping spidersoft-db


============================================================
                    🔌 ПОРТЫ
============================================================

Сервисы, доступные с Docker host:


    spidersoft-web

        Container: 80
        Host:      8080

        Назначение:
            Основной вход в приложение.


    spidersoft-adminer

        Container: 8080
        Host:      8081

        Назначение:
            Web UI для PostgreSQL.


    spidersoft-cadvisor

        Container: 8080
        Host:      8082

        Назначение:
            Мониторинг контейнеров.


    spidersoft-prometheus

        Container: 9090
        Host:      9090

        Назначение:
            Prometheus UI.


    spidersoft-grafana

        Container: 3000
        Host:      3000

        Назначение:
            Grafana UI.


    spidersoft-loki

        Container: 3100
        Host:      3100

        Назначение:
            Loki API.


============================================================
                    🔒 ВНУТРЕННИЕ СЕРВИСЫ
============================================================

Следующие сервисы не публикуют порты
на Docker host:


    spidersoft-api

        5000


    spidersoft-db

        5432


Они доступны только:

    - внутри Docker network;
    - через другие контейнеры;
    - через reverse proxy, если настроен.


Это уменьшает количество точек,
доступных извне.


============================================================
                    🔁 REVERSE PROXY
============================================================

Контейнер:

    spidersoft-web


Web server:

    Nginx


Основной порт:

    Host:      8080
    Container: 80


Nginx выполняет две основные задачи:

    1. Отдаёт статический контент.
    2. Проксирует API-запросы.


Схема:

    http://localhost:8080/
            │
            ▼
       Static content


    http://localhost:8080/api/
            │
            ▼
    spidersoft-api:5000


Конфигурация:

    /opt/spidersoft/docker/web/nginx/default.conf


Пример:

    location /api/ {
        proxy_pass http://spidersoft-api:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }


============================================================
                    🔄 API REQUEST FLOW
============================================================

    Browser
       │
       │ HTTP :8080
       ▼
    Nginx
       │
       │ /api/
       ▼
    spidersoft-api:5000
       │
       │ PostgreSQL
       ▼
    spidersoft-db:5432


API и PostgreSQL не требуют
публичных портов.


============================================================
                    📊 MONITORING NETWORK
============================================================

    spidersoft-cadvisor
             │
             │ metrics
             ▼
    spidersoft-prometheus
             │
             │ PromQL
             ▼
    spidersoft-grafana


Prometheus получает метрики API:

    spidersoft-api:5000/metrics


Grafana получает данные
из Prometheus:

    spidersoft-prometheus:9090


============================================================
                    📝 LOGGING
============================================================

Если используются Loki и Promtail:


    spidersoft-promtail
             │
             │ logs
             ▼
    spidersoft-loki:3100


Loki:

    Container port: 3100
    Host port:      3100


============================================================
                    🔒 БЕЗОПАСНОСТЬ
============================================================

Основные принципы:

    1. Изолированная Docker network.

    2. Минимальный проброс портов.

    3. PostgreSQL не публикуется на host.

    4. API не публикуется напрямую на host.

    5. Внешний HTTP-трафик проходит через Nginx.

    6. Внутренняя коммуникация выполняется
       через Docker DNS.


Сервисы без ports:

    недоступны напрямую с Docker host
    через опубликованный TCP-порт.


============================================================
                    🔍 ДИАГНОСТИКА
============================================================

Посмотреть Docker networks:

    docker network ls


Посмотреть содержимое сети:

    docker network inspect spidersoft-network


Посмотреть контейнеры:

    docker ps


Проверить DNS:

    docker exec spidersoft-api \
        ping spidersoft-db


Проверить API с host:

    curl -I http://localhost:8080/api/health


Проверить API непосредственно
из Docker network:

    docker exec spidersoft-web \
        wget -qO- http://spidersoft-api:5000/health


Посмотреть логи Nginx:

    docker logs spidersoft-web --tail 50


Следить за логами:

    docker logs -f spidersoft-web


============================================================
                    🛠️ ПОЛЕЗНЫЕ ПРОВЕРКИ
============================================================

Проверить, слушает ли host порт:

    ss -tlnp


Проверить конкретный порт:

    ss -tlnp | grep :8080


Проверить HTTP:

    curl http://localhost:8080


Проверить API:

    curl http://localhost:8080/api/health


Проверить Prometheus:

    curl http://localhost:9090/-/healthy


Проверить Grafana:

    curl http://localhost:3000/api/health


============================================================
                    🕷 NETWORK SUMMARY
============================================================

    Network:

        spidersoft-network


    Type:

        bridge


    External:

        yes


    Main entry point:

        Nginx :8080


    API:

        spidersoft-api:5000


    Database:

        spidersoft-db:5432


    Metrics:

        spidersoft-prometheus:9090


    Dashboard:

        spidersoft-grafana:3000


    Container monitoring:

        spidersoft-cadvisor:8080


    Database UI:

        spidersoft-adminer:8080


    Logging:

        spidersoft-loki:3100


============================================================
