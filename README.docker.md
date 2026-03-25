Running headful-browser-vnc in Docker

This repository includes a reference Dockerfile and docker-compose.yml to run the skill in a containerized environment. The container bundles Xvfb, x11vnc, Chromium, and helper scripts so the runtime behaves consistently across hosts that support Docker.

Quickstart (build + run):

1) Build the image (from skills/headful-browser-vnc/docker):
   docker build -t headful-browser-vnc:latest .

2) Create a skill-local .env next to the repo (or mount one). Minimal example:
   VNC_PASSFILE=/tmp/vnc/passwd
   VNC_DISPLAY=:99
   VNC_RESOLUTION=1366x768
   REMOTE_DEBUG_PORT=9222

3) Run with docker-compose (binds ports 5900, 9222)
   docker-compose up --build -d

Notes and security
- Exposing the container's VNC port to the network is risky. Prefer SSH port forwarding into the host or limit docker-compose ports to localhost (127.0.0.1:5900:5900) where possible.
- For production, run as a non-root user inside container and bind mount an artifacts directory for persistence.
- The Dockerfile provided is a reference and intentionally permissive; create hardened images for production use.

If you want I can refine the Dockerfile (smaller base image, install Google Chrome .deb instead of apt chromium, add non-root user) — reply make-docker-refine.
