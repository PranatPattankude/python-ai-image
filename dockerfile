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
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --upgrade pip \
    && pip install --no-cache-dir --prefix=/install -r requirements.txt \
    \
    # Remove torch dev junk (big space saver)
    && rm -rf /install/lib/python3.11/site-packages/torch/include \
    && rm -rf /install/lib/python3.11/site-packages/torch/share \
    && rm -rf /install/lib/python3.11/site-packages/torchgen \
    \
    # Remove tests + caches
    && find /install -type d -name "tests" -exec rm -rf {} + \
    && find /install -type d -name "__pycache__" -exec rm -rf {} + \
    && find /install -type f -name "*.pyc" -delete \
    \
    # Remove static libraries
    && find /install -type f -name "*.a" -delete \
    \
    # Strip shared objects
    && find /install -type f -name "*.so" -exec strip --strip-unneeded {} + || true

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
