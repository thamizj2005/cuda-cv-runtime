# 🏭 Industrial AI Bag Counting System — Docker Environment

> **Production-deployed computer vision system** at **Ramco Cements**, automating cement bag counting on conveyor lines using YOLOv8 segmentation, ByteTrack multi-object tracking, and Modbus TCP PLC integration.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Docker Image Details](#-docker-image-details)
- [Prerequisites](#-prerequisites)
- [Step-by-Step: Rebuild the Docker Image](#-step-by-step-rebuild-the-docker-image)
- [Running the Container](#-running-the-container)
- [Project Structure Inside Container](#-project-structure-inside-container)
- [Hardware Requirements](#-hardware-requirements)
- [Troubleshooting](#-troubleshooting)
- [Author](#-author)

---

## 🔍 Project Overview

This repository contains the complete Docker environment for an **industrial-grade AI vision system** deployed on the production floor at **Ramco Cements**. The system:

- **Counts cement bags** moving on conveyor belts in real time using a GPU-accelerated RTSP camera pipeline
- Feeds live counts directly into the **PLC via Modbus TCP** to synchronise plant operations
- Streams annotated video over **Flask MJPEG** for plant floor monitoring
- Presents operators with a **PyQt6 desktop dashboard** showing live counts, shift totals, and alerts
- Logs all count data to **MS SQL Server** for production reporting

The Docker image (`ai-cv:pyqt6-fixed`, 23.7 GB) encapsulates every dependency — CUDA 12.4, cuDNN 9, an OpenCV build compiled **from source with full CUDA support**, GStreamer, PyQt6, MS ODBC 18, and Ultralytics YOLOv8 — so the system runs identically across GPU workstations and edge servers.

---

## 🏗 System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Docker Container                              │
│                      (ai-cv:pyqt6-fixed)                            │
│                                                                     │
│  ┌──────────────┐     ┌───────────────────────────────────────┐     │
│  │  RTSP Camera │────▶│         Capture Thread                │     │
│  │  (IP Camera) │     │   GStreamer / OpenCV CUDA Pipeline     │     │
│  └──────────────┘     └──────────────────┬────────────────────┘     │
│                                          │                          │
│                              ┌───────────▼───────────┐             │
│                              │   YOLOv8 Segmentation  │             │
│                              │   (GPU Inference)      │             │
│                              └───────────┬───────────┘             │
│                                          │                          │
│                              ┌───────────▼───────────┐             │
│                              │  ByteTrack MOT Engine  │             │
│                              │  (Multi-Object Tracker)│             │
│                              └───┬───────────────┬───┘             │
│                                  │               │                  │
│               ┌──────────────────▼──┐    ┌───────▼──────────────┐  │
│               │  Modbus TCP Client  │    │  Flask MJPEG Stream  │  │
│               │  (PLC Integration)  │    │  (Operator Monitor)  │  │
│               └──────────────────┬──┘    └──────────────────────┘  │
│                                  │                                  │
│               ┌──────────────────▼──┐    ┌──────────────────────┐  │
│               │    MS SQL Server    │    │   PyQt6 Dashboard    │  │
│               │  (Production Logs)  │    │  (Operator Desktop)  │  │
│               └─────────────────────┘    └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🛠 Tech Stack

| Layer | Technology | Version / Notes |
|---|---|---|
| **Base Image** | NVIDIA CUDA | `12.4.1-devel-ubuntu22.04` |
| **Deep Learning Runtime** | cuDNN | 9.11.0 (CUDA 12 build) |
| **Computer Vision** | OpenCV | Built from source — CUDA + GStreamer + V4L2 |
| **Detection Model** | Ultralytics YOLOv8 | Segmentation head (`yolov8*-seg.pt`) |
| **Object Tracking** | ByteTrack | Multi-object tracking (MOT) |
| **Media Pipeline** | GStreamer 1.0 | Full plugin stack — base, good, bad, ugly, libav |
| **GUI Framework** | PyQt6 | `≥ 6.4.0` with full XCB / Qt6 platform plugin stack |
| **PLC Integration** | pymodbus | Modbus TCP client |
| **Database** | pyodbc + MS ODBC 18 | Microsoft SQL Server |
| **Video Streaming** | Flask | MJPEG stream server |
| **Language** | Python | 3.10 |
| **OS** | Ubuntu | 22.04 LTS |

---

## 🐳 Docker Image Details

| Property | Value |
|---|---|
| **Image name** | `ai-cv:pyqt6-fixed` |
| **Image ID** | `407a0a95806c` |
| **Compressed disk usage** | 23.7 GB |
| **Base** | `nvidia/cuda:12.4.1-devel-ubuntu22.04` |
| **Working directory** | `/home/aiadmin/AI_Counting` |
| **Default user** | `aiadmin` (UID 1000) |
| **Entrypoint** | `/usr/local/bin/user-entrypoint.sh` |

### Why is the image 23.7 GB?

The size comes from three compounding factors:

1. **CUDA 12.4 devel image** — the `-devel` variant ships the full CUDA toolkit, compiler (`nvcc`), headers, and static libraries (~8 GB).
2. **cuDNN 9 local install** — full cuDNN 9 runtime + dev libraries for CUDA 12 (~3 GB).
3. **OpenCV compiled from source** — building OpenCV with `WITH_CUDA=ON`, `opencv_contrib`, GStreamer, and V4L2 generates large intermediate objects that are not fully purged (~4 GB residual).

> **Tip for size reduction:** Switch the base to `nvidia/cuda:12.4.1-runtime-ubuntu22.04` and use a multi-stage build to copy only compiled `.so` files into the final image. This can bring the image below 10 GB.

---

## ✅ Prerequisites

Before building, confirm your host machine meets **every** requirement below.

### 1. Hardware

- **GPU:** NVIDIA GPU with Compute Capability ≥ 7.0 (RTX 2000 series or newer recommended)
- **VRAM:** ≥ 6 GB (8 GB+ for comfortable real-time inference)
- **RAM:** ≥ 16 GB system RAM
- **Storage:** ≥ 40 GB free (25 GB for the image + build workspace)

### 2. Host Driver

```bash
# Verify NVIDIA driver is installed
nvidia-smi

# Minimum driver version for CUDA 12.4
# Driver ≥ 550.54.15 (Linux)
```

### 3. Software

```bash
# Docker Engine (≥ 24.x)
docker --version

# NVIDIA Container Toolkit
nvidia-ctk --version   # Must be installed for GPU passthrough

# Git
git --version
```

**Install NVIDIA Container Toolkit (Ubuntu):**

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

**Verify GPU passthrough works:**

```bash
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

---

## 🔨 Step-by-Step: Rebuild the Docker Image

> **Build time:** 45–90 minutes depending on CPU core count (OpenCV compilation dominates).

### Step 1 — Clone this repository

```bash
git clone https://github.com/<your-username>/ramco-ai-bag-counting.git
cd ramco-ai-bag-counting
```

### Step 2 — Download the cuDNN 9 local `.deb` package

The build requires the cuDNN 9.11.0 local installer for Ubuntu 24.04 (the package naming is `ubuntu2404` but it works on Ubuntu 22.04 inside the container).

1. Go to: [https://developer.nvidia.com/cudnn-downloads](https://developer.nvidia.com/cudnn-downloads)
2. Select:
   - **Operating System:** Linux
   - **Architecture:** x86_64
   - **Distribution:** Ubuntu
   - **Version:** 24.04
   - **Installer Type:** deb (local)
3. Download the file — it will be named:
   ```
   cudnn-local-repo-ubuntu2404-9.11.0_1.0-1_amd64.deb
   ```
4. Place it in the **root of the build context** (same directory as the `Dockerfile`):

```
ramco-ai-bag-counting/
├── Dockerfile
├── cudnn-local-repo-ubuntu2404-9.11.0_1.0-1_amd64.deb   ← place here
├── requirements.txt
├── entrypoint/
│   └── user-entrypoint.sh
└── README.md
```

> **File size warning:** The `.deb` is approximately 1.5–2 GB. Do not commit it to Git. It is listed in `.gitignore`.

### Step 3 — Create the `requirements.txt`

Create a `requirements.txt` in the build context. Below is the recommended set for this project:

```text
# ── Core Inference ──────────────────────────────────────────────────
ultralytics>=8.2.0          # YOLOv8 — detection + segmentation
supervision>=0.21.0         # ByteTrack wrapper + annotation utilities

# ── PLC / Industrial ────────────────────────────────────────────────
pymodbus>=3.6.0             # Modbus TCP client

# ── Database ────────────────────────────────────────────────────────
pyodbc>=5.1.0               # MS SQL Server via ODBC 18

# ── Web / Streaming ─────────────────────────────────────────────────
Flask>=3.0.0
Werkzeug>=3.0.0

# ── Data & Utilities ────────────────────────────────────────────────
numpy>=1.26.0
Pillow>=10.3.0
scipy>=1.13.0
pandas>=2.2.0
matplotlib>=3.8.0
PyYAML>=6.0
tqdm>=4.66.0
psutil>=5.9.0

# ── Tracking (ByteTrack direct, if not using supervision) ───────────
# lap>=0.5.12               # Already installed in Dockerfile Stage 6
```

> Adjust versions to match your exact deployment. The `lap` package is pre-installed directly in the Dockerfile (Stage 6) to avoid build issues.

### Step 4 — Create the user entrypoint script

Create the file `entrypoint/user-entrypoint.sh`:

```bash
#!/bin/bash
# user-entrypoint.sh — wraps the system entrypoint with display fixes

export XDG_RUNTIME_DIR=/tmp/runtime-root
export QT_X11_NO_MITSHM=1
export QT_QPA_PLATFORM=xcb
export DISPLAY=${DISPLAY:-:0}

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

exec "$@"
```

Add this `COPY` instruction to Stage 7 of the Dockerfile (before the `USER 1000:1000` line), or copy it into the container manually:

```dockerfile
COPY entrypoint/user-entrypoint.sh /usr/local/bin/user-entrypoint.sh
RUN chmod +x /usr/local/bin/user-entrypoint.sh
```

### Step 5 — Verify your build context

```
ramco-ai-bag-counting/
├── Dockerfile
├── cudnn-local-repo-ubuntu2404-9.11.0_1.0-1_amd64.deb
├── requirements.txt
├── entrypoint/
│   └── user-entrypoint.sh
├── .dockerignore
├── .gitignore
└── README.md
```

### Step 6 — Build the image

```bash
# Standard build (uses all available CPU cores for OpenCV compilation)
docker build \
    --tag ai-cv:pyqt6-fixed \
    --progress=plain \
    .
```

**Recommended: Build with BuildKit for better caching**

```bash
DOCKER_BUILDKIT=1 docker build \
    --tag ai-cv:pyqt6-fixed \
    --progress=plain \
    .
```

> **Tip:** Stage 4 (OpenCV compilation) runs `make -j$(nproc)` — it will saturate all CPU cores and typically takes 30–60 minutes alone.

### Step 7 — Verify the build

```bash
# Check image is present
docker images ai-cv:pyqt6-fixed

# Verify CUDA is accessible inside the container
docker run --rm --gpus all ai-cv:pyqt6-fixed \
    bash -c "python3 -c \"import cv2; print('OpenCV:', cv2.__version__); print('CUDA devices:', cv2.cuda.getCudaEnabledDeviceCount())\""

# Expected output:
# OpenCV: 4.x.x
# CUDA devices: 1
```

---

## ▶ Running the Container

### Basic interactive shell

```bash
docker run -it --rm \
    --gpus all \
    --network host \
    --env DISPLAY=$DISPLAY \
    --volume /tmp/.X11-unix:/tmp/.X11-unix:rw \
    ai-cv:pyqt6-fixed \
    bash
```

### Run with project code mounted from host

```bash
docker run -it --rm \
    --gpus all \
    --network host \
    --env DISPLAY=$DISPLAY \
    --volume /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --volume /path/to/your/AI_Counting:/home/aiadmin/AI_Counting \
    ai-cv:pyqt6-fixed \
    bash
```

### Run the PyQt6 dashboard (requires X11 forwarding)

```bash
# Allow the container to connect to your host X server
xhost +local:docker

docker run -it \
    --gpus all \
    --network host \
    --env DISPLAY=$DISPLAY \
    --env QT_QPA_PLATFORM=xcb \
    --volume /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --volume /path/to/your/AI_Counting:/home/aiadmin/AI_Counting \
    ai-cv:pyqt6-fixed \
    python3 optical_flow/main.py

# Revoke X access when done
xhost -local:docker
```

### Using Docker Compose

```yaml
# docker-compose.yml
version: "3.9"
services:
  bag-counter:
    image: ai-cv:pyqt6-fixed
    runtime: nvidia
    network_mode: host
    environment:
      - DISPLAY=${DISPLAY}
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility,video,display
      - QT_QPA_PLATFORM=xcb
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - ./AI_Counting:/home/aiadmin/AI_Counting
    restart: unless-stopped
    command: python3 optical_flow/main.py
```

```bash
xhost +local:docker
docker compose up
```

---

## 📁 Project Structure Inside Container

```
/home/aiadmin/
└── AI_Counting/
    ├── optical_flow/           ← Main application entry point
    │   ├── main.py             ← PyQt6 dashboard launcher
    │   ├── counter.py          ← YOLOv8 + ByteTrack counting logic
    │   ├── rtsp_pipeline.py    ← Multi-threaded RTSP capture (GStreamer)
    │   ├── modbus_client.py    ← PLC Modbus TCP interface
    │   ├── flask_stream.py     ← MJPEG video stream server
    │   └── db_logger.py        ← SQL Server logging via pyodbc
    ├── models/
    │   └── *.pt                ← YOLOv8 segmentation model weights
    ├── config/
    │   └── config.yaml         ← Camera IP, PLC IP, DB connection string
    └── logs/
        └── *.log               ← Runtime logs

/opt/ultralytics/               ← Ultralytics config (root-owned)
/home/aiadmin/.ultralytics/     ← Ultralytics user config (UID 1000)
```

---

## 💻 Hardware Requirements

| Component | Minimum | Recommended (Production) |
|---|---|---|
| **GPU** | GTX 1660 (6 GB VRAM) | RTX 3060 / RTX 4060 (8 GB+) |
| **CPU** | 4-core i5 / Ryzen 5 | 8-core i7 / Ryzen 7 |
| **RAM** | 16 GB | 32 GB |
| **Storage** | 50 GB SSD | 100 GB NVMe SSD |
| **Network** | Gigabit Ethernet (for RTSP) | Gigabit Ethernet |
| **NVIDIA Driver** | ≥ 550.54.15 | Latest stable |
| **OS** | Ubuntu 20.04 / 22.04 | Ubuntu 22.04 LTS |

---

## 🔧 Troubleshooting

### `cannot connect to X server` — PyQt6 dashboard does not open

```bash
# On the host, grant Docker access to X11
xhost +local:docker

# Verify DISPLAY is passed correctly
echo $DISPLAY        # Should output :0 or :1

# Set explicitly if empty
export DISPLAY=:0
```

### `qt.qpa.plugin: Could not load the Qt platform plugin "xcb"`

All required XCB libraries are installed in Stage 8 of the Dockerfile. If you still see this error, verify the container is built from the full Dockerfile (all 9 stages):

```bash
docker run --rm ai-cv:pyqt6-fixed \
    python3 -c "from PyQt6.QtWidgets import QApplication; print('PyQt6 OK')"
```

### `CUDA out of memory` during inference

Reduce the inference batch size or input resolution in `config/config.yaml`:

```yaml
model:
  imgsz: 640       # reduce to 480 or 320
  batch: 1
```

### OpenCV cannot open RTSP stream (`Error -215`)

```bash
# Verify GStreamer pipeline can decode the stream on the host
gst-launch-1.0 rtspsrc location=rtsp://<camera-ip>/stream ! decodebin ! autovideosink

# Test inside the container
docker run -it --gpus all --network host ai-cv:pyqt6-fixed \
    python3 -c "import cv2; cap = cv2.VideoCapture('rtsp://<camera-ip>/stream'); print(cap.isOpened())"
```

### Modbus TCP connection refused

```bash
# Confirm the PLC IP is reachable from inside the container (--network host required)
docker run --rm --network host ai-cv:pyqt6-fixed \
    bash -c "apt-get install -y iputils-ping -qq && ping -c 3 <plc-ip>"
```

### cuDNN `.deb` not found during build

The file **must** be named exactly:
```
cudnn-local-repo-ubuntu2404-9.11.0_1.0-1_amd64.deb
```
and placed in the **same directory** as the `Dockerfile`. Verify:
```bash
ls -lh cudnn-local-repo-ubuntu2404-9.11.0_1.0-1_amd64.deb
```

---

## 💾 Transferring the Pre-built Image (Instead of Rebuilding)

If you have access to the original pre-built image, you can export and import it without rebuilding:

```bash
# On the source machine — save image to a compressed archive
docker save ai-cv:pyqt6-fixed | gzip > ai-cv-pyqt6-fixed.tar.gz
# (~10–12 GB compressed, from 23.7 GB image)

# Transfer to target machine (e.g., via scp)
scp ai-cv-pyqt6-fixed.tar.gz user@target-machine:/home/user/

# On the target machine — load the image
docker load < ai-cv-pyqt6-fixed.tar.gz

# Verify
docker images ai-cv:pyqt6-fixed
```

---

## 🗂 Supporting Files

### `.dockerignore`

```
.git
*.md
*.tar.gz
*.log
__pycache__
*.pyc
*.pyo
AI_Counting/
models/
logs/
```

### `.gitignore`

```
# cuDNN installer (too large for Git)
*.deb

# Model weights
*.pt
*.pth
*.onnx

# Logs and runtime artifacts
logs/
*.log
__pycache__/
*.pyc

# Docker exports
*.tar
*.tar.gz

# IDE
.vscode/
.idea/
```

---

## 👤 Author

**Thamizh Selvan G**

AI & Computer Vision Engineer

Interests:
- Computer Vision
- Industrial AI
- Edge AI Deployment
- Machine Learning Systems

🔗 LinkedIn: https://linkedin.com/in/thamizh-ai
🔗 Hugging Face: https://huggingface.co/thamizhg


## 📄 License

This project is deployed in a production industrial environment at Ramco Cements. Source code is proprietary. The Docker environment configuration in this repository is shared for reference and educational purposes.
