FROM wordpress:fpm

COPY ./php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./php/php.ini /usr/local/etc/php/conf.d/php.ini
