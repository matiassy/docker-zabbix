#!/usr/bin/env bash
set -euo pipefail

# Carga variables de .env en este shell
export $(grep -v '^#' .env | xargs)

echo "[1/4] Levantando MySQL..."
docker compose up -d mysql-server

echo "[2/4] Esperando MySQL (healthcheck)..."
# Espera al estado healthy (requiere el healthcheck del compose)
until [ "$(docker inspect -f '{{.State.Health.Status}}' mysql-server 2>/dev/null)" = "healthy" ]; do
  echo "  -> aún no listo, reintento en 5s..."
  sleep 5
done
echo "  -> MySQL listo."

echo "[3/4] Cargando esquema Zabbix..."
docker exec -i mysql-server mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < 1-schema.sql
docker exec -i mysql-server mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < 2-images.sql
docker exec -i mysql-server mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < 3-data.sql
echo "  -> Esquema importado."

echo "[4/4] Levantando el stack completo..."
docker compose up -d
echo "OK."
