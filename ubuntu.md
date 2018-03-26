# Ubuntu LEMP-stack 설치 스크립트 설명

* 이 스택에서 다루는 방법은 우분투 16.04.3(LTS)에서 검증된 방식입니다.
* 가장 기본적인 스탭으로 타 운영체제 세팅시에도 명령어조합이 조금 차이날 뿐 거의 동일한 방법으로 가능합니다.
* 모든 명령어는 root 권한의 상태에서 실행한 결과입니다. (필요할 경우 유저 변경을 수행하는 부분은 따로 표시합니다.)
* 이 스택을 모두 설치하는데 소요되는 시간은 약 10분 내외입니다. (운영체제 릴리즈 버전 업그레이드 제외)

## 0. 기본 호스트 설정

### 한글 유니코드 지원

```bash
locale-gen ko_KR.UTF-8
```

### ROOT 비밀번호 변경

> "root:**password**" 부분 password 수정

```bash
echo "root:password"|chpasswd
```

### 국내 저장소로 변경

```bash
sed -i 's/kr.archive.ubuntu.com/ftp.daumkakao.com/g' /etc/apt/sources.list
```

### OS 패키지 업데이트 및 업그레이드 및 불필요한 패키지 자동 삭제

```bash
export DEBIAN_FRONTEND=noninteractive && \
apt-get update && \
apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade && \
apt -y autoremove
```

### 서버 시간 변경

한국 시간으로 서버 시간 설정을 변경하고 싶을 때 수행합니다.

```bash
echo "Asia/Seoul" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
```

### hostname 및 hosts

실제로 사용 할 도메인으로 서버 호스트 네임을 변경합니다. 내부적으로 도메인 네임을 설정해놓으면 외부 네임서버를 거치지 않고 바로 스크립트등을 수행하기 때문에 설정해 둘 필요가 있습니다.

```bash
DOMAIN="domain.com"
echo "${DOMAIN}" > /etc/hostname
hostname -F /etc/hostname
sed -i "s/127.0.0.1 localhost/127.0.0.1 localhost ${DOMAIN}/" /etc/hosts
```

## 1. 서버운영에 필요한 필수 프로그램 설치

sendmail과 ftp, ssh등 서버 관리에 필수 프로그램에 관한 설정부분입니다.

### 메일 송신을 위한 sendmail 설치

```bash
apt-get -y install sendmail && \
echo "localhost" > /etc/mail/local-host-names
```


### 파일 전송을 위한 vsftp 설치

```bash
apt-get -y install vsftpd && \
sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf && \
sed -i 's/#local_umask=022/local_umask=022/' /etc/vsftpd.conf && \
service vsftpd restart
```

### zip 파일 압축을 풀기 위한 unzip 설치

```bash
apt-get -y install unzip
```

### nginx, mariadb, php 저장소 추가

기본적으로 `apt-get install` 명령어로 위의 프로그램을 설치 할수 있지만, 최신버전이 설치되지 않습니다. 최신 패치가 적용된 버전을 설치하기 위해서는 기본저장소 외에 최신 패치 버전이 올라오는 저장소를 추가 해 주어야 합니다.


```bash
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
apt-get update
```

## 2. Nginx

저장소가 제대로 적용 되었다면 이후 과정은 정말 간단하게 최신버전의 Nginx와 MariaDB, PHP를 설치해서 사용하실 수 있습니다.

### Nginx 설치

```bash
apt-get -y install nginx && \
service nginx restart
```

버전을 확인해 봅니다.

```bash
nginx -v
nginx version: nginx/1.13.9
```

웹 브라우저로 서버 아이피나 도메인을 통해 접속을 시도해봅시다.

Welcome to nginx!

If you see this page, the nginx web server is successfully installed and working. Further configuration is required.

For online documentation and support please refer to nginx.org.
Commercial support is available at nginx.com.

Thank you for using nginx.

해당 문구의 텍스트 페이지가 나타난다면 Nginx는 문제없이 잘 설치된 상태입니다.
만약 정적인(statc) 페이지의 웹 사이트를 운영할 생각이라면 이 상태로 바로 서버를 운영해도 전혀 문제가 없는 상태입니다.

저장경로(/usr/share/nginx/html)에서 웹사이트를 업로드하고 바로 이용을 하실 수 있습니다.

## 3. PHP-FPM

