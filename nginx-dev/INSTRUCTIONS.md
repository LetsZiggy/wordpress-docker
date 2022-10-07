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

1. `cd nginx-dev`
2. `mkdir -p certs mariadb nginx php wordpress/plugins wordpress/themes wordpress/wordpress`
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
4. Set NGINX configs for [SSL](https://www.ssl.com/how-to/install-ssl-certificate-on-nginx/), [HTTP redirect](https://www.ssl.com/how-to/install-ssl-certificate-on-nginx/), [php-fpm](https://www.nginx.com/resources/wiki/start/topics/recipes/wordpress/), and socket connection ([01](https://medium.com/@shrikeh/setting-up-nginx-and-php-fpm-in-docker-with-unix-sockets-6fdfbdc19f91), [02](https://serversforhackers.com/c/php-fpm-configuration-the-listen-directive), [03](https://rtcamp.com/tutorials/php/fpm-sysctl-tweaking/))
	1. `cd ./nginx`
	2. `touch access.log error.log`
	3. `docker run --rm nginx:latest /bin/bash -c "cat /etc/nginx/conf.d/default.conf" > default.conf`
	4. Edit *./nginx/default.conf*
		- Amend **ssl_certificate...** statements accordingly if **localhost** is not the **[URL]** for `mkcert [URL]`
			- Check SSL cert filenames in *./certs* and amend accordingly
			- Lines starts with:
				- **ssl_certificate ...**
				- **ssl_certificate_key ...**
		- [Example](#nginx-default-conf)
	5. Ensure SSL cert filenames matches in *./nginx.dockerfile*
		- Amend **COPY ./certs/...** statements accordingly if **localhost** is not the **[URL]** for `mkcert [URL]`
			- Check SSL cert filenames in *./certs* and amend accordingly
			- Lines ends with:
				- **.../certs/localhost.pem**
				- **.../private/localhost-key.pem**
		- [Example](#nginx-dockerfile)
5. Set [PHP configs](https://github.com/docker-library/docs/tree/master/wordpress#configuring-php-directives)
	1. `cd ./php`
	2. `docker run --rm wordpress:fpm /bin/bash -c "cat $PHP_INI_DIR/php-fpm.d/www.conf" > www.conf`
		- `docker run --rm wordpress:fpm /bin/bash -c "cat /usr/local/etc/php-fpm.d/www.conf" > www.conf`
	3. Edit *./php/&#969;&#969;&#969;.conf*
		- Uncomment and amend php-fpm settings accordingly
			- Lines starts with:
				- **listen = ...**
				- **listen.owner = ...**
				- **listen.group = ...**
				- **listen.mode = ...**
		- [Example](#php-fpm)
	4. `docker run --rm wordpress:fpm /bin/bash -c "cat $PHP_INI_DIR/php.ini-development" > php.ini`
		- `docker run --rm wordpress:fpm /bin/bash -c "cat /usr/local/etc/php/php.ini-development" > php.ini`
	5. Edit *./php/php.ini*
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

#### nginx-default-conf
```Nginx
upstream wordpress {
  server unix:/tmp/php-cgi.socket;
  server wordpress:9000;
}

server {
  listen      80;
  listen      [::]:80;
  server_name localhost;

  return 301 https://$host$request_uri;
}

server {
  listen      443 ssl;
  listen      [::]:443 ssl;
  server_name localhost;
  root        /var/www/html;
  index       index.php;

  ssl_certificate     /etc/ssl/certs/localhost.pem;
  ssl_certificate_key /etc/ssl/private/localhost-key.pem;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root /usr/share/nginx/html;
  }

  location ~ \.php$ {
    try_files                $uri = 404;
    fastcgi_split_path_info  ^(.+\.php)(/.+)$;
    fastcgi_intercept_errors on;
    fastcgi_pass             wordpress;
    fastcgi_index            index.php;
    include                  fastcgi_params;
    fastcgi_param            SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param            PATH_INFO $fastcgi_path_info;
  }

  location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
    expires       max;
    log_not_found off;
  }
}
```

#### nginx-dockerfile
```Dockerfile
FROM nginx:latest

COPY ./certs/localhost.pem /etc/ssl/certs/localhost.pem
COPY ./certs/localhost-key.pem /etc/ssl/private/localhost-key.pem

COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf
```

#### php-fpm
```INI
...
listen = /tmp/php-cgi.socket ; 127.0.0.1:9000
...

...
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
...
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
