FROM debian:buster

#installing packages
RUN apt update && \
    apt install -y nginx mariadb-server mariadb-client php-fpm php-mysql 

#nginx startup
COPY srcs/nginx-config	/etc/nginx/sites-available/localhost
RUN ln -s /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled/


#mariadb setup
RUN service mysql start && \
	mariadb && \
	echo "CREATE DATABASE wordpress;" && \
	echo "GRANT ALL ON wordpress.* TO 'juvan-de'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;" && \
	echo "FLUSH PRIVILEGES;"


EXPOSE 80

CMD service mysql start && \
	service nginx start && \
	tail -f /dev/null
	