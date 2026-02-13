# ---------- Stage 1: Builder ----------
FROM python:3.11-slim-bookworm AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --upgrade pip \
    && pip install --no-cache-dir --prefix=/install -r requirements.txt \
    && find /install -name "*.pyc" -delete \
    && find /install -name "__pycache__" -type d -exec rm -rf {} + \
    && find /install -name "tests" -type d -exec rm -rf {} + \
    && find /install -name "*.a" -delete \
    && strip --strip-unneeded /install/lib/python3.11/site-packages/*/*.so || true

# ---------- Stage 2: Runtime ----------
FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

CMD ["python"]
