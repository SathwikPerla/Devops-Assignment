# Stage 1: Build & Dependencies
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Hardened Production Runtime
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY app ./app

# Non-root user for container security compliance
RUN useradd -u 1001 appuser && chown -R appuser:appuser /app
USER 1001

EXPOSE 5001

ENV FLASK_APP=app/app.py \
    PYTHONUNBUFFERED=1

CMD ["python", "app/app.py"]
