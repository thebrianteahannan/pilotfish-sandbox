FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ENV WEBUI_PORT=8111 PYTHONUNBUFFERED=1
EXPOSE 8111
CMD ["python", "app.py"]
