#!/bin/bash

# Configuramos para mostrar los comandos y finalizar si hay error
set -ex

# Importamos el archivo de variables
source .env

# Borramos intalaciones previas
rm -rf /tmp/wp-cli.phar*

# Descargamos el WP-CLI , tambien se puede descargar con curl -o, la ruta /opt como lo vamos a usar mas de una vez , en caso de usarlo solo una vez es mejor en /tmp
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp

# Le asignamos permisos de ejesucuion
chmod +x /tmp/wp-cli.phar

# Lo movemos con en los comandos locales /usr/local/bin y le asignamos un nombre mas corto, asi no tenemos que poner toda la ruta /tmp/wp-cli.phar
mv /tmp/wp-cli.phar /usr/local/bin/wp

rm -rf $WORDPRESS_DIRECTORY/*

# Instalamos el codigo fuente, en español , en la ruta /var/www/html , y que se pueda ejercutar como root
wp core download --locale=es_ES --path=$WORDPRESS_DIRECTORY --allow-root

# Creamos el archivo de configuracion
wp config create --dbname=$WORDPRESS_DB_NAME --dbuser=$WORDPRESS_DB_USER --dbpass=$WORDPRESS_DB_PASSWORD --dbhost=$BACKEND_IP --path=$WORDPRESS_DIRECTORY --allow-root

# Instalamos el Worpres con el titulo y el usuario
wp core install --url=$LE_DOMAIN --title=$WORDPRESS_TITULO --admin_user=$WORDPRESS_USER --admin_password=$WORDPRESS_PASSWORD --admin_email=$LE_EMAIL --path=$WORDPRESS_DIRECTORY --allow-root  

# Cambiamos los permisos de root a www-data
chown www-data:www-data /var/www/html/*

# Instalamos un tema
wp theme install mindscape --activate --path=$WORDPRESS_DIRECTORY --allow-root

# Configuramos los enlaces 
wp rewrite structure '/%postname%/' --path=$WORDPRESS_DIRECTORY --allow-root

# Instalamos un plugin para que oculte el inicio de sesion
wp plugin install wps-hide-login --activate --path=$WORDPRESS_DIRECTORY --allow-root

# Configuramos el plugin 
wp option update whl_page "$WORDPRESS_HIDE_LOGIN_URL" --path=$WORDPRESS_DIRECTORY --allow-root

# Copiamos el archivo .htaccess
cp ../htaccess/.htaccess $WORDPRESS_DIRECTORY

# Cambiamos los permisos de root a www-data
chown www-data:www-data /var/www/html/*