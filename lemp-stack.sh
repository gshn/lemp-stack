#!/usr/bin/env bash
HOSTNAME="lillycover"
DOMAIN="lillycover.com"
DBROOTPASS="1231"
PHPMYADMIN_VERSION="4.7.7"
PHPMYADMIN_BLOWFISH=")Aje8s~9VE|JyV8s7MF0Zw|DReayVcpU^"
PHPMYADMIN_DIRECTORY="phpMyAdmin"
USERID="lillycover"
USERPW="1231"
DOCUMENT_ROOT="/home/${USERID}/app/public"

echo "Asia/Seoul" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

locale-gen ko_KR.UTF-8

echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname

sed -i 's/127.0.0.1 localhost/127.0.0.1 localhost ${DOMAIN}/' /etc/hosts

sed -i 's/kr.archive.ubuntu.com/ftp.daumkakao.com/g' /etc/apt/sources.list

echo "# Nginx" >> /etc/apt/sources.list
echo "deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/sources.list

echo "# MariaDB(한국)" >> /etc/apt/sources.list
echo "deb http://ftp.kaist.ac.kr/mariadb/repo/10.2/ubuntu xenial main" >> /etc/apt/sources.list

wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
rm nginx_signing.key
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8

add-apt-repository -y ppa:ondrej/php

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade
apt -y autoremove

apt-get -y install sendmail
echo "localhost" > /etc/mail/local-host-names

apt-get -y install vsftpd

sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf
sed -i 's/#local_umask=022/local_umask=022/' /etc/vsftpd.conf

service vsftpd restart

apt-get -y install unzip


## nginx 설치
apt-get -y install nginx
service nginx restart

## php 설치
## libargon2-0 libsodium23 php-common php7.2-cli php7.2-common php7.2-json php7.2-opcache php7.2-readline

apt-get -y install php7.2-fpm php7.2-intl php7.2-gd php7.2-curl php7.2-mbstring php7.2-xml
sed -i 's/;emergency_restart_threshold = 0/emergency_restart_threshold = 10/' /etc/php/7.2/fpm/php-fpm.conf
sed -i 's/;emergency_restart_interval = 0/emergency_restart_interval = 1m/' /etc/php/7.2/fpm/php-fpm.conf
service php7.2-fpm restart

## mariadb 설치
debconf-set-selections <<< "mariadb-server-10.2 mysql-server/root_password password ${DBROOTPASS}"
debconf-set-selections <<< "mariadb-server-10.2 mysql-server/root_password_again password ${DBROOTPASS}"
apt-get -y install mariadb-server-10.2 mariadb-client-10.2
apt-get -y install php7.2-mysql

echo "[client]
default-character-set=utf8mb4

[mysql]
default-character-set=utf8mb4

[mysqld]
collation-server = utf8mb4_unicode_ci
character_set_server = utf8mb4
init-connect='SET NAMES utf8mb4'
lower_case_table_names=1
query_cache_type = 1
query_cache_min_res_unit = 2k
sql_mode = NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
max_allowed_packet = 32M
slow_query_log = 1
long_query_time = 2

[mysqldump]
default-character-set=utf8mb4
max_allowed_packet = 32M
" > /etc/mysql/conf.d/mariadb.cnf
service mysql restart

## memcached 캐시서버 설치
apt-get -y install memcached
apt-get -y install php7.2-memcached


## nginx 기본 설정 변경
cat ~/lemp-stack/nginx/nginx.conf > /etc/nginx/nginx.conf
cat ~/lemp-stack/nginx/default.conf > /etc/nginx/conf.d/default.conf
cat ~/lemp-stack/nginx/fastcgi_params > /etc/nginx/fastcgi_params
service nginx restart

## phpmyadmin 설치
cd /usr/share/nginx/html
wget https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
unzip phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
mv phpMyAdmin-$PHPMYADMIN_VERSION-all-languages $PHPMYADMIN_DIRECTORY
rm phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
mv $PHPMYADMIN_DIRECTORY/config.sample.inc.php $PHPMYADMIN_DIRECTORY/config.inc.php
sed -i "s/''/'${PHPMYADMIN_BLOWFISH}'/" $PHPMYADMIN_DIRECTORY/config.inc.php
cd ~

