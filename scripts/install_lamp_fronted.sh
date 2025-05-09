#!/bin/bash
# Configuramos para mostrar los comandos y finalizar si hay error
set -ex
# Actualizamos los repositorios
apt update
# Actualizamos los paquetes
apt upgrade -y
# Instalamos el servidor web Apache
apt install apache2 -y
# Habilitamos un módulo rewrite
a2enmod rewrite
#Copiamos el arhcivo de configuracion de Apache
cp ../conf/000-default.conf /etc/apache2/sites-available
#Instalamos PHP y algunos modulos de PHP para Apache y MySQL
apt install php libapache2-mod-php php-mysql -y
#Reiniciamos el servicio de Apache
systemctl restart apache2
#Copiamos el script de prueba de PHP en /var/www/html
cp ../php/index.php /var/www/html
#Modificar el propietario y el grupo
chown -R www-data:www-data /var/www/html