============================================================
                  🕷 SPIDERSOFT MONITORING 🕷
============================================================

SpiderSoft использует стек мониторинга на основе
Prometheus и Grafana.

Мониторинг позволяет отслеживать:

    - состояние приложения;
    - состояние Docker-контейнеров;
    - состояние сервера;
    - состояние PostgreSQL;
    - производительность API;
    - использование CPU, памяти, диска и сети;
    - ошибки и доступность сервисов.


============================================================
                    🧩 COMPONENTS
============================================================

Prometheus:

    Сбор и хранение метрик.


Grafana:

    Визуализация метрик и управление алертами.


cAdvisor:

    Метрики Docker-контейнеров:

        CPU
        Memory
        Network


Node Exporter:

    Метрики хоста:

        CPU
        Memory
        Disk
        Load
        Uptime


PostgreSQL Exporter:

    Метрики PostgreSQL:

        Connections
        Database size
        Transactions
        Availability


SpiderSoft API:

    Собственные метрики приложения:

        Requests
        Errors
        Response time


============================================================
                    🌐 MONITORING SERVICES
============================================================

Prometheus:

    http://localhost:9090


Grafana:

    http://localhost:3000


cAdvisor:

    http://localhost:8082


Grafana:

    Login:    admin
    Password: admin


============================================================
                    📡 DATA SOURCES
============================================================

Prometheus:

    URL:

        http://spidersoft-prometheus:9090

    Назначение:

        Основной источник метрик.


Loki:

    URL:

        http://spidersoft-loki:3100

    Назначение:

        Источник логов.

    Подробности:

        logging.md


============================================================
                    📊 METRICS
============================================================


------------------------------------------------------------
                    1. CONTAINERS
------------------------------------------------------------

Источник:

    cAdvisor


CPU:

    rate(container_cpu_usage_seconds_total[5m])


Memory:

    container_memory_usage_bytes


Network Receive:

    container_network_receive_bytes_total


Network Transmit:

    container_network_transmit_bytes_total


------------------------------------------------------------
                    2. HOST
------------------------------------------------------------

Источник:

    Node Exporter


Свободное место:

    node_filesystem_avail_bytes


Размер файловой системы:

    node_filesystem_size_bytes


Доступная память:

    node_memory_MemAvailable_bytes


Общий объём памяти:

    node_memory_MemTotal_bytes


Load Average:

    node_load1
    node_load5
    node_load15


------------------------------------------------------------
                    3. POSTGRESQL
------------------------------------------------------------

Источник:

    PostgreSQL Exporter


Доступность:

    pg_up


Количество подключений:

    pg_stat_database_numbackends


Размер базы:

    pg_database_size_bytes


Время запуска PostgreSQL:

    pg_postmaster_start_time_seconds


------------------------------------------------------------
                    4. SPIDERSOFT API
------------------------------------------------------------

Источник:

    Flask API


Количество запросов:

    spidersoft_api_requests_total


Labels:

    method
    endpoint
    status


Время ответа:

    spidersoft_api_request_duration_seconds


Тип:

    Histogram


Ошибки базы данных:

    spidersoft_api_db_errors_total


============================================================
                    📈 GRAFANA DASHBOARDS
============================================================


SpiderSoft Infrastructure:

    Назначение:

        Общий статус инфраструктуры.


    Основные показатели:

        Service Status
        Memory Usage
        RPS
        Response Time
        Requests by Endpoint


SpiderSoft Containers:

    Назначение:

        Состояние Docker-контейнеров.


    Основные показатели:

        CPU
        Memory
        Network Receive
        Network Transmit


Host Overview:

    Назначение:

        Состояние сервера.


    Основные показатели:

        Disk Usage
        Memory
        Load
        Uptime


Дашборды хранятся в репозитории
в формате JSON:

    grafana/dashboards/


============================================================
                    🔔 ALERT RULES
============================================================

SpiderSoft API Down:

    Условие:

        up{job="spidersoft-api"} < 1

    For:

        1m

    Действие:

        Notification


SpiderSoft Disk Space High:

    Условие:

        Disk Usage > 80%

    For:

        5m

    Действие:

        Notification


