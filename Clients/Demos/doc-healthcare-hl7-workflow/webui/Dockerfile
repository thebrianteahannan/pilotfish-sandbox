FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
COPY templates/ templates/
COPY static/ static/

ENV FLASK_APP=app.py
EXPOSE 8092
CMD ["python", "app.py"]
