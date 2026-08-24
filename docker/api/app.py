import os
import time
import socket
import logging
from datetime import datetime
from flask import Flask, request, jsonify
import psycopg
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY, CONTENT_TYPE_LATEST

from pythonjsonlogger import jsonlogger
time.sleep(30)
# ============================================
# НАСТРОЙКА ЛОГГЕРА
# ============================================

# Создаём логгер с именем 'spidersoft'
logger = logging.getLogger('spidersoft')
logger.setLevel(logging.DEBUG)

# Создаём обработчик для stdout (консоль)
handler = logging.StreamHandler()
handler.setLevel(logging.DEBUG)

# Форматировщик JSON
formatter = jsonlogger.JsonFormatter(
    fmt='%(asctime)s %(levelname)s %(message)s %(module)s %(funcName)s',
    datefmt='%Y-%m-%dT%H:%M:%S',
    rename_fields={
        'asctime': 'timestamp',
        'levelname': 'level',
        'message': 'message'
    }
)
handler.setFormatter(formatter)
logger.addHandler(handler)

# Добавляем статическое поле "service" во все записи
logger = logging.LoggerAdapter(logger, {'service': 'SpiderSoft API'})

# ============================================
# FLASK ПРИЛОЖЕНИЕ
# ============================================

app = Flask(__name__)

# ============================================
# PROMETHEUS МЕТРИКИ
# ============================================

http_requests_total = Counter(
    'spidersoft_api_requests_total',
    'Total count of HTTP requests to SpiderSoft API',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'spidersoft_api_request_duration_seconds',
    'Histogram of HTTP request durations in seconds',
    ['method', 'endpoint']
)

db_errors_total = Counter(
    'spidersoft_api_db_errors_total',
    'Total count of database errors',
    ['operation']
)

# ============================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ============================================

def get_connection():
    try:
        conn = psycopg.connect(
            host=os.getenv("DB_HOST"),
            port=os.getenv("DB_PORT"),
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            connect_timeout=5
        )
        return conn
    except Exception as e:
        db_errors_total.labels(operation='connect').inc()
        raise e

# Отключаем стандартные access логи
logging.getLogger('werkzeug').setLevel(logging.ERROR)

# ============================================
# ДЕКОРАТОР ДЛЯ МЕТРИК И ЛОГИРОВАНИЯ
# ============================================

def track_and_log(f):
    """Декоратор для сбора метрик Prometheus и JSON-логирования запросов"""
    def wrapper(*args, **kwargs):
        method = request.method
        endpoint = request.path
        start_time = time.time()
        status_code = 200  # по умолчанию

        try:
            response = f(*args, **kwargs)
            if isinstance(response, tuple):
                status_code = response[1] if len(response) > 1 else 200
            else:
                status_code = 200

            duration_ms = (time.time() - start_time) * 1000  # в миллисекундах

            # Логируем запрос в JSON
            logger.info(
                "Request processed",
                extra={
                    'method': method,
                    'endpoint': endpoint,
                    'status': status_code,
                    'duration_ms': round(duration_ms, 3)
                }
            )

            # Записываем метрики Prometheus
            http_requests_total.labels(
                method=method,
                endpoint=endpoint,
                status=str(status_code)
            ).inc()
            http_request_duration_seconds.labels(
                method=method,
                endpoint=endpoint
            ).observe(duration_ms / 1000)

            return response

        except Exception as e:
            status_code = 500
            duration_ms = (time.time() - start_time) * 1000

            # Логируем ошибку с уровнем ERROR
            logger.error(
                "Request failed",
                extra={
                    'method': method,
                    'endpoint': endpoint,
                    'status': status_code,
                    'duration_ms': round(duration_ms, 3),
                    'error': str(e)
                }
            )

            # Записываем метрики Prometheus для ошибки
            http_requests_total.labels(
                method=method,
                endpoint=endpoint,
                status=str(status_code)
            ).inc()
            http_request_duration_seconds.labels(
                method=method,
                endpoint=endpoint
            ).observe(duration_ms / 1000)

            # Пробрасываем исключение дальше
            raise

    wrapper.__name__ = f.__name__
    return wrapper

# ============================================
# ENDPOINTS
# ============================================

@app.route('/')
@track_and_log
def home():
    logger.info("Home endpoint called")
    return jsonify({
        "service": os.getenv('APP_NAME', 'spidersoft-api'),
        "version": os.getenv('APP_VERSION', '1.0.0'),
        "environment": os.getenv('APP_ENV', 'development'),
        "timestamp": datetime.now().isoformat(),
        "hostname": socket.gethostname()
    })

@app.route('/health')
@track_and_log
def health():
    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1")
        logger.info("Health check passed")
        return jsonify({
            "status": "healthy",
            "database": "connected",
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        db_errors_total.labels(operation='query').inc()
        logger.error(f"Health check failed: {e}")
        return jsonify({
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 503

@app.route('/version')
@track_and_log
def version():
    logger.info("Version endpoint called")
    return jsonify({
        "name": os.getenv("APP_NAME", "spidersoft-api"),
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "environment": os.getenv("APP_ENV", "development")
    })

@app.route('/db-info')
@track_and_log
def db_info():
    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT version();")
                version = cursor.fetchone()[0]
        logger.info("Database info retrieved")
        return jsonify({
            "postgres_version": version,
            "connected": True,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        db_errors_total.labels(operation='query').inc()
        logger.error(f"Database info error: {e}")
        return jsonify({
            "error": str(e),
            "connected": False,
            "timestamp": datetime.now().isoformat()
        }), 503

@app.route('/slow')
@track_and_log
def slow():
    """Тестовый эндпоинт с задержкой"""
    delay = 3
    time.sleep(delay)
    logger.info(f"Slow endpoint delayed by {delay}s")
    return jsonify({
        "message": f"Response after {delay} seconds delay",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/metrics')
def metrics():
    return generate_latest(REGISTRY), 200, {'Content-Type': CONTENT_TYPE_LATEST}

# ============================================
# ЗАПУСК
# ============================================

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
