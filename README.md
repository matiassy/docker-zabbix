# docker-zabbix
docker para zabbix 7.0.18

# Descargar y ejecutar:
git clone https://github.com/matiassy/docker-zabbix.git && ./install_zabbix-sh

# Ejecución manual
## levanta solo mysql
docker compose up -d mysql-server 

## Restaura estructura DBs
```bash
docker exec -i mysql-server mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < 1-schema.sql
docker exec -i mysql-server mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < 2-images.sql
docker exec -i mysql-server mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < 3-data.sql
```

## Levanta el resto de contenedores
docker compose up -d