### php-fpm 7.2 설치

```bash
PHPVERSION="7.2"
apt-get -y install php$PHPVERSION-fpm php$PHPVERSION-intl php$PHPVERSION-gd php$PHPVERSION-curl php$PHPVERSION-mbstring php$PHPVERSION-xml php$PHPVERSION-zip && \
sed -i 's/;emergency_restart_threshold = 0/emergency_restart_threshold = 10/' /etc/php/$PHPVERSION/fpm/php-fpm.conf && \
sed -i 's/;emergency_restart_interval = 0/emergency_restart_interval = 1m/' /etc/php/$PHPVERSION/fpm/php-fpm.conf && \
service php$PHPVERSION-fpm restart
```

버전을 확인해 봅니다.

```bash
php -v
PHP 7.2.1-1+deb.sury.org~xenial+1 (cli) (built: Jan 20 2017 09:20:20) ( NTS )
Copyright (c) 1997-2017 The PHP Group
Zend Engine v3.1.0, Copyright (c) 1998-2017 Zend Technologies
    with Zend OPcache v7.1.1-1+deb.sury.org~xenial+1, Copyright (c) 1999-2017, by Zend Technologies
```

### PHP 버전 문제에 대해서

- PHP 버전이 높을 수록 예전 코드로 작성된 PHP 프로그램이 돌아가지 않을 가능성이 높습니다.
- PHP는 그동안 수 많은 변화를 겪었고, 페이스북과 마이크로소프트 등의 지원과 영감을 받아 엔진부터 새롭게 작성되어 6을 건너뛰고 7으로 거듭났습니다. 그 과정에서 많은 내장 함수들이 제외되었고 새로운 문법으로 작성되도록 권고되고 있습니다.
- 만약 내장함수 의존성 문제등으로 5.x의 PHP를 사용해야만 한다면 5.6을 설치해서 사용해주세요.
- 대체적으로 mysql관련 함수만 mysqli로 고친다면 문제없이 잘 작동하는 경우가 많습니다.
- 그 외에 코드를 7.0으로 마이그레이션 해야한다면 다음의 페이지를 참고하세요.
http://php.net/manual/kr/migration70.php
- modern PHP에 대하여 알아보고 싶다면 다음의 링크를 참고하세요.
http://modernpug.github.io/php-the-right-way/


## 4. MariaDB

### MariaDB 10.2 설치

```bash
DBROOTPASS="1234"
debconf-set-selections <<< "mariadb-server-10.2 mysql-server/root_password password ${DBROOTPASS}"
debconf-set-selections <<< "mariadb-server-10.2 mysql-server/root_password_again password ${DBROOTPASS}"
apt-get -y install mariadb-server-10.2 mariadb-client-10.2 && \
apt-get -y install php$PHPVERSION-mysql
```

설치가 제대로 되었는지 확인 합니다.

```bash
service mysql status
● mariadb.service - MariaDB database server
   Loaded: loaded (/lib/systemd/system/mariadb.service; enabled; vendor preset: enabled)
  Drop-In: /etc/systemd/system/mariadb.service.d
           └─migrated-from-my.cnf-settings.conf
   Active: active (running) since 월 2017-02-06 08:38:43 KST; 7h ago
  Process: 2096 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 2093 ExecStartPost=/etc/mysql/debian-start (code=exited, status=0/SUCCESS)
  Process: 1620 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`/usr/bin/galera_recovery`; [ $? -eq 0 ]   &&
  Process: 1539 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 1522 ExecStartPre=/usr/bin/install -m 755 -o mysql -g root -d /var/run/mysqld (code=exited, status=0/SUCCESS)
 Main PID: 1976 (mysqld)
   Status: "Taking your SQL requests now..."
    Tasks: 32
   Memory: 66.1M
      CPU: 13.735s
   CGroup: /system.slice/mariadb.service
           └─1976 /usr/sbin/mysqld
(중략)
# `q`키를 눌러 로그를 종료할 수 있습니다.
```

`active (running)` 문구가 있다면 정상적으로 잘 실행되고 있습니다.


### MySQL과 MariaDB의 선택 문제

