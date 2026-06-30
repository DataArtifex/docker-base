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

# 2. Install QSV and its bootstrap dependencies
# We use bash explicitly because the script uses double-bracket [[ ]] syntax
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    gnupg \
    jq \
    unzip \
    && arch=$(dpkg --print-architecture); \
    if [[ "$arch" == "amd64" ]]; then \
        wget -O - https://dathere.github.io/qsv-deb-releases/qsv-deb.gpg | gpg --dearmor -o /usr/share/keyrings/qsv-deb.gpg; \
        echo "deb [signed-by=/usr/share/keyrings/qsv-deb.gpg] https://dathere.github.io/qsv-deb-releases ./" > /etc/apt/sources.list.d/qsv.list; \
        apt-get update && apt-get install -y --no-install-recommends qsv; \
    elif [[ "$arch" == "arm64" ]]; then \
        version=$(curl -fsSL https://api.github.com/repos/dathere/qsv/releases/latest | jq -r '.tag_name'); \
        curl -fsSL "https://github.com/dathere/qsv/releases/download/${version}/qsv-${version}-aarch64-unknown-linux-gnu.zip" -o /tmp/qsv.zip; \
        unzip /tmp/qsv.zip -d /tmp/qsv; \
        install -m 0755 /tmp/qsv/qsv /usr/local/bin/qsv; \
        rm -rf /tmp/qsv /tmp/qsv.zip; \
    fi \
    && apt-get purge -y --auto-remove wget gnupg unzip \
    && rm -rf /var/lib/apt/lists/*

# Clean environment baseline ready to be published