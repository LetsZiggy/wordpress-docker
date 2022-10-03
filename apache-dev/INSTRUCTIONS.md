Prerequisites:
- [mkcert](https://github.com/FiloSottile/mkcert)
	- `mkcert -install`
- docker
	- `groupadd docker`
- docker-compose
- $USER in docker group to allow adding/editing files/folders as $USER
	- `usermod -aG docker $USER`
- $USER in http group to allow adding/editing files/folders as $USER
	- `usermod -aG http $USER`

---

1. `cd apache-dev`
2. `mkdir -p apache certs mariadb php wordpress/plugins wordpress/themes wordpress/wordpress`
	- `mkdir -p wordpress/plugins/[custom-plugins-folder]`
		- Edit *./docker-compose.yml*
			- Uncomment and amend commented **volumes** item accordingly
	- `mkdir -p wordpress/themes/[custom-themes-folder]`
		- Edit *./docker-compose.yml*
			- Uncomment and amend commented **volumes** item accordingly
3. Create SSL certs with [mkcert](https://github.com/FiloSottile/mkcert)
	1. `cd ./certs`
	2. `mkcert [URL]`
		- eg: `mkcert localhost`
4. Set [Apache configs](https://www.ssl.com/how-to/redirect-http-to-https-with-apache/)
	1. `cd ./apache`
	2. `touch access.log error.log other_vhosts_access.log`
	3. `docker run --rm wordpress:apache /bin/bash -c "cat /etc/apache2/sites-available/000-default.conf" > 000-default.conf`
	4. Edit *./apache/000-default.conf*
		- [Example](#000-default-conf)
	5. `docker run --rm wordpress:latest /bin/bash -c "cat /etc/apache2/sites-available/default-ssl.conf" > default-ssl.conf`
	6. Edit *./apache/default-ssl.conf*
		- Amend **SSLCertificate...** statements accordingly if **localhost** is not the **[URL]** for `mkcert [URL]`
			- Check SSL cert filenames in *./certs* and amend accordingly
			- Lines starts with:
				- **SSLCertificateFile ...**
				- **SSLCertificateKeyFile ...**
		- [Example](#default-ssl-conf)
	7. Ensure SSL cert filenames matches in *./wordpress.dockerfile*
		- Amend **COPY ./certs/...** statements accordingly if **localhost** is not the **[URL]** for `mkcert [URL]`
			- Check SSL cert filenames in *./certs* and amend accordingly
			- Lines ends with:
				- **.../certs/localhost.pem**
				- **.../private/localhost-key.pem**
		- [Example](#wordpress-dockerfile)
5. Set [PHP configs](https://github.com/docker-library/docs/tree/master/wordpress#configuring-php-directives)
	1. `cd ./php`
	2. `docker run --rm wordpress:apache /bin/bash -c "cat $PHP_INI_DIR/php.ini-development" > php.ini`
		- `docker run --rm wordpress:apache /bin/bash -c "cat /usr/local/etc/php/php.ini-development" > php.ini`
	3. Edit *./php/php.ini*
		- Amend php settings accordingly
			- Settings with:
				- **upload_max_filesize**
				- **post_max_size**
				- **memory_limit**
				- **max_execution_time**
				- **max_input_time**
		- [Example](#php-ini)
6. Create *./development.env*
	1. `cp development.example.env development.env`
	2. Amend the values with **set_...** accordingly
		- Passphase Generators
			- [Bitwarden passphase generator](https://bitwarden.com/password-generator/)
			- [1Password passphase generator](https://1password.com/password-generator/)
		- Key Generators
			- [WordPress key generator 1.1 - salt](https://api.wordpress.org/secret-key/1.1/salt/)
			- [WordPress key generator 1.1](https://api.wordpress.org/secret-key/1.1/)
			- [WordPress key generator 1.0](https://api.wordpress.org/secret-key/1.0/)
7. To start-up docker containers
	- `docker-compose up --remove-orphans --build --detach`
8. Change permissions to be able to add/edit files as $USER
	1. `sudo find ./wordpress -type d -exec chmod -v 775 {} \;`
		- 775 instead of 755 to allow $USER to add/edit files in docker
	2. `sudo find ./wordpress -type f -exec chmod -v 664 {} \;`
		- 664 instead of 644 to allow $USER to add/edit files in docker
9.Using [wp-cli](https://wp-cli.org/)
	1. Add alias for ease of use
		- Per-session:
			- `alias wp='docker-compose run --rm wp-cli'`
		- Per-user:
			1. Edit *&#126;/.bashrc*
				- [Example](#bash-alias)
			2. `source ~/.bashrc`
	2. Run wp-cli
		- [Command list](https://developer.wordpress.org/cli/commands/)
			- eg: `wp user list`
10. To shutdown docker containers
	- `docker-compose down --remove-orphans --rmi=local`

---

#### wordpress-dockerfile
```Dockerfile
FROM wordpress:apache

COPY ./certs/localhost.pem /etc/ssl/certs/localhost.pem
COPY ./certs/localhost-key.pem /etc/ssl/private/localhost-key.pem

COPY ./php/php.ini /usr/local/etc/php/conf.d/php.ini

COPY ./apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./apache/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf

RUN a2enmod ssl \
 && a2ensite default-ssl

EXPOSE 80 443
```

#### 000-default-conf
```ApacheConf
<VirtualHost *:80>
  ServerName localhost
  Redirect / https://localhost/
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
```

#### default-ssl-conf
```ApacheConf
<IfModule mod_ssl.c>
  <VirtualHost _default_:443>
    ServerAdmin webmaster@localhost

    DocumentRoot /var/www/html

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    SSLEngine on

    SSLCertificateFile /etc/ssl/certs/localhost.pem
    SSLCertificateKeyFile /etc/ssl/private/localhost-key.pem

    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>

    <Directory /usr/lib/cgi-bin>
      SSLOptions +StdEnvVars
    </Directory>
  </VirtualHost>
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
```

#### php-ini
```INI
...
upload_max_filesize = 128M
...

...
post_max_size = 128M
...

...
memory_limit = 256M
...

...
max_execution_time = 300
...

...
max_input_time = 300
...
```

#### bash-alias
```Shell
...
# Docker WP-CLI
alias wp='docker-compose run --rm wp-cli'
...
```
