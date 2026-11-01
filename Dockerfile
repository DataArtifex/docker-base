ARG QSV_IMAGE="dartfx/qsv:latest"
FROM ${QSV_IMAGE} AS qsv-source

# --- Stage 1: Build & Sync Environment (Python Packages Only) ---
FROM python:3.14-slim AS builder

WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
COPY pyproject.toml ./

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN uv venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN uv pip install .

# --- Stage 2: Final Published Core Runtime ---
FROM python:3.14-slim

WORKDIR /app

# Create a non-privileged system user and group
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -m -s /sbin/nologin appuser && \
    chown -R appuser:appgroup /app

# 1. Copy the pre-compiled virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 2. Install full-featured QSV binary and runtime utilities
COPY --from=qsv-source /usr/local/bin/qsv /usr/local/bin/qsv

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    libstdc++6 \
    && /usr/local/bin/qsv --version \
    && rm -rf /var/lib/apt/lists/*


# Clean environment baseline ready to be published