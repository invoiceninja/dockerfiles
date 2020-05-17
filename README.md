# Docker for [Invoice Ninja](https://www.invoiceninja.com/) 

:bulb: Please consider posting your question on [StackOverflow](https://stackoverflow.com/) as this widens the audience that can help you. Just use the tag `invoice-ninja` and we are there to help. This is mostly related to the usage of Invoice Ninja and the docker setup.
If you feel your question is directly related to a code change or you want to sent in a change + PR Github is the right place, of course.

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

### PhantomJS key

The PhantomJS key is set to `a-demo-key-with-low-quota-per-ip-address`. This demo key is limited to 100 requests per day.

To set a different key feel free to add `-e PHANTOMJS_CLOUD_KEY='<INSERT YOUR PHANTOMJS KEY HERE>'` to thee docker command below.

For further configuration and toubleshotting regarding PhantomJS and Invoice Ninja [see documentation here](https://docs.invoiceninja.com/configure.html?#phantomjs).


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


## Debugging your Docker setup

Even when running your Invoice Ninja setup with Docker - errors can occur. Depending on where the error happens - the webserver, Invoice Ninja or the database - different log files can be responsible. 

### Show logs without `docker-compose`

If you are not running the `docker-compose` you first need to find the container id for your php container with `docker ps`. Then you can run

```shell
docker logs -f <CONTAINER NAME>
```

This gives you a constant output of the log files for the php container.

### Show logs with `docker-compose`

If you are running the `docker-compose` setup you can output all logs, from all containers, with the following command

```shell
docker-compose logs -f
```

If you better want a physical log file in in your `storage/logs` folder, just add `-e LOG=single` to the [usage](#usage) command. 
Or add an environment variable 

```yml
...
environment:
  LOG: single
...
```

to your `docker-compose.yml`.

This generated log file will only hold Invoice Ninja information.


### Known issues

Phantomjs doesn't work on linux alpine https://github.com/ariya/phantomjs/issues/14186.
