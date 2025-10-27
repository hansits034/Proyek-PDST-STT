# syntax=docker/dockerfile:1.6

# Base image with CUDA runtime and cuDNN to access NVIDIA L4 GPU on Cloud Run
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    # Allow pip to find CUDA-enabled wheels published by PyTorch
    PIP_EXTRA_INDEX_URL=https://download.pytorch.org/whl/cu124 \
    FFMPEG_BIN=/usr/bin/ffmpeg

# Install system dependencies and Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-venv \
        python3-pip \
        python3-dev \
        build-essential \
        wget \
        xz-utils \
        git \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install FFmpeg 7.1.1 static build (split RUN for better caching and error recovery)
RUN wget -v https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz -O /tmp/ffmpeg.tar.xz && \
    ls -lh /tmp/ffmpeg.tar.xz

RUN mkdir -p /opt/ffmpeg && \
    tar -xf /tmp/ffmpeg.tar.xz -C /opt/ffmpeg --strip-components=1 && \
    ls -lh /opt/ffmpeg/ffmpeg && \
    ln -sf /opt/ffmpeg/ffmpeg /usr/bin/ffmpeg && \
    ln -sf /opt/ffmpeg/ffprobe /usr/bin/ffprobe && \
    ffmpeg -version | head -1 && \
    rm -f /tmp/ffmpeg.tar.xz

# Ensure python command resolves to python3
RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

WORKDIR /app

# Only copy dependency manifests first for better layer caching
COPY requirements.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source (env and other local artefacts are excluded via .dockerignore)
COPY . .

# Expose the default Cloud Run port; actual value supplied via PORT env var
EXPOSE 8080

# Run the FastAPI app with uvicorn respecting the PORT provided by the platform
CMD ["/bin/bash", "-c", "uvicorn large-turbo:app --host 0.0.0.0 --port ${PORT:-8080} --timeout-keep-alive 90"]
