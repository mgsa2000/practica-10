#!/bin/bash

#Cogemos las variables

source .env

# Configuramos para mostrar los comandos y finalizar si hay error

set -ex
# Actualizamos los repositorios

apt update
# Actualizamos los paquetes

apt upgrade -y

#Instalamos MySQL Server

apt install mysql-server -y

# Configuramos el archivo etc/mysql
sed -i "s/127.0.0.1/$BACKEND_IP/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Reiniciamos mysql para que se haga los cambios
sudo systemctl restart mysql