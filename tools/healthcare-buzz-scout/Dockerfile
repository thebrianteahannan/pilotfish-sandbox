FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./
COPY config/ ./config/
COPY templates/ ./templates/
COPY static/ ./static/

ENV WEBUI_PORT=8130 \
    SCOUT_DB=/data/buzz.sqlite3 \
    POLL_INTERVAL_SECONDS=3600 \
    PYTHONUNBUFFERED=1

EXPOSE 8130
VOLUME ["/data"]
CMD ["python", "main.py"]
