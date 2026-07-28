from flask import Flask, jsonify
import os
import psycopg

app = Flask(__name__)
def get_connection():
    return psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )

@app.route("/", methods=["GET"])
def index():
    return jsonify({
        "service": "SpiderSoft API",
        "status": "ok"
    })

@app.route("/health", methods=["GET"])
def health():
    try:
        connection = get_connection()

        cursor = connection.cursor()

        cursor.execute("SELECT 1;")

        cursor.close()

        connection.close()

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
    return jsonify({
        "name": os.getenv("APP_NAME"),
        "version": os.getenv("APP_VERSION"),
        "environment": os.getenv("APP_ENV")
    })


@app.route("/db-info")
def db_info():
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
