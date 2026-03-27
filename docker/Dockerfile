FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime deps: Xvfb, x11vnc, fonts, curl, ca-certificates, supervisor
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     ca-certificates curl wget gnupg2 ca-certificates tzdata \
     xvfb x11vnc fluxbox x11-utils \
     fonts-noto-cjk fontconfig \
     python3 python3-pip nodejs npm \
     net-tools procps socat \
  && rm -rf /var/lib/apt/lists/*

# Install Chromium (snap not suitable in container) — use chromium-browser from apt
RUN apt-get update && apt-get install -y --no-install-recommends chromium-browser || true && rm -rf /var/lib/apt/lists/*

# Optional: install noVNC/websockify via pip for simplicity
RUN pip3 install websockify

# Create app directory
WORKDIR /opt/headful-browser-vnc
COPY . /opt/headful-browser-vnc

# Expose common ports (VNC, devtools)
EXPOSE 5900 5901 9222 6080

# Default env
ENV VNC_DISPLAY=:99 \
    VNC_RESOLUTION=1366x768 \
    REMOTE_DEBUG_PORT=9222 \
    VNC_PASSFILE=/root/.vnc/passwd \
    VNC_IMPLEMENTATION=auto

# Entrypoint: start VNC and keep container running; user overrides recommended via docker-compose
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["debug",":99","1366x768"]
