FROM nginx:latest

ARG BUILD_DATE

RUN apt-get update && \
    apt-get install -y wget && \
    rm -rf /var/lib/apt/lists/*

COPY index.html /usr/share/nginx/html/index.html

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --quiet --spider http://localhost || exit 1
