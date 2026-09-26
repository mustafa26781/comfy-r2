FROM pytorch/pytorch:2.8.0-cuda12.8-cudnn9-runtime
ENV DEBIAN_FRONTEND=noninteractive PYTHONUNBUFFERED=1
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl unzip zstd ffmpeg openssh-server \
    libx11-6 libgl1 libglib2.0-0 libegl1 libgles2 \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rc.zip \
 && unzip -q /tmp/rc.zip -d /tmp/rc \
 && install -m 0755 /tmp/rc/rclone-*-linux-amd64/rclone /usr/bin/rclone \
 && rm -rf /tmp/rc /tmp/rc.zip && rclone version
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI /app/ComfyUI \
 && pip install --no-cache-dir -r /app/ComfyUI/requirements.txt \
 && pip install --no-cache-dir "huggingface_hub[cli]"
COPY start.sh addmodel.sh getmodel.sh /app/
RUN chmod +x /app/start.sh /app/addmodel.sh /app/getmodel.sh
EXPOSE 8188 22
CMD ["/app/start.sh"]
