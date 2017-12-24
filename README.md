DockerFile for invoice ninja (https://www.invoiceninja.com/)

This image is based on `php:7` official version.

The easiest way to test Invoice Ninja with docker is by copying the example directory, run `docker-compose up` and visit http://localhost:8000/ .

To make your data persistent, you have to mount `/var/www/app/public/logo` and `/var/www/app/storage`.

The MySQL volume is already mounted to `/srv/invoiceninja/data` so to persist data stored in MySQL (ex. invoices).

All the supported environment variable can be found here https://github.com/invoiceninja/invoiceninja/blob/master/.env.example


### Usage

To run it:

```
docker run -d
  -e APP_ENV='production'
  -e APP_DEBUG=0
  -e APP_URL='http://ninja.dev'
  -e APP_KEY='SomeRandomStringSomeRandomString'
  -e APP_CIPHER='AES-256-CBC'
  -e DB_TYPE='mysql'
  -e DB_STRICT='false'
  -e DB_HOST='localhost'
  -e DB_DATABASE='ninja'
  -e DB_USERNAME='ninja'
  -e DB_PASSWORD='ninja'
  -p '80:80'
  invoiceninja/invoiceninja
```
A list of environment variables can be found [here](https://github.com/invoiceninja/invoiceninja/blob/master/.env.example)


### Know issue

Phantomjs doesn't work on linux alpine https://github.com/ariya/phantomjs/issues/14186
