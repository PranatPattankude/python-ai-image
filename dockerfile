# ---------- Stage 1 ----------
FROM python:3.11-slim AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ---------- Stage 2 ----------
FROM python:3.11-slim

WORKDIR /opt/ai-base

COPY --from=builder /usr/local /usr/local

RUN apt-get update && apt-get install -y \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

CMD ["python"]