- MySQL이 오라클에 인수 된 후 기존 MySQL 개발팀이 MySQL을 fork해서 MariaDB를 내놓습니다. (저작권 등의 문제로 인해 오픈소스의 정신이 훼손되었다고 생각했나 봅니다.)
- 둘은 거의 모든 경우에 동일한 동작을 보입니다. 심지어 모듈명 서비스명령어까지 동일합니다.
- 버전업은 MariaDB가 먼저 되고 MySQL이 뒤를 따르는 모습입니다.
- 보안 이슈등과 같은 문제는 MariaDB가 항상 빠르게 대응합니다.
- 속도와 관련해서도 MariaDB가 더 향상된 모습으로 평가 됩니다.
- MySQL에만 의존성을 가지는 프로그램이 아니라면 MariaDB를 사용하는게 훨씬 이득입니다.

### MariaDB 언어셋 설정

최근엔 모바일에서 사용하는 이모지(emoji)등에 대응하기 위해 `utf8`이 아닌 `utf8mb4` 언어셋으로 지정합니다.

```bash
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
```

## 5. redis 캐시서버 설치

부가적으로 PHP에서 세션을 이용할 때 디스크 파일이 아닌 캐시를 이용해서 사이트 속도 품질을 올리는 기법이 추천되고 있습니다.
하드디스크 파일보단 메모리 캐시의 I/O가 훨씬 빠르다는 것쯤은 모두 알고 계시지요.

### redis 서버 및 php-redis 연동 설치

```bash
apt-get -y install redis-server && \
apt-get -y install php-redis
```

이후 PHP 설정에서 세션 핸들러를 파일이 아닌 redis 서버로 설정할 것입니다.

## 6. Nginx 와 PHP를 연동하는 기본 설정

apache와 달리 Nginx는 PHP 스크립트를 해석하는 모듈을 기본적으로 포함하고 있지 않습니다. 단지 프록시 기능만을 수행 할 뿐인데요, PHP-FPM이라는 PHP fast process manege 프로그램을 통해서 PHP를 해석하고 받은 결과를 클라이언트에게 서비스하는 방식으로 구현해야 합니다.

먼저 nginx 기본설정을 수정합니다.

```bash
echo "fastcgi_param   QUERY_STRING            \$query_string;
fastcgi_param   REQUEST_METHOD          \$request_method;
fastcgi_param   CONTENT_TYPE            \$content_type;
fastcgi_param   CONTENT_LENGTH          \$content_length;
fastcgi_param   SCRIPT_FILENAME         \$document_root\$fastcgi_script_name;
fastcgi_param   SCRIPT_NAME             \$fastcgi_script_name;
fastcgi_param   PATH_INFO               \$fastcgi_path_info;
fastcgi_param   PATH_TRANSLATED         \$document_root\$fastcgi_path_info;
fastcgi_param   REQUEST_URI             \$request_uri;
fastcgi_param   DOCUMENT_URI            \$document_uri;
fastcgi_param   DOCUMENT_ROOT           \$document_root;
fastcgi_param   SERVER_PROTOCOL         \$server_protocol;
fastcgi_param   GATEWAY_INTERFACE       CGI/1.1;
fastcgi_param   SERVER_SOFTWARE         nginx/\$nginx_version;
fastcgi_param   REMOTE_ADDR             \$remote_addr;
fastcgi_param   REMOTE_PORT             \$remote_port;
fastcgi_param   SERVER_ADDR             \$server_addr;
fastcgi_param   SERVER_PORT             \$server_port;
fastcgi_param   SERVER_NAME             \$server_name;
fastcgi_param   HTTPS                   \$https;
# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param   REDIRECT_STATUS         200;
" > /etc/nginx/fastcgi_params

echo "user  www-data;
### 1 코어당 1 프로세스 ###
worker_processes  1; 
pid        /var/run/nginx.pid;
error_log  /var/log/nginx/error.log error;
events {
    ### 동시에 몇 접속까지 허용할지 ulimit -n 을 통해서 측정 ###
    worker_connections  1024;
}
http {
    ### Nginx 버전 표기 ###
    server_tokens off;
    ### 보안 적용 ###
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection '1;mode=block';
    ### global ###
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    access_log off;
    ### buffers ###
    client_body_buffer_size     16k;
    client_header_buffer_size   1k;
    client_max_body_size        0;
    large_client_header_buffers 2 1k;
    ### timeouts ###
    client_body_timeout     12;
    client_header_timeout   12;
    keepalive_timeout       15;
    send_timeout            10;
    ### compression ###
    gzip                    on;
    gzip_comp_level         2;
    gzip_min_length         1000;
    gzip_proxied            expired no-cache no-store private auth;
    gzip_types              text/plain text/css text/x-component
                            text/xml application/xml application/xhtml+xml application/json
                            image/x-icon image/bmp image/svg+xml application/atom+xml
                            text/javascript application/javascript application/x-javascript
                            application/pdf application/postscript
                            application/rtf application/msword
                            application/vnd.ms-powerpoint application/vnd.ms-excel
                            application/vnd.ms-fontobject application/vnd.wap.wml
                            application/x-font-ttf application/x-font-opentype;
    include /etc/nginx/conf.d/*.conf;
}
" > /etc/nginx/nginx.conf

echo "server {
    listen 80 default_server;
    server_name localhost;
    root /usr/share/nginx/html;
    location / {
        index  index.php index.html;
    }
    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        if (!-f \$document_root\$fastcgi_script_name) {
            return 404;
        }
        fastcgi_pass unix:/run/php/php${PHPVERSION}-fpm.sock;
        fastcgi_index index.php;
        fastcgi_buffers 64 16k;
        include fastcgi_params;
    }
}
" > /etc/nginx/conf.d/default.conf
service nginx restart
```

