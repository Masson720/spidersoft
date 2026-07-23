from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/", methods=["GET"])
def index():
    return jsonify({
        "service": "SpiderSoft API",
        "status": "ok"
    })

@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy"
    })

@app.route("/version", methods=["GET"])
def version():
    return jsonify({
        "name": os.getenv("APP_NAME"),
        "version": os.getenv("APP_VERSION"),
        "environment": os.getenv("APP_ENV")
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
