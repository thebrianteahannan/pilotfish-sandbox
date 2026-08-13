FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
ENV PORT=4599 PYTHONUNBUFFERED=1
EXPOSE 4599
CMD ["python", "app.py"]