## 7. phpMyAdmin 설치 테스트

Nginx, MariaDB, PHP가 잘 연동되었는지 확인할 수 있는 가장 좋은 프로그램인 phpMyAdmin을 설치해서 테스트 해봅니다. DB를 손쉽게 관리하는 차원에서도 이 프로그램은 반드시 필요한 프로그램입니다.

http://phpmyadmin.net 에서 최신버전(예시는 4.6.6)을 확인 후 `wget` 명령어를 변경해서 설치하도록 합니다. 꼭 최신버전으로 설치하세요.

_php_My_Admin_1234 과 같은 이상한 디렉터리에 올리는 이유는 보안상 노출되면 좋지 않은 디렉터리이기 때문입니다. 아주 질이 나쁜 봇(bot)들은 phpMyAdmin이 올라가 있는 디렉터리를 항상 찾아다닙니다. 오픈소스이기 때문에 알려진 취약점이 많은 프로그램이라 업그레이드 되지 않은 오래된 버전의 phpMyAdmin은 공식적인 최고의 해킹툴로 전략 해버리니 항상 버전업에 신경써주시고, 되도록 노출되지 않을법한 디렉터리명에 저장하시기 바랍니다.
그리고 robots.txt의 룰을 통해서 디렉터리를 보호하겠다는 생각은 하지 마시길 바랍니다. 해당 룰을 지키는 봇은 몇 안됩니다. 특히 크래킹을 목적으로 가진 봇이 그 룰을 지킬리는 만무합니다.

혹시 모르는 보안을 위해서 blowfish_secret도 생성해 적용합니다.

https://www.question-defense.com/tools/phpmyadmin-blowfish-secret-generator

```bash
PHPMYADMIN_VERSION="4.7.9"
PHPMYADMIN_DIRECTORY="_php_My_Admin_1234"
PHPMYADMIN_BLOWFISH=")Aje8s~9VE|JyV8s7MF0Zw|DReayVcpU^"
cd /usr/share/nginx/html
wget https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
unzip phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
mv phpMyAdmin-$PHPMYADMIN_VERSION-all-languages $PHPMYADMIN_DIRECTORY
rm phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
mv $PHPMYADMIN_DIRECTORY/config.sample.inc.php $PHPMYADMIN_DIRECTORY/config.inc.php
sed -i "s/''/'${PHPMYADMIN_BLOWFISH}'/" $PHPMYADMIN_DIRECTORY/config.inc.php
cd ~
```

브라우저를 통해 phpMyAdmin가 설치된 경로에 접근해 봅니다.
정상적으로 DB에 접속이 된다면 모든 서비스가 잘 설정 되었다고 볼 수 있습니다.

만약 본 서버에 하나의 도메인에 하나의 호스팅만 할 예정이라면 현 상태로 PHP 스크립트를 올려 프로젝트를 서비스하셔도 됩니다. 이 후의 과정은 여러개의 도메인을 사용해서 여러 개의 사이트가 별도의 설정을 가지는 서버일 경우에 하는 설정을 기술합니다.

## 8. 사용자별 계정 추가 및 설정

