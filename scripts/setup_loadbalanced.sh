#!/bin/bash

#Comando para ver la ejecucion y  si hay fallo pare
set -ex

#Usamos nuestro archivo de variables
source .env

# Actualizamos

apt update
apt upgrade -y
#instalaccion de Nginx
sudo apt install nginx -y

# # vamos a deshabilitar el sitio por defecto eliminando el enlace simbólico:
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    unlink /etc/nginx/sites-enabled/default
fi

#Colocamos el archivo balanceador en la carpeta de sitios disponibles
cp ../conf/load-balancer.conf /etc/nginx/sites-available/

# Cambiamos los valores de IP_FRONTEND 
sed -i "s/IP_FRONTEND_1/$FRONTEND_IP/" /etc/nginx/sites-available/load-balancer.conf
sed -i "s/IP_FRONTEND_2/$FRONTEND_IP2/" /etc/nginx/sites-available/load-balancer.conf
sed -i "s/LE_DOMAIN/$LE_DOMAIN/" /etc/nginx/sites-available/load-balancer.conf

# Habilitamos el virtual host del balanceador de carga
if [ ! -f "/etc/nginx/sites-enabled/default" ]; then
    ln -s /etc/nginx/sites-available/load-balancer.conf /etc/nginx/sites-enabled/
fi

# Recargue la configuración de Nginx.
sudo systemctl reload nginx
