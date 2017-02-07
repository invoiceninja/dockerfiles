DockerFile for invoice ninja (https://www.invoiceninja.com/)

This image is based on `php:7` official version.

The easiest way to test Invoice Ninja with docker is by copying the example directory, run `docker-compose up` and visit http://localhost:8000/ .
The first launch could be slow because we create all tables and seed the database, but once youe see `NOTICE: ready to handle connections` all is ready.

To make your data persistent, you have to mount `/var/www/app/public/logo` and `/var/www/app/storage`.

All the supported environment variable can be found here https://github.com/invoiceninja/invoiceninja/blob/master/.env.example

### First run
Initializing the database can be done as follows:
```
docker run -it --rm \
  -e APP_ENV='production' \
  -e APP_DEBUG=0 \
  -e APP_URL='http://localhost' \
  -e APP_KEY='SomeRandomStringSomeRandomString' \
  -e APP_CIPHER='AES-256-CBC' \
  -e DB_TYPE='mysql' \
  -e DB_STRICT='false' \
  -e DB_HOST='localhost' \
  -e DB_DATABASE='ninja' \
  -e DB_USERNAME='ninja' \
  -e DB_PASSWORD='ninja' \
  invoiceninja/invoiceninja initdb
```
> This eliminates the problem of server timeouts happening when doing an installation via the web installer.

### Usage

To run it:

```
docker run -d \
  -e APP_ENV='production' \
  -e APP_DEBUG=0 \
  -e APP_URL='http://localhost' \
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
A list of environment variables can be found [here](https://github.com/invoiceninja/invoiceninja/blob/master/.env.example)