도메인에 따라서 여러개의 사이트를 운영하는 법을 알려드립니다.

### 사용자 추가

```bash
USERID="userid"
USERPW="userpw"
DOCUMENT_ROOT="/home/${USERID}/app/public"
adduser --disabled-password --gecos "" $USERID && \
echo "${USERID}:${USERPW}" | chpasswd && \
su -c "mkdir -p ${DOCUMENT_ROOT}" $USERID && \
su -c 'mkdir ~/log' $USERID && \
su -c "echo 'success' > ${DOCUMENT_ROOT}/index.php" $USERID
```

### 사용자 php 설정

이제 공통의 php.ini 설정이 아닌 사용자별 PHP를 설정해줍니다.

```bash
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
" > /etc/php/$PHPVERSION/fpm/pool.d/$USERID.conf
service php$PHPVERSION-fpm restart
```

`pm`은 자식 프로세스에 관한 설정들입니다. 사용자가 폭발적으로 늘어나게되면 반드시 설정의 변화가 필요합니다. 자세한 튜닝법은 서버 스팩과 동시 접속자 사이에서 적절하게 찾아야 하며, 많은 시행착오 끝에 좋은 결과가 나오니 이 부분은 많은 검색을 통해서 해결해보는게 좋습니다.

`opcache`는 PHP에서 기본적으로 제공하는 캐시를 설정하는 부분입니다. 이 캐시가 활성화하게 되면 php-fpm가 PHP 스크립트를 해석하는 과정이 제외되고 바로 해석이 완료된 결과물을 Nginx에게 보내게 됩니다. 
개발 서버의 경우 `opcache.validate_timestamps` 가 `1`로 설정해서 계속해서 바뀐 스크립트가 있는지를 확인 해야 합니다.
서비스를 하는 서버의 경우 `opcache.validate_timestamps`는 `0`으로 설정을 바꾸시면 되고 만약 PHP 스크립트가 수정되게 되면 php-fpm 서비스를 재시작 하셔야 반영이 됩니다.

`max_execution_time`은 PHP 서버의 품질과 관련되어 있습니다. 만약 해석이 너무 느려지는 스크립트가 발생되면 빠르게 500에러를 발생시켜서 사용자가 계속해서 기다리기만 하지 않도록 합니다. 단지 기다리기만 하는 것을 문제점이 있다는 인식으로 바꿔 줄 수 있습니다만 이는 근본적인 해결책은 아닙니다. 개발자가 PHP 스크립트 품질을 직접 검사하는게 옳은 방법입니다.

`max_input_time`, `post_max_size`, `upload_max_filesize` 부분은 파일 업로드와 관련이 큰 부분입니다. 프로젝트의 컨셉에 맞게 해당 사이즈들을 설정하시면 됩니다.

`session` 부분은 이전에 memcache 서버를 설치 했다면 이 설정으로 변경하시면 됩니다. 만약 단순히 file 시스템을 이용한다면 이 부분을 사용해선 안됩니다.

`realpath_cache_size` 이 부분은 PHP 언어가 가진 특성인 무한 `include`, `require` 늪에서 조금이나마 빠르게 file path를 찾도록 도와주는 캐시입니다.

### 사용자 Nginx 설정

개별 도메인에 대한 Nginx 연결 설정을 해줍니다.

```bash
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
        if (!-f \$document_root\$fastcgi_script_name) {
            return 404;
        }
        fastcgi_pass unix:/run/php/${USERID}.sock;
        fastcgi_index index.php;
        fastcgi_buffers 64 16k;
        include fastcgi_params;
    }
}
" > /etc/nginx/conf.d/$USERID.conf
service nginx restart
```

`listen` 은 기본적으로 80포트를 봅니다. 만약 다른 포트로 사이트를 운영 할 예정이라면 다른 포트로 변경하셔도 됩니다.

`server_name` 은 사용할 도메인을 열거합니다. 여러개의 도메인을 모두 적용 할 수 있습니다. 예를 들어 `czm.kr` 과 `www.czm.kr` 을 같은 연결로 볼 때 스페이스를 구분자로 열거 할 수 있습니다.

`root`, `access_log`, `error_log`는 각각의 파일들이 위치한 경로를 설정합니다. 그 디렉터리의 소유자는 `czm`이어야만 합니다.

