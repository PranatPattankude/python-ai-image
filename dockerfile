# ---------- Stage 1: Builder ----------
FROM python:3.10-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    git \
    curl \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

# Install AI dependencies
COPY requirements-ai.txt .
RUN pip install --prefix=/install -r requirements-ai.txt

# Install application dependencies
COPY requirements-app.txt .
RUN pip install --prefix=/install -r requirements-app.txt


# -------- Remove unnecessary files (major size reduction) --------

# Remove torch dev files
RUN rm -rf /install/lib/python3.10/site-packages/torch/include \
    && rm -rf /install/lib/python3.10/site-packages/torch/share \
    && rm -rf /install/lib/python3.10/site-packages/torchgen

# Remove transformers TF/Flax backends (not needed for PyTorch)
RUN rm -rf /install/lib/python3.10/site-packages/transformers/models/tf_* \
    && rm -rf /install/lib/python3.10/site-packages/transformers/models/flax_*

# Remove tests, caches
RUN find /install -type d -name "tests" -exec rm -rf {} + \
    && find /install -type d -name "__pycache__" -exec rm -rf {} + \
    && find /install -type f -name "*.pyc" -delete

# Remove static libraries
RUN find /install -type f -name "*.a" -delete

# Strip shared libraries
RUN find /install -type f -name "*.so" -exec strip --strip-unneeded {} + || true



# ---------- Stage 2: Runtime ----------
FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /opt/ai-base

RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Copy only installed packages
COPY --from=builder /install /usr/local

CMD ["python"]
