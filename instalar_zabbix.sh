#!/bin/bash

# Paso 1: Iniciar solo el servicio de MySQL
echo "Iniciando el servicio de MySQL..."
docker-compose up -d mysql-server

# Esperar a que la base de datos esté lista
echo "Esperando a que MySQL esté listo..."
until docker exec -i mysql-server mysql -u root -proot -e "SELECT 1" > /dev/null 2>&1; do
    echo "MySQL no está listo, esperando 5 segundos..."
    sleep 5
done
echo "MySQL está listo."

# Paso 2: Restaurar las bases de datos
echo "Restaurando las bases de datos..."
docker exec -i mysql-server mysql -u root -proot zabbix < 1-schema.sql
docker exec -i mysql-server mysql -u root -proot zabbix < 2-images.sql
docker exec -i mysql-server mysql -u root -proot zabbix < 3-data.sql
echo "Bases de datos restauradas."

# Paso 3: Levantar el resto de los servicios
echo "Levantando el resto de los servicios de Zabbix..."
docker-compose up -d
echo "Todos los servicios de Zabbix están en funcionamiento."

# Fin del script
echo "Proceso completado con éxito."
