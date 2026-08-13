FROM python:3.12-slim
WORKDIR /app
COPY mllp_server.py /app/mllp_server.py
RUN mkdir -p /received
EXPOSE 2576
CMD ["python", "-u", "/app/mllp_server.py"]
