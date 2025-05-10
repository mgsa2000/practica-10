# practica-10 Balanceador de carga con Nginx
En esta práctica  vamos a realizar la  implatacion a dos niveles utilizando un frontend y un backend y vamos a realizar un balanceador de carga utilizando el servidor nginx en vez de apache.El balanceador,se encargará de redireccionar al cliente a la ip del frontal más eficiente. 
Como siempre,emplearemos un archivo .env,un 000-default y load_balancer.conf

Como es de esperar, usaremos 4 máquinas. Una máquina backend que la usaremos para guardar nuestra base de datos mysql, dos maquinas frontend que utilizaremos para que el balanceador de carga vaya cambiando entre las dos y asi haya menos saturacion de tráfico en la red y una máquina que sera nuestro balanceador de cargar.

Vamos a realizar lo siguientes pasos para la correcta instalación:
## Maquina backend : Instalacion de Mysql
Primero en la maquina backend instalaremos el lamp de la siguiente manera:

Cogemos las variables

```bash
source .env
```
Configuramos para mostrar los comandos y finalizar si hay error

```bash
set -ex
```
Actualizamos los repositorios

```bash
apt update
```
Actualizamos los paquetes

```bash
apt upgrade -y
```
Instalamos MySQL Server

```bash
apt install mysql-server -y
```
La diferencia de este lamp es que modificaremos las direccion de la  interfaz de red del servidor de MySQL se van a permitir conexiones

```bash
sed -i "s/127.0.0.1/$BACKEND_IP/" /etc/mysql/mysql.conf.d/mysqld.cnf
```

Reiniciamos mysql para que se haga los cambios
```bash
sudo systemctl restart mysql
```
Una vez  instalada, vamos a generar un deploy para mysql creando la base de datos y dandole permisos a los usuarios
Configuramos para mostrar los comandos y finalizar si hay error

```bash
set -ex
```
Importamos el archivo de variables

```bash
source .env
```
Creamos  la base de datos de usuario

```bash
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$FRONTEND_IP"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$FRONTEND_IP IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$FRONTEND_IP"
```
Con esto ya tendriamos configurada la maquina backend. ahora procedemos a instarlar y configurar la maquina frontend

## Máquinas frontend : Instalacion de Apache y Wordpress
### Instalamos Apache

Configuramos para mostrar los comandos y finalizar si hay error
```bash
set -ex
```
Actualizamos los repositorios
```bash
apt update
```
Actualizamos los paquetes
```bash
apt upgrade -y
```
Instalamos el servidor web Apache
```bash
apt install apache2 -y
```
Habilitamos un módulo rewrite
```bash
a2enmod rewrite
```
Copiamos el arhcivo de configuracion de Apache
```bash
cp ../conf/000-default.conf /etc/apache2/sites-available
```
Instalamos PHP y algunos modulos de PHP para Apache y MySQL
```bash
apt install php libapache2-mod-php php-mysql -y
```
Reiniciamos el servicio de Apache
```bash
systemctl restart apache2
```
Copiamos el script de prueba de PHP en /var/www/html
```bash
cp ../php/index.php /var/www/html
```
Modificar el propietario y el grupo
```bash
chown -R www-data:www-data /var/www/html
```
Ahora lanzamos el script deploy para instalar wordpress.

## Wordpress

Configuramos para mostrar los comandos y finalizar si hay error
```bash
set -ex
```
Importamos el archivo de variables
```bash
source .env
```
Borramos intalaciones previas

```bash
rm -rf /tmp/wp-cli.phar*
```
Descargamos el WP-CLI , tambien se puede descargar con curl -o, la ruta /opt como lo vamos a usar mas de una vez , en caso de usarlo solo una vez es mejor en /tmp

```bash
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp
```
Le asignamos permisos de ejecucion

```bash
chmod +x /tmp/wp-cli.phar
```

Lo movemos con en los comandos locales /usr/local/bin y le asignamos un nombre mas corto, asi no tenemos que poner toda la ruta /tmp/wp-cli.phar

```bash
mv /tmp/wp-cli.phar /usr/local/bin/wp

rm -rf $WORDPRESS_DIRECTORY/*
```
Instalamos el codigo fuente, en español , en la ruta /var/www/html , y que se pueda ejercutar como root

