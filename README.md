# Docker for [Invoice Ninja](https://www.invoiceninja.com/) 

This image is based on `php:7.2-fpm` official version.

## Prerequisites

### Generate an application key

Before starting Invoice Ninja via Docker make sure you generate a valid application key. If you are not sure what an application key is, please visit [this blog post](https://tighten.co/blog/app-key-and-you/).  

To generate an application just run

```shell
docker run --rm -it invoiceninja/invoiceninja php artisan key:generate --show
```

This will generate an application key for you which you need later.

### Create folders for data persistence

To make your data persistent, you have to mount `public` and `storage` from your host to your containers.

1. Create two folder on your host, e. g. `/var/invoiceninja/public` and `/var/invoiceninja/storage`
2. Mount these folders into your container - see [usage](#usage)

You can create these folders wherever you want on your host system.

### Generate a PhantomJS key

If you use PhantomJS Cloud make sure you generated a secret key before starting Invoice Ninja. The following snippets will generate 10 char random keys.

**On Mac**

```shell
openssl rand -base64 10 | md5 |head -c10;echo
```

**On Linux**
```shell
head /dev/urandom | tr -dc A-Za-z0-9 | head -c 10 ; echo ''
```

## Usage

To run it:

```
docker run -d \
  -v /var/invoiceninja/public:/var/app/public \
  -v /var/invoiceninja/storage:/var/app/storage \
  -e APP_ENV='production' \
  -e APP_DEBUG=0 \
  -e APP_URL='http://ninja.dev' \
  -e APP_KEY='<INSERT THE GENERATED APPLICATION KEY HERE>' \
  -e APP_CIPHER='AES-256-CBC' \
  -e PHANTOMJS_CLOUD_KEY='<INSERT YOUR PHANTOMJS KEY HERE>' \
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
