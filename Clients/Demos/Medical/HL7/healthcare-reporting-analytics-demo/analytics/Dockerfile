FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir "flask>=3.0,<4"
COPY app.py .
ENV PORT=7072 PYTHONUNBUFFERED=1
EXPOSE 7072
CMD ["python", "app.py"]
