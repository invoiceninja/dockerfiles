DockerFile for invoice ninja (https://www.invoiceninja.com/)

This image is based on `php:7.2-fpm` official version.

To make your data persistent, you have to mount `/var/www/app/public/logo` and `/var/www/app/storage`.


### Usage

To run it:

```
docker run -d \
  -e APP_ENV='production' \
  -e APP_DEBUG=0 \
  -e APP_URL='http://ninja.dev' \
  -e APP_KEY='SomeRandomStringSomeRandomString' \
  -e APP_CIPHER='AES-256-CBC' \
  -e DB_TYPE='mysql' \
  -e DB_STRICT='false' \
  -e DB_HOST='localhost' \
  -e DB_DATABASE='ninja' \
  -e DB_USERNAME='ninja' \
  -e DB_PASSWORD='ninja' \
  -p '9000:9000' \
  invoiceninja/invoiceninja
```
A list of environment variables can be found [here](https://github.com/invoiceninja/invoiceninja/blob/master/.env.example).


### With docker-compose

A ready to use docker-compose configuration can be found at [`./docker-compose`](https://github.com/invoiceninja/dockerfiles/tree/master/docker-compose).

Run `cp .env.example .env` and change the environment variables as needed.
The file assumes that all your persistent data is mounted from `/srv/invoiceninja/`.
Once started, the application should be accessible at http://localhost:8000.

### Known issues

Phantomjs doesn't work on linux alpine https://github.com/ariya/phantomjs/issues/14186.
