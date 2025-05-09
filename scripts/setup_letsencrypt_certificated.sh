#!/bin/bash

# Configuramos para mostrar los comandos y finalizar si hay error
set -ex

# Importamos el archivo de variables
source .env

# El proveedor de donimnio sera no-ip

# Instalamos y actualizamos snap
snap install core
snap refresh core

# Eliminamos instalaciones previas de cerbot con apt
apt remove certbot -y -v

# Instalamos Certbot
snap install --classic certbot

# Solicitamos un cerficado a Let`s Encrypt
sudo certbot --nginx -m $LE_EMAIL --agree-tos --no-eff-email -d $LE_DOMAIN --non-interactive