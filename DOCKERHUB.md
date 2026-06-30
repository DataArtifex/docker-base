# dartfx/docker-base

`dartfx/docker-base` is the official core base Docker image for the **Data Artifex** platform. It provides a secure, high-performance runtime environment with pre-installed system utilities (such as `qsv`, `curl`, and `jq`) and a synchronized Python virtual environment containing the core Data Artifex libraries (`dartfx-utils`, `ddi-toolkit`, `qsv-toolkit`, `rdf-toolkit`, and `dartfx-unf`).

## Key Features

* **Python Virtual Environment**: Ready-to-use virtual environment located at `/opt/venv` (pre-configured in the `PATH`).
* **Core Data Artifex Packages**: Pre-installed ecosystem libraries: `dartfx-utils`, `ddi-toolkit`, `qsv-toolkit`, `rdf-toolkit`, and `dartfx-unf`.
* **System Utilities**: High-performance CSV-wrangling tool `qsv`, plus `curl`, `jq`, `unzip`, and certificates.
* **Security Defaults**:
  * Runs under a non-privileged system user: **`appuser`** (UID `10001`, GID `10001` under **`appgroup`**).
  * Optimized for read-only root filesystems (`--read-only`).

---

## How to Extend This Image

To build a new service on top of this base image, use a multi-stage Dockerfile that leverages `uv` to sync dependencies into the pre-existing virtual environment (`/opt/venv`).

### 1. Project Structure

Ensure your service has a `pyproject.toml` at its root:

```
my-service/
├── Dockerfile
├── pyproject.toml
└── src/
    └── my_service/
        ├── __init__.py
        └── main.py
```

### 2. Example `pyproject.toml`

Define your service metadata and dependencies:

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-service"
version = "0.1.0"
dependencies = [
    "httpx",
    "pydantic>=2.0"
]

[tool.hatch.metadata]
allow-direct-references = true

[tool.hatch.build.targets.wheel]
packages = ["src/my_service"]
```

### 3. Example `Dockerfile`

```dockerfile
# --- Builder Stage ---
FROM dartfx/docker-base:latest AS builder
WORKDIR /app

# Install uv for fast package management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copy project configuration files first to optimize layer caching
COPY pyproject.toml ./

# Install project dependencies into the virtual environment /opt/venv
RUN uv pip install --no-cache -r pyproject.toml

# Copy project source code
COPY . /app

# Install the project itself (without reinstalling dependencies)
RUN uv pip install --no-cache --no-deps .

# --- Runtime Stage ---
FROM dartfx/docker-base:latest
WORKDIR /app

# Copy the updated virtual environment and application code with proper ownership
COPY --from=builder --chown=appuser:appgroup /opt/venv /opt/venv
COPY --chown=appuser:appgroup . /app

# Run as the default non-root user
USER appuser

# Start your service entrypoint
CMD ["python", "-m", "my_service.main"]
```

---

## Quick Start (Testing the Base Image)

You can run the base image directly to check the Python environment:

```bash
docker run --rm dartfx/docker-base:latest python -c "import dartfx.utils; print('dartfx-utils imported successfully!')"
```

## Production Guidelines

1. **Read-Only Root Filesystem**: Configure your container orchestrator (e.g., Kubernetes or ECS) to run with a read-only root filesystem (`readOnlyRootFilesystem: true`). Mount a `tmpfs` volume at `/tmp` if your application needs to write temporary files.
2. **Pin Base Image Versions**: For production stability, pin the base image to a specific version tag or digest:
   ```dockerfile
   FROM dartfx/docker-base:0.1.0
   ```
3. **Secrets Management**: Never build secrets (API keys, database credentials) into your image layers. Always inject them at runtime via environment variables.
