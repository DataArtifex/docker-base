# dartfx/docker-base

This repository contains the configuration for the base Docker image used by the **Data Artifex** platform. This image serves as the foundation for services, APIs, and other system components of the Data Artifex, providing a synchronized Python virtual environment and pre-installed system utilities.

## Architecture & Structure

The Docker image is built using a multi-stage `Dockerfile`:

1. **Builder Stage**: Builds and syncs the Python virtual environment using the [`uv`](https://github.com/astral-sh/uv) package manager. Dependencies are resolved from the `pyproject.toml` configuration.
2. **Final Runtime Stage**: Installs the high-performance [`qsv`](https://github.com/dathere/qsv) command-line tool (for CSV data-wrangling) and other essential system utilities, and copies the compiled Python virtual environment from the builder stage.

## Package Dependencies

The base environment includes several key components of the Data Artifex ecosystem:
- `dartfx-utils`
- `ddi-toolkit`
- `qsv-toolkit`
- `rdf-toolkit`
- `dartfx-unf`

These dependencies are managed via `pyproject.toml` and installed into `/opt/venv` within the container.

## Production Security Guidelines

To run containers built from these images securely in production, follow these key recommendations:

### 1. Run as a Non-Root User (Default Setup)
By default, Docker containers run as root, which presents a significant security risk. To mitigate this:
* This base image pre-creates a non-privileged system user: **`appuser`** (UID `10001`, GID `10001` under **`appgroup`**).
* **Inheritance & Build Design:** The user is defined in the base image so that all derived images inherit the user configuration automatically, ensuring consistency in UID/GID across all cluster services. However, the base image does *not* switch the active execution user (leaving it as `root`). This allows downstream Dockerfiles to run build-time commands (like `apt-get` or dependency installations) without needing to switch back and forth.
* Downstream runtime stages should use the `USER appuser` instruction to run final application processes as non-root.
* Ensure all copied application files in downstream stages use appropriate ownership, e.g., `COPY --chown=appuser:appgroup`.

### 2. Read-Only Root Filesystem
Configure your production orchestrator (e.g., Kubernetes or AWS ECS) to run containers with a read-only root filesystem (`readOnlyRootFilesystem: true` or `--read-only`). This prevents files from being modified or written to the container dynamically.
* If the application needs to write temporary files, mount a `tmpfs` volume or directory at `/tmp`.

### 3. Build Reproducibility & Base Image Pinning
While `python:3.14-slim` is clean, the underlying package versions may change during rebuilds.
* In production-bound builds, pin the base image to specific patch versions or, ideally, to their SHA256 digest:
  ```dockerfile
  FROM python:3.14.0-slim@sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  ```

### 4. Secrets Management
Never hardcode or build secrets (API keys, database passwords, SSL/TLS certificates) into the Docker image layers.
* Inject all credentials at runtime using environment variables managed by a secrets provider (e.g., Kubernetes Secrets, AWS Secrets Manager, HashiCorp Vault).

## Getting Started

### Building the Image

To build the Docker image locally, run:

```bash
docker build -t dartfx/docker-base:latest .
```

### Verifying the Image

A script is provided to verify that all system utilities (`curl`, `jq`, `qsv`) and Python packages are correctly installed and importable inside the built image.

To run the verification checks:

```bash
./verify_image.sh
```

### Entering the Container Shell

To debug or inspect the container environment, you can log into the container's shell.

#### Option A: Start a new container with an interactive shell
```bash
docker run --rm -it dartfx/docker-base:latest /bin/bash
```

#### Option B: Open a shell in an already running container
1. Find the running container's ID or name:
   ```bash
   docker ps
   ```
2. Exec into the container:
   ```bash
   docker exec -it <container_id_or_name> /bin/bash
   ```

### Publishing the Image

A utility script `publish_image.sh` is provided to automate tagging and pushing the image to Docker Hub (or another container registry). By default, the script:
1. Ensures the local image exists (builds it if not).
2. Verifies the image locally using `./verify_image.sh` to make sure all checks pass.
3. Extracts the version string from [pyproject.toml](file:///Users/pascal/Library/CloudStorage/Dropbox/git-dartfx/docker-base/pyproject.toml) (e.g. `0.1.0`).
4. Tags the image with both `latest` and the version tag.
5. Pushes the tagged images to the registry.

#### Prerequisites

Before running the script, ensure you are authenticated with Docker Hub (or your target container registry):

```bash
docker login
```

#### Usage Examples

To publish to the default namespace (`dartfx`):

```bash
./publish_image.sh
```

To publish to your own personal Docker Hub namespace or organization:

```bash
./publish_image.sh --namespace myusername
```

To push to an alternate registry (like GitHub Container Registry or AWS ECR):

```bash
./publish_image.sh --registry ghcr.io --namespace myorganization
```

#### Script Options

```
Options:
  -n, --namespace <name>  Docker Hub namespace/username (default: dartfx)
  -t, --tag <tag>          Additional custom tag to push
  -r, --registry <url>     Target container registry (default: docker.io)
  -s, --skip-verification  Skip running verify_image.sh before pushing
  -h, --help               Show usage help
```

## License

This project is licensed under the [MIT License](LICENSE).

