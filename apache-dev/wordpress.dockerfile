FROM wordpress:apache

COPY ./certs/localhost.pem /etc/ssl/certs/localhost.pem
COPY ./certs/localhost-key.pem /etc/ssl/private/localhost-key.pem

COPY ./php/php.ini /usr/local/etc/php/conf.d/php.ini

COPY ./apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./apache/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf

RUN a2enmod ssl \
 && a2ensite default-ssl

EXPOSE 80 443
