FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py document_routes.py ./
COPY templates/ templates/
COPY static/ static/

ENV FLASK_APP=app.py
ENV WEBUI_PORT=8125
EXPOSE 8109
CMD ["python", "app.py"]
