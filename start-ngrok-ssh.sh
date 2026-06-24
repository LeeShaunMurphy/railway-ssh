#!/bin/bash
echo "=== Bắt đầu dịch vụ SSH ==="
service ssh start

if [ -z "$NGROK_AUTH_TOKEN" ]; then
  echo "⚠️  Không tìm thấy NGROK_AUTH_TOKEN!"
  exit 1
fi

ngrok config add-authtoken "$NGROK_AUTH_TOKEN"

echo "=== Khởi tạo Ngrok TCP tunnel ==="
nohup ngrok tcp 22 --region ap > ngrok.log 2>&1 &

# ✅ Chờ động thay vì sleep cố định
echo "Đang chờ Ngrok khởi động..."
for i in $(seq 1 20); do
  sleep 2
  TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['tunnels'][0]['public_url'])" 2>/dev/null)
  
  if [ -n "$TUNNEL_URL" ]; then
    break
  fi
  echo "  Thử lần $i/20..."
done

echo "=== Thông tin SSH ==="
if [ -n "$TUNNEL_URL" ]; then
  HOST=$(echo "$TUNNEL_URL" | sed 's#tcp://##' | cut -d: -f1)
  PORT=$(echo "$TUNNEL_URL" | sed 's#tcp://##' | cut -d: -f2)
  echo "✅ Tunnel: $TUNNEL_URL"
  echo "➡️  Lệnh SSH: ssh -p $PORT user@$HOST"
else
  echo "⚠️  Không lấy được tunnel. Nội dung ngrok.log:"
  cat ngrok.log
fi

echo "=== Giữ container hoạt động ==="
python3 -m http.server 8080
