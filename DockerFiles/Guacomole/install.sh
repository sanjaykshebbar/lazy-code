#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/sanjaykshebbar/lazy-code.git"
INSTALL_DIR="/opt/guacamole"

echo "[1/7] Checking dependencies..."

if ! command -v docker >/dev/null 2>&1; then
echo "Docker is not installed."
exit 1
fi

if docker compose version >/dev/null 2>&1; then
COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
COMPOSE="docker-compose"
else
echo "Docker Compose not found."
exit 1
fi

echo "[2/7] Installing files..."

rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR"

cd "$INSTALL_DIR"

echo "[3/7] Starting MySQL..."

$COMPOSE up -d mysql

echo "[4/7] Waiting for MySQL..."

until docker exec guac-mysql mysqladmin ping -uroot -prootpassword --silent >/dev/null 2>&1
do
sleep 5
done

echo "[5/7] Initializing Guacamole schema..."

docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql

docker exec -i guac-mysql mysql 
-uroot 
-prootpassword 
guacamole_db < initdb.sql || true

echo "[6/7] Starting Guacamole..."

$COMPOSE up -d guacamole

sleep 20

echo "[7/7] Setting admin password..."

docker exec guac-mysql mysql 
-uroot 
-prootpassword 
guacamole_db <<'EOF'
UPDATE guacamole_user
SET password_hash = UNHEX(SHA2('Password123',256)),
password_salt = NULL
WHERE username='guacadmin';
EOF

PUBLIC_IP=$(curl -s https://api.ipify.org || echo "SERVER_IP")

echo
echo "=========================================="
echo "Guacamole Installed"
echo "URL: http://${PUBLIC_IP}:8080/guacamole"
echo "Username: guacadmin"
echo "Password: Password123"
echo "=========================================="
