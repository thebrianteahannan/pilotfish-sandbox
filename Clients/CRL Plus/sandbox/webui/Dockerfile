FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ENV OUTPUT_DIR=/output
ENV HOST=0.0.0.0
ENV PORT=8094
EXPOSE 8094
CMD ["python", "app.py"]