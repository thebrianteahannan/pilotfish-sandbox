FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
ENV PORT=8095 HOST=0.0.0.0 OUTPUT_DIR=/output
EXPOSE 8095
CMD ["python", "app.py"]
