# AGENTS INSTRUCTIONS

This project builds a base Docker image for the Data Artifex.
This image is intended to be used as a base image for other Docker images that will be used to run API,
services, and other components of the Data Artifex.

## Dockerfile Structure

The Dockerfile is divided into two stages:

1. **Builder Stage**: This stage is used to build and sync the Python virtual environment.
2. **Final Runtime Stage**: This stage is used to install the QSV binary and other system utilities.

## Python Packages

The Python packages are defined in the `pyproject.toml` file. The `uv` tool is used to build and sync the Python virtual environment.
