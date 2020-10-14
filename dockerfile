FROM debian:buster

#installing packages
RUN apt update && \
	apt -y upgrade && \
    apt install -y nginx mariadb-server mariadb-client openssl wget bash && \
	apt install -y php7.3 \
    php7.3-fpm \
    php7.3-mysql \
    php7.3-cli \
    php7.3-common \
    php7.3-json \
    php7.3-opcache \
    php7.3-readline \
    php-gd \
    php-mbstring \
	php-zip \
	php-xml \
	php-curl

RUN apt install sudo

RUN rm -rf /usr/share/nginx/www
#nginx startup
RUN mkdir /var/www/localhost 
COPY srcs/nginx-config	/etc/nginx/sites-available/localhost
RUN ln -s /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj '/C=NL/ST=Noord-Holland/L=Amsterdam/O=Codam/CN=123' -keyout /etc/ssl/certs/localhost.key -out /etc/ssl/certs/localhost.crt

#set user
ARG user=juvan-de
ARG password=password
ENV AUTO_INDEX=on

#copy necessary files
COPY srcs/php.ini /etc/php/7.3/fpm/ 

#installing phpmyadmin
RUN wget  -c https://files.phpmyadmin.net/phpMyAdmin/4.9.5/phpMyAdmin-4.9.5-english.tar.gz && \
	tar -xzvf phpMyAdmin-4.9.5-english.tar.gz && \
	mv	phpMyAdmin-4.9.5-english /var/www/localhost/phpMyAdmin && \
	rm -rf phpMyAdmin-4.9.5-english.tar.gz

#doing the blowfish cookie thing
RUN rm var/www/localhost/phpMyAdmin/config.sample.inc.php
COPY srcs/config.inc.php var/www/localhost/phpMyAdmin/

#mariadb setup
RUN service mysql start  && \
	mysql -e "CREATE DATABASE wordpress;" && \
	mysql -e "CREATE DATABASE phpmyadmin;" && \
	mysql phpmyadmin < var/www/localhost/phpMyAdmin/sql/create_tables.sql && \
	mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${user}'@'localhost' IDENTIFIED BY '${password}';" && \
	mysql -e "FLUSH PRIVILEGES;"

#php setup
RUN mv /var/www/html/index.nginx-debian.html /var/www/localhost
RUN	chown -R www-data:www-data /var/www/localhost
RUN chmod -R 755 /var/www/localhost

#wordpress configuration
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN	chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/bin/wp
RUN wp cli update --allow-root

RUN	service mysql start && \
	wp core download --path=/var/www/localhost/wordpress --allow-root && \
	wp config create --path=/var/www/localhost/wordpress --dbname=wordpress --dbuser=${user} --dbpass=${password} --allow-root && \
	wp core install --path=/var/www/localhost/wordpress --url=localhost/wordpress --title="ft_server" --admin_user=${user} --admin_password=${password} --admin_email=juvan@server.nl --allow-root

RUN chown -R www-data:www-data /var/www/ && \
	chown -R www-data:www-data /var/lib/php/sessions/
COPY srcs/autoindex.sh /
RUN	chmod +x autoindex.sh

EXPOSE 80 443

CMD \
	service mysql start && \
	service php7.3-fpm start && \
	service nginx start && \
	bash