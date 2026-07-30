from prometheus_client import Counter, generate_latest
from flask import Flask, jsonify, Response
import os
import psycopg

app = Flask(__name__)
REQUEST_COUNT = Counter(
    "spidersoft_api_requests_total",
    "Total API requests"
)
def get_connection():
    return psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )
@app.route("/metrics")
def metrics():
    return Response(
        generate_latest(),
        mimetype="text/plain"
    )
@app.route("/", methods=["GET"])
def index():
    REQUEST_COUNT.inc()
    return jsonify({
        "service": "SpiderSoft API",
        "status": "ok"
    })

@app.route("/health", methods=["GET"])
def health():
    REQUEST_COUNT.inc()
    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1")

        return jsonify({
            "status": "healthy",
            "database": "connected"
        })

    except Exception:

        return jsonify({
            "status": "unhealthy",
            "database": "disconnected"
        }), 503

@app.route("/version", methods=["GET"])
def version():
    REQUEST_COUNT.inc()
    return jsonify({
        "name": os.getenv("APP_NAME"),
        "version": os.getenv("APP_VERSION"),
        "environment": os.getenv("APP_ENV")
    })


@app.route("/db-info")
def db_info():
    REQUEST_COUNT.inc()
    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT version();")
                version = cursor.fetchone()[0]

        return jsonify({
            "postgres_version": version
        })

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