## 사용자 추가
adduser --disabled-password --gecos "" $USERID
echo "${USERID}:${USERPW}" | chpasswd
su -c "mkdir -p ${DOCUMENT_ROOT}" $USERID
su -c 'mkdir ~/log' $USERID

## 사용자 php 설정
echo "[${USERID}]

user = ${USERID}
group = ${USERID}

listen = /run/php/${USERID}.sock

listen.owner = ${USERID}
listen.group = www-data

pm = dynamic
pm.max_children = 9
pm.start_servers = 3
pm.min_spare_servers = 2
pm.max_spare_servers = 4
pm.max_requests = 200

php_admin_value[date.timezone] = Asia/Seoul

php_admin_value[opcache.memory_consumption] = 128
php_admin_value[opcache.interned_strings_buffer] = 16
php_admin_value[opcache.max_accelerated_files] = 10000
php_admin_value[opcache.validate_timestamps] = 1
php_admin_value[opcache.revalidate_freq] = 0 ;0:개발, 1:라이브수정, 2:최적성능
php_admin_value[opcache.fast_shutdown] = 1

php_admin_value[max_execution_time] = 60
php_admin_value[max_input_time] = 60
php_admin_value[post_max_size] = 30M
php_admin_value[upload_max_filesize] = 20M
php_admin_value[upload_tmp_dir]=/home/${USERID}/upload_tmp

php_admin_value[session.save_handler] = 'memcached'
php_admin_value[session.save_path] = '127.0.0.1:11211'

php_admin_value[realpath_cache_size] = 64k

php_admin_value[short_open_tag] = On
" > /etc/php/7.2/fpm/pool.d/$USERID.conf
service php7.2-fpm restart

## 사용자 nginx 설정
echo "server {
    listen      80;
    server_name ${DOMAIN};
    root        ${DOCUMENT_ROOT};

    access_log /home/${USERID}/log/access.log;
    error_log  /home/${USERID}/log/error.log warn;

    location / {
        index  index.php index.html;
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # Allow Lets Encrypt Domain Validation Program
    location ^~ /.well-known/acme-challenge/ {
        allow all;
    }

    # Block dot file (.htaccess .htpasswd .svn .git .env and so on.)
    location ~ /\. {
        deny all;
    }

    # Block (log file, binary, certificate, shell script, sql dump file) access.
    location ~* \.(log|binary|pem|enc|crt|conf|cnf|sql|sh|key)$ {
        deny all;
    }

    # Block access
    location ~* (composer\.json|contributing\.md|license\.txt|readme\.rst|readme\.md|readme\.txt|copyright|artisan|gulpfile\.js|package\.json|phpunit\.xml)$ {
        deny all;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        log_not_found off;
        access_log off;
    }

    # cache expires 1 year
    location ~ [^/]\.(css|js|gif|png|jpg|jpeg|eot|svg|ttf|woff|woff2|otf)(/|$) {
        access_log off;
        add_header Cache-Control must-revalidate;
        expires 1y;
        etag on;
    }

    # Block .php file inside upload folder. uploads(wp), files(drupal, xe), data(gnuboard).
    location ~* /(?:uploads|files|data)/.*\.php$ {
        deny all;
    }

    # Add PHP handler
    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        fastcgi_pass unix:/run/php/${USERID}.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
" > /etc/nginx/conf.d/$USERID.conf

service nginx restart

## 데이터베이스 생성
mysql -uroot -p$DBROOTPASS -e "CREATE DATABASE ${USERID}
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;"
mysql -uroot -p$DBROOTPASS -e "CREATE USER '${USERID}'@'localhost' IDENTIFIED BY '${USERPW}'"
mysql -uroot -p$DBROOTPASS -e "GRANT USAGE ON *.* TO '${USERID}'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0"
mysql -uroot -p$DBROOTPASS -e "GRANT ALL PRIVILEGES ON ${USERID}.* TO '${USERID}'@'localhost'"