`location /` 은 기본 실행 파일명이 들어갑니다. uri에 `index.php` 라는 파일명이 들어가지 않아도 자동으로 `index.html`, `index.php`를 검색해서 수행하겠다는 이야기 입니다. 그리고 arguments 요청은 `?$args`로 요청을 수행하겠다는 명시입니다.

`location ^~ /.well-known/acme-challenge/` 부분은 나중에 설정할 내용으로 Encrypt 접속에 대한 예외 처리로 사용됩니다.

`location ~* \.(log|binary|pem|enc|crt|conf|cnf|sql|sh|key)$` 의 내용은 혹시나 보안에 관련된 파일을 접속 혹은 수행 할 수 없도록 막는 역할입니다.

`location ~* (composer\.json|contributing\.md|license\.txt|readme\.rst|readme\.md|readme\.txt|copyright|artisan|gulpfile\.js|package\.json|phpunit\.xml)$` 이 내용 역시 보안과 관련된 내용을 접속 혹은 수행 할 수 없도록 막는 역할을 합니다.

`location = /favicon.ico` 와 `location = /robots.txt` 는 단순한 접속에 의해서 로그가 남는 경우를 줄이기 위해서 사용합니다.

`location ~* /(?:uploads|files|data)/.*\.php$` 의 경우 사용자가 업로드 한 파일에 스크립트가 실행 되지 않도록 막는 역할을 합니다.

마지막으로 `location ~ [^/]\.php(/|$)` 는 확장자가 `.php` 파일일 경우 FPM에서 해석하는 과정을 거쳐서 서비스 하도록 지시를 내리는 역할입니다.

여기까지가 기본적인 사용자 계정 세팅 방법입니다. 80포트를 통해 http 서비스를 제공 할 경우 여기까지만 수행하시면 됩니다. 뒤로 나오는 내용은 443 포트를 이용한 https 서비스를 제공할 경우에 해야하는 과정을 설명합니다.

### 사용자 데이터베이스 생성

DATABASE root 패스워드를 입력해야합니다.

```bash
mysql -uroot -p$DBROOTPASS -e "CREATE DATABASE ${USERID}
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;"
mysql -uroot -p$DBROOTPASS -e "CREATE USER '${USERID}'@'localhost' IDENTIFIED BY '${USERPW}'"
mysql -uroot -p$DBROOTPASS -e "GRANT USAGE ON *.* TO '${USERID}'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0"
mysql -uroot -p$DBROOTPASS -e "GRANT ALL PRIVILEGES ON ${USERID}.* TO '${USERID}'@'localhost'"
```

## 9. TLS(SSL)을 통한 https 프로토콜 사용

무료 인증서인 `letsencrypt`를 이용해서 https 서비스를 제공하는 법을 설명합니다. 이 방법을 그대로 적용하면 `HTTP/2` 프로토콜까지 함께 사용할 수 있는 효과가 있습니다.

`HTTP/2` 를 이용하게 되면 다음과 같은 이점이 있습니다.
1. HTTP 헤더 크기를 줄이도록 지원합니다. 일반적인 기존 헤더 크기보다 3분의 1가량 크기를 줄일 수 있습니다.
2. 멀티플랙스 스트림을 사용할 수 있습니다. 이는 메시지 구조 자체를 새로 만든 것입니다. TCP 커넥션으로 단일 메시지가 아닌 여러 메시지를 주고 받는 형태입니다. 이를 통해 서버와 클라이언트간 통신 시간인 `RTT`를 절반 가량 줄일 수 있습니다.
3. 서버 푸시를 사용할 수 있습니다. 클라이언트가 요청하지 않은 리소스를 서버가 알아서 보내는 것을 말합니다. 클라이언트의 요청 작업이 줄어드니 전체 처리 속도가 빨라질 수 밖에 없습니다.
4. 스트림 프라이어티를 사용할 수 있습니다. 이는 중요한 요청에 우선순위를 부과하는 기술입니다. 예를 들어 CSS와 그림 파일이 중요하다고 지정하면, 해당 파일에 의존성을 부과하여 웹브라우저 화면에서 가장 먼저 노출해야할 파일들을 먼저 로딩시켜 레이아웃이나 이미지가 깨져 보이지 않도록 조절 하는 기술입니다.

결론적으로 좀 더 진보한 기술인 `HTTP/2`를 이용하면 기존보다 훨씬 빠른 속도로 웹 서비스를 제공할 수 있습니다.

