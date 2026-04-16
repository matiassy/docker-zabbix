#!/usr/bin/env bash
set -euo pipefail

# ── Colores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Prerequisitos ─────────────────────────────────────────────────────────────
command -v docker >/dev/null 2>&1          || error "docker no está instalado."
docker compose version >/dev/null 2>&1    || error "docker compose (v2) no está disponible."

# ── Cargar .env ───────────────────────────────────────────────────────────────
[[ -f .env ]] || error "No se encontró .env en el directorio actual."
set -a; source .env; set +a

# ── [1/4] Levantar MySQL ──────────────────────────────────────────────────────
info "[1/4] Levantando MySQL..."
docker compose up -d mysql-server

# ── [2/4] Esperar MySQL (healthcheck) ─────────────────────────────────────────
info "[2/4] Esperando que MySQL esté listo..."
TIMEOUT=120
ELAPSED=0
until [ "$(docker inspect -f '{{.State.Health.Status}}' mysql-server 2>/dev/null)" = "healthy" ]; do
  if (( ELAPSED >= TIMEOUT )); then
    error "MySQL no alcanzó el estado healthy luego de ${TIMEOUT}s. Revisar: docker logs mysql-server"
  fi
  echo "  -> aún no listo, reintento en 5s... (${ELAPSED}s/${TIMEOUT}s)"
  sleep 5
  ELAPSED=$(( ELAPSED + 5 ))
done
info "MySQL listo."

# ── [3/4] Cargar esquema Zabbix (idempotente) ─────────────────────────────────
SCHEMA_LOADED=$(docker exec mysql-server mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
  -sN -e "SELECT COUNT(*) FROM information_schema.tables \
          WHERE table_schema='${MYSQL_DATABASE}' AND table_name='hosts';" 2>/dev/null || echo 0)

if [[ "${SCHEMA_LOADED}" -gt 0 ]]; then
  warn "[3/4] El esquema ya está cargado, omitiendo importación."
else
  info "[3/4] Cargando esquema Zabbix..."
  docker exec -i mysql-server mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" < 1-schema.sql
  docker exec -i mysql-server mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" < 2-images.sql
  docker exec -i mysql-server mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" < 3-data.sql
  info "Esquema importado correctamente."
fi

# ── [4/4] Levantar stack completo ─────────────────────────────────────────────
info "[4/4] Levantando el stack completo..."
docker compose up -d
info "Stack iniciado correctamente."
echo ""
echo -e "  Frontend Zabbix: ${GREEN}http://localhost:8081${NC}"
echo -e "  Usuario por defecto: Admin / zabbix"