SpiderSoft Container High Memory:

    Условие:

        Memory > 500 MB

    For:

        5m

    Действие:

        Notification


PostgreSQL High Connections:

    Статус:

        Опционально.


Все alert rules экспортируются в JSON.


Расположение:

    grafana/alerts/


============================================================
                    🎯 PROMETHEUS TARGETS
============================================================

Страница:

    http://localhost:9090/targets


Все необходимые targets должны находиться
в состоянии:

    UP


Основные targets:

    spidersoft-api
    cAdvisor
    Node Exporter
    PostgreSQL Exporter
    Prometheus


Если target находится в состоянии DOWN:

    1. Проверить контейнер.
    2. Проверить Docker network.
    3. Проверить endpoint метрик.
    4. Проверить конфигурацию Prometheus.
    5. Проверить логи.


============================================================
                    🔍 GRAFANA EXPLORE
============================================================

Grafana позволяет выполнять PromQL-запросы
через:

    Explore


------------------------------------------------------------
                    API STATUS
------------------------------------------------------------

    up{job="spidersoft-api"}


Результат:

    1 = сервис доступен

    0 = сервис недоступен


------------------------------------------------------------
                    CONTAINER MEMORY
------------------------------------------------------------

    container_memory_usage_bytes{name=~"spidersoft.*"}


------------------------------------------------------------
                    API RPS
------------------------------------------------------------

    rate(spidersoft_api_requests_total[5m])


Показывает количество запросов
в секунду за последние 5 минут.


------------------------------------------------------------
                    DISK USAGE
------------------------------------------------------------

    100 - (
        node_filesystem_avail_bytes{
            mountpoint="/"
        }
        /
        node_filesystem_size_bytes{
            mountpoint="/"
        }
        * 100
    )


Показывает процент занятого дискового пространства.


============================================================
                    🛠️ ДИАГНОСТИКА
============================================================

Проверить контейнеры:

    docker ps


Проверить monitoring-сервисы:

    docker ps | grep spidersoft


Проверить Docker network:

    docker network inspect spidersoft-network


Проверить Prometheus:

    curl http://localhost:9090/-/healthy


Проверить API metrics:

    curl http://localhost:8080/api/metrics


Проверить Grafana:

    curl http://localhost:3000/api/health


Посмотреть логи Prometheus:

    docker logs spidersoft-prometheus --tail 50


Посмотреть логи Grafana:

    docker logs spidersoft-grafana --tail 50


Посмотреть логи cAdvisor:

    docker logs spidersoft-cadvisor --tail 50


============================================================
                    🔄 MONITORING FLOW
============================================================

                    ┌───────────────┐
                    │ SpiderSoft API│
                    └───────┬───────┘
                            │
                         /metrics
                            │
                            ▼
                    ┌───────────────┐
                    │  Prometheus   │
                    └───────┬───────┘
                            │
                         PromQL
                            │
                            ▼
                    ┌───────────────┐
                    │    Grafana    │
                    └───────────────┘


Docker:

    cAdvisor
        │
        ▼
    Prometheus


Host:

    Node Exporter
        │
        ▼
    Prometheus


Database:

    PostgreSQL Exporter
        │
        ▼
    Prometheus


Logs:

    Promtail
        │
        ▼
    Loki
        │
        ▼
    Grafana


============================================================
                    📂 STRUCTURE
============================================================

Monitoring configuration:

    /opt/spidersoft/docker/prometheus/


Grafana dashboards:

    grafana/dashboards/


Grafana alerts:

    grafana/alerts/


Основная конфигурация Prometheus:

    prometheus/prometheus.yml


============================================================
                    🕷 MONITORING SUMMARY
============================================================

    Metrics:

        Prometheus


    Visualization:

        Grafana


    Container metrics:

        cAdvisor


    Host metrics:

        Node Exporter


    PostgreSQL metrics:

        PostgreSQL Exporter


    Application metrics:

        SpiderSoft API


    Logs:

        Loki


    Main Prometheus UI:

        http://localhost:9090


    Main Grafana UI:

        http://localhost:3000


    cAdvisor UI:

        http://localhost:8082


============================================================