### 인증서 프로그램 설치

먼저 무료 인증서 프로그램인 `letsencrypt` 를 설치합니다.

```bash
apt-get install -y letsencrypt && \
letsencrypt certonly --agree-tos --email $EMAIL --webroot --webroot-path=$DOCUMENT_ROOT -d $DOMAIN && \
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
```

### Nginx 연결 설정 변경

nginx 연결 설정 파일을 새로 작성합니다.

```
echo "server {
    listen       80;
    server_name  ${DOMAIN};
    return       301 https://${DOMAIN}\$request_uri;
}
server {
    listen       443 ssl http2;
    server_name  ${DOMAIN};
    root   ${DOCUMENT_ROOT};
    access_log /home/${USERID}/log/access.log;
    error_log  /home/${USERID}/log/error.log warn;
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;
    # Enable HSTS. This forces SSL on clients that respect it, most modern browsers. The includeSubDomains flag is optional.
    add_header Strict-Transport-Security 'max-age=63072000';
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection '1;mode=block';
    # Set caches, protocols, and accepted ciphers. This config will merit an A+ SSL Labs score.
    ssl_session_cache shared:SSL:20m;
    ssl_session_timeout 10m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DH+3DES:!ADH:!AECDH:!MD5';
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
    location ~* /(?:uploads|files|data|upload)/.*\.php$ {
        deny all;
    }
    # Add PHP handler
    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        if (!-f \$document_root\$fastcgi_script_name) {
            return 404;
        }
        fastcgi_pass unix:/run/php/${USERID}.sock;
        fastcgi_index index.php;
        fastcgi_buffers 64 16k;
        include fastcgi_params;
    }
}
" > /etc/nginx/conf.d/$USERID.conf
service nginx restart
```

443으로 들어오는 연결은 `ssl` 연결이며 `HTTP/2` 연결로 받아들입니다. `ssl_certificate`, `ssl_certificate_key`, `ssl_dhparam` 경로를 해당 도메인에 맞게 변경을 합니다.

`Strict-Transport-Security` 설정을 하게 되면 적어도 365일간은 http 접속을 할 수 없게 됩니다. 브라우저가 이미 해당도메인은 https로 인식하게 되서 애초에 연결을 https로만 시도하게 되고 강제로 http 접속을 시도하려고 해도 바꿀 수 없도록 설정합니다. 이는 http로 위조하는 공격을 애초가 못하도록 차단하는 역할을 합니다.

그 외 ssl 관련 설정만 그대로 옮겨와 쓰시면 되고, 나머지 설정은 80일때 설정과 동일한 상태입니다.

### 인증서 자동 리뉴얼

`letsencrypt` 의 인증서 유효기간은 3개월로 매우 짧은 편입니다. 3개월이 지나면 폐기 되는 인증서가 되는데 이는 관리가 상당히 번거로울 수 있습니다. 하지만 크론탭을 통해서 인증서를 자동으로 리뉴얼 할 수 있으니 걱정안하셔도 됩니다.

```bash
 -e "10 5 * * 1 /usr/bin/letsencrypt renew >> /var/log/le-renew.log\n15 5 * * 1 /usr/sbin/service nginx reload" | crontab
```

이렇게 해두면 인증서를 계속해서 점검을 하게됩니다. 서버내에 설치된 모든 인증서가 만료 기한이 다되면 자동으로 리뉴얼하게 됩니다.

## 10. 자동 백업

매일 2회 10일치를 저장합니다.

```bash
mkdir /backup
chmod 700 /backup
cd ~
echo "#!/bin/bash
tar -czpf /backup/${USERID}.\`date +%Y%m%d%H%M%S\`.tgz /home/${USERID} 1>/dev/null 2>/dev/null
mysqldump --extended-insert=FALSE -u${USERID} -p${USERPW} ${USERID} > /backup/${USERID}.\`date +%Y%m%d%H%M%S\`.sql
find /backup/ -type f -mtime +10 | sort | xargs rm -f
" > backup.sh
chmod 700 backup.sh
echo -e "0 6 * * * /root/backup.sh 1>/dev/null 2>/dev/null\n0 18 * * * /root/backup.sh 1>/dev/null 2>/dev/null" | crontab
```

여기까지 진행 했으면 reboot 후 도메인으로 접속을 시도 합니다.

```bash
reboot
```
