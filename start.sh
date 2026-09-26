#!/usr/bin/env bash
set -u
echo ">>> [1/4] SSH"
mkdir -p /root/.ssh /run/sshd
PUBLIC_KEY="${PUBLIC_KEY:-}"; PUBLIC_KEY="${PUBLIC_KEY//\"/}"   # strip quotes some sites add
if [ -n "$PUBLIC_KEY" ]; then
  echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
  chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys
fi
/usr/sbin/sshd || true
# make R2_BUCKET / MODELS visible in SSH sessions (they don't inherit the container env)
for v in R2_BUCKET MODELS; do
  if [ -n "${!v:-}" ]; then
    echo "$v=${!v}" >> /etc/environment
    echo "export $v=\"${!v}\"" >> /root/.bashrc
  fi
done
echo "PATH=$PATH" >> /etc/environment
echo "export PATH=\"$PATH\"" >> /root/.bashrc
echo ">>> [2/4] Configuring rclone for R2"
mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf <<EOC
[r2]
type = s3
provider = Cloudflare
access_key_id = ${R2_ACCESS_KEY:-}
secret_access_key = ${R2_SECRET_KEY:-}
endpoint = https://${R2_ACCOUNT_ID:-}.r2.cloudflarestorage.com
acl = private
no_check_bucket = true
EOC
install -m 0755 /app/getmodel.sh /usr/local/bin/getmodel 2>/dev/null || true
install -m 0755 /app/addmodel.sh /usr/local/bin/addmodel 2>/dev/null || true
if rclone lsf "r2:${R2_BUCKET:-}" --max-depth 1 >/dev/null 2>&1; then
  echo "    R2 connection OK (bucket: ${R2_BUCKET:-})"
else
  echo "    !! R2 connection FAILED - check R2_ACCESS_KEY / R2_SECRET_KEY / R2_ACCOUNT_ID / R2_BUCKET"
fi
echo ">>> [3/4] Models"
if [ -n "${MODELS:-}" ]; then
  echo "    auto-loading: ${MODELS}"
  /app/getmodel.sh ${MODELS} || echo "    (some bundles failed)"
else
  echo "    booting empty (fast). Load one with:  getmodel <name>"
fi
echo ">>> [4/4] Starting ComfyUI on :8188"
cd /app/ComfyUI
exec python main.py --listen 0.0.0.0 --port 8188
