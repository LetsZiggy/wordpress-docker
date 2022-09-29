# Usage

1. [Download ZIP](https://github.com/LetsZiggy/wordpress-docker/archive/refs/heads/main.zip)
	- Use `Download ZIP` instead of `git clone`
2. Extract folder with preferred Wordpress stack
	- apache-dev
	- nginx-dex
3. Follow steps in `INSTRUCTIONS.md`

## Base Images

#### ./apache-dev

- adminer:latest
- mariadb:latest
- wordpress:apache
	- apache
	- php
	- wordpress
- wordpress:cli

#### ./nginx-dex

- adminer:latest
- mariadb:latest
- nginx:latest
- wordpress:fpm
	- php-fpm
	- wordpress
- wordpress:cli