```bash
wp core download --locale=es_ES --path=$WORDPRESS_DIRECTORY --allow-root
```
Creamos el archivo de configuracion

```bash
wp config create --dbname=$WORDPRESS_DB_NAME --dbuser=$WORDPRESS_DB_USER --dbpass=$WORDPRESS_DB_PASSWORD --dbhost=$BACKEND_IP --path=$WORDPRESS_DIRECTORY --allow-root
```
Instalamos el Worpres con el titulo y el usuario

```bash
wp core install --url=$LE_DOMAIN --title=$WORDPRESS_TITULO --admin_user=$WORDPRESS_USER --admin_password=$WORDPRESS_PASSWORD --admin_email=$LE_EMAIL --path=$WORDPRESS_DIRECTORY --allow-root  
```
 Cambiamos los permisos de root a www-data

```bash
chown www-data:www-data /var/www/html/*
```
Instalamos un tema

```bash
wp theme install mindscape --activate --path=$WORDPRESS_DIRECTORY --allow-root
```
Configuramos los enlaces 

```bash
wp rewrite structure '/%postname%/' --path=$WORDPRESS_DIRECTORY --allow-root
```
 Instalamos un plugin para que oculte el inicio de sesion

```bash
wp plugin install wps-hide-login --activate --path=$WORDPRESS_DIRECTORY --allow-root
```
Configuramos el plugin 

```bash
wp option update whl_page "$WORDPRESS_HIDE_LOGIN_URL" --path=$WORDPRESS_DIRECTORY --allow-root
```
Copiamos el archivo .htaccess

```bash
cp ../htaccess/.htaccess $WORDPRESS_DIRECTORY
```
Configuramos la variable $_SERVER['HTTPS'] , para que cargen las hojas de estilo CSS

```bash
sed -i "/COLLATE/a \$_SERVER['HTTPS'] = 'on';" /var/www/html/wp-config.php
```

Cambiamos los permisos de root a www-data

```bash
chown www-data:www-data /var/www/html/*
```
## Balanceador de carga: Instalación del balanceador y del certificado
Comando para ver la ejecucion y  si hay fallo pare
```bash
set -ex
```

Usamos nuestro archivo de variables

```bash
source .env
```

Actualizamos

```bash
apt update
apt upgrade -y
```

instalaccion de Nginx
```bash
sudo apt install nginx -y
```

vamos a deshabilitar el sitio por defecto eliminando el enlace simbólico:

```bash
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    unlink /etc/nginx/sites-enabled/default
fi
```

Colocamos el archivo balanceador en la carpeta de sitios disponibles

```bash
cp ../conf/load-balancer.conf /etc/nginx/sites-available/
```

Cambiamos los valores de IP_FRONTEND

```bash
sed -i "s/IP_FRONTEND_1/$FRONTEND_IP/" /etc/nginx/sites-available/load-balancer.conf
sed -i "s/IP_FRONTEND_2/$FRONTEND_IP2/" /etc/nginx/sites-available/load-balancer.conf
sed -i "s/LE_DOMAIN/$LE_DOMAIN/" /etc/nginx/sites-available/load-balancer.conf
```

Habilitamos el virtual host del balanceador de carga

```bash
if [ ! -f "/etc/nginx/sites-enabled/default" ]; then
    ln -s /etc/nginx/sites-available/load-balancer.conf /etc/nginx/sites-enabled/
fi
```

Recargue la configuración de Nginx.

```bash
sudo systemctl reload nginx
```

Por último instalaremos el certificado.

Configuramos para mostrar los comandos y finalizar si hay error

```bash
set -ex
```

Importamos el archivo de variables

```bash
source .env
```
El proveedor de donimnio sera no-ip

Instalamos y actualizamos snap

```bash
snap install core
snap refresh core
```
Eliminamos instalaciones previas de cerbot con apt

```bash
apt remove certbot -y
```
Instalamos Certbot

```bash
snap install --classic certbot
```
Solicitamos un cerficado a Let`s Encrypt

```bash
sudo certbot --apache -m $LE_EMAIL --agree-tos --no-eff-email -d $LE_DOMAIN --non-interactive
```
 ## Comprobación