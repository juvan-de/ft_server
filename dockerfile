FROM debian:buster

#installing packages
RUN apt update && \
    apt install -y nginx mariadb-server mariadb-client openssl && \
	apt install -y php7.3 \
    php7.3-fpm \
    php7.3-mysql \
    php7.3-cli \
    php7.3-common \
    php7.3-json \
    php7.3-opcache \
    php7.3-readline \
    php-gd \
    php-mbstring 

RUN rm -rf /usr/share/nginx/www
#nginx startup
RUN mkdir /var/www/localhost 
COPY srcs/nginx-config	/etc/nginx/sites-available/localhost
RUN ln -s /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj '/C=NL/ST=Noord-Holland/L=Amsterdam/O=Codam/CN=123' -keyout /etc/ssl/certs/localhost.key -out /etc/ssl/certs/localhost.crt

#mariadb setup
RUN service mysql start  && \
	mysql -e "CREATE DATABASE wordpress;" && \
	mysql -e "CREATE USER 'juvan-de'@'localhost' IDENTIFIED BY 'password';" && \
	mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'juvan-de'@'localhost' IDENTIFIED BY 'password';" && \
	mysql -e "FLUSH PRIVILEGES;"

#php setup
COPY srcs/info.php	/var/www/localhost/
RUN	chown -R www-data:www-data /var/www/localhost/info.php
RUN chmod -R 777 /var/www/localhost/info.php

EXPOSE 80 443

CMD \
	service mysql start && \
	service php7.3-fpm start && \
	service nginx start && \
	tail -f /dev/null