from prometheus_client import Counter, Histogram, generate_latest, REGISTRY
from prometheus_client import CONTENT_TYPE_LATEST
from flask import Flask, jsonify, request
import os
import time
import psycopg
import socket
from datetime import datetime

app = Flask(__name__)


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
    ['operation']  # 'query', 'connect', etc.
)


def get_connection():
    """Создает соединение с PostgreSQL"""
    try:
        conn = psycopg.connect(
            host=os.getenv("DB_HOST"),
            port=os.getenv("DB_PORT"),
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            connect_timeout=5  # Таймаут подключения 5 секунд
        )
        return conn
    except Exception as e:
        db_errors_total.labels(operation='connect').inc()
        raise e

# ============ ДЕКОРАТОР ДЛЯ СБОРА МЕТРИК ============

def track_metrics(f):
    """Декоратор для автоматического сбора метрик по каждому запросу"""
    def wrapper(*args, **kwargs):
        method = request.method
        endpoint = request.path
        
        start_time = time.time()
        
        try:
            response = f(*args, **kwargs)
            
            if isinstance(response, tuple):
                status_code = str(response[1]) if len(response) > 1 else '200'
            else:
                status_code = '200'
            
            http_requests_total.labels(
                method=method,
                endpoint=endpoint,
                status=status_code
            ).inc()
            
            duration = time.time() - start_time
            http_request_duration_seconds.labels(
                method=method,
                endpoint=endpoint
            ).observe(duration)
            
            return response
            
        except Exception as e:
            http_requests_total.labels(
                method=method,
                endpoint=endpoint,
                status='500'
            ).inc()
            
            duration = time.time() - start_time
            http_request_duration_seconds.labels(
                method=method,
                endpoint=endpoint
            ).observe(duration)
            
            raise
    
    wrapper.__name__ = f.__name__
    return wrapper

# ============ ENDPOINTS ============

@app.route("/metrics")
def metrics():
    """Эндпоинт для Prometheus"""
    return generate_latest(REGISTRY), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route("/", methods=["GET"])
@track_metrics
def index():
    return jsonify({
        "service": os.getenv('APP_NAME', 'spidersoft-api'),
        "version": os.getenv('APP_VERSION', '1.0.0'),
        "environment": os.getenv('APP_ENV', 'development'),
        "timestamp": datetime.now().isoformat(),
        "hostname": socket.gethostname()
    })

@app.route("/health", methods=["GET"])
@track_metrics
def health():
    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1")
        
        return jsonify({
            "status": "healthy",
            "database": "connected",
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        db_errors_total.labels(operation='query').inc()
        
        return jsonify({
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 503

@app.route("/version", methods=["GET"])
@track_metrics
def version():
    return jsonify({
        "name": os.getenv("APP_NAME", "spidersoft-api"),
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "environment": os.getenv("APP_ENV", "development")
    })

@app.route("/db-info")
@track_metrics
def db_info():
    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT version();")
                version = cursor.fetchone()[0]
        
        return jsonify({
            "postgres_version": version,
            "connected": True,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        db_errors_total.labels(operation='query').inc()
        
        return jsonify({
            "error": str(e),
            "connected": False,
            "timestamp": datetime.now().isoformat()
        }), 503

@app.route("/slow")
@track_metrics
def slow():
    """Тестовый эндпоинт для демонстрации гистограммы"""
    delay = 3
    time.sleep(delay)
    return jsonify({
        "message": f"Response after {delay} seconds delay",
        "timestamp": datetime.now().isoformat()
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
