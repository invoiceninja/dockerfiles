DockerFile for invoice ninja (https://www.invoiceninja.com/)

This image is based on `php:7` official version.

The easiest way to try this image is via docker compose :

```
db:
  image: mysql
  environment:
    MYSQL_DATABASE: ninja
    MYSQL_ROOT_PASSWORD: mdp

app:
  image: invoiceninja/invoiceninja
  links:
    - db:mysql

web:
  image: nginx
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf:ro
  links:
    - app
  volumes_from:
    - app
  ports:
    - 80
```

To make your data persistant, you have to mount `/var/www/app/public/logo` and `/var/www/app/storage`.
