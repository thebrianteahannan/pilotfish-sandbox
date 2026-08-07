FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py snip_report.py docs_and_v2.py document_routes.py ./
COPY templates/ templates/
COPY static/ static/
COPY xslt/ xslt/

ENV FLASK_APP=app.py
EXPOSE 8115
CMD ["python", "app.py"]
