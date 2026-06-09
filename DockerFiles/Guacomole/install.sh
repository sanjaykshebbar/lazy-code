#!/usr/bin/env bash

set -euo pipefail

COMPOSE_URL="https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/refs/heads/main/DockerFiles/Guacomole/docker-compose.yml"

INSTALL_DIR="/opt/guacamole"

echo "[1/9] Checking Docker..."

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

echo "[2/9] Creating install directory..."

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "[3/9] Downloading docker-compose.yml..."

curl -fsSL "$COMPOSE_URL" -o docker-compose.yml

echo "[4/9] Pulling required images..."

docker pull guacamole/guacamole:latest
docker pull mysql:8.0

echo "[5/9] Starting MySQL..."

$COMPOSE up -d mysql

echo "[6/9] Waiting for MySQL..."

until docker exec guac-mysql mysqladmin ping -uroot -prootpassword --silent >/dev/null 2>&1
do
sleep 5
done

echo "[7/9] Initializing Guacamole schema..."

docker run --rm 
guacamole/guacamole 
/opt/guacamole/bin/initdb.sh --mysql > initdb.sql

docker exec -i guac-mysql 
mysql -uroot -prootpassword guacamole_db < initdb.sql || true

echo "[8/9] Starting Guacamole..."

$COMPOSE up -d guacamole

echo "Waiting for Guacamole startup..."
sleep 20

echo "[9/9] Setting admin password..."

docker exec guac-mysql mysql 
-uroot 
-prootpassword 
guacamole_db <<'EOF'
UPDATE guacamole_user
SET password_hash = UNHEX(SHA2('Password123',256)),
password_salt = NULL
WHERE username='guacadmin';
EOF

IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')

echo
echo "========================================"
echo "Guacamole installed successfully"
echo "URL      : http://${IP}:8080/guacamole"
echo "Username : guacadmin"
echo "Password : Password123"
echo "========================================"
