FROM nginx:latest

COPY ./certs/localhost.pem /etc/ssl/certs/localhost.pem
COPY ./certs/localhost-key.pem /etc/ssl/private/localhost-key.pem

COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf
