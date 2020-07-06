![Docker images](https://github.com/invoiceninja/dockerfiles/workflows/Docker%20images/badge.svg)
[![Docker image, latest](https://img.shields.io/docker/image-size/invoiceninja/invoiceninja/latest?label=latest)](https://hub.docker.com/r/invoiceninja/invoiceninja)
[![Docker image, alpine](https://img.shields.io/docker/image-size/invoiceninja/invoiceninja/alpine?label=alpine)](https://hub.docker.com/r/invoiceninja/invoiceninja)

# Docker for [Invoice Ninja](https://www.invoiceninja.com/) 

:bulb: Please consider posting your question on [StackOverflow](https://stackoverflow.com/) as this widens the audience that can help you. Just use the tag `invoice-ninja` and we are there to help. This is mostly related to the usage of Invoice Ninja and the docker setup.
If you feel your question is directly related to a code change or you want to sent in a change + PR Github is the right place, of course.

:crown: **Features**

:lock: Automatic HTTPS (:heart: [Caddy](https://caddyserver.com/))  
:hammer: Fully production-ready through docker-compose  
:pencil: Adjustable to your needs via environment variable  


## Prerequisites

### Generate an application key

Before starting Invoice Ninja via Docker make sure you generate a valid application key. If you are not sure what an application key is, please visit [this blog post](https://tighten.co/blog/app-key-and-you/).  

To generate an application key just run

```shell
docker run --rm -it invoiceninja/invoiceninja php artisan key:generate --show
```

This will generate an application key for you which you need later.

### Create folders for data persistence

To make your data persistent, you have to mount `public` and `storage` from your host to your containers.

1. Create two folder on your host, e. g. `/var/invoiceninja/public` and `/var/invoiceninja/storage`
2. Mount these folders into your container - see [usage](#usage)

You can create these folders wherever you want on your host system.

:warning: When using host mounted folder for persistence, make sure they are owned by the proper user and group. As we run Invoice Ninja without `root` , we use a separate user, the folders on the host system need to be owned by uid `1000` and a gid `101`.  

Run this on your host system

```shell
chown -R 1000:101 /var/invoiceninja/public /var/invoiceninja/storage
```

to apply the proper permission to the folders. This also applies to the `docker-compose` setup when using [bind-mounted host directories](https://github.com/invoiceninja/dockerfiles/blob/master/docker-compose.yml#L17).


### PhantomJS key

The PhantomJS key is set to `a-demo-key-with-low-quota-per-ip-address`. This demo key is limited to 100 requests per day.

To set a different key feel free to add `-e PHANTOMJS_CLOUD_KEY='<INSERT YOUR PHANTOMJS KEY HERE>'` to thee docker command below.

For further configuration and toubleshotting regarding PhantomJS and Invoice Ninja [see documentation here](https://docs.invoiceninja.com/configure.html?#phantomjs).


## Usage

:warning: The `latest` tag contains the new version 5 of Invoice Ninja which is still in alpha state. To stick to the version 4 please use `alpine-4` tag.

To run it:

```shell
docker run -d \
  -v /var/invoiceninja/public:/var/app/public \
  -v /var/invoiceninja/storage:/var/app/storage \
  -e APP_URL='http://ninja.dev' \
  -e APP_KEY='<INSERT THE GENERATED APPLICATION KEY HERE>' \
  -e DB_HOST='localhost' \
  -e DB_DATABASE='ninja' \
  -e DB_USERNAME='ninja' \
  -e DB_PASSWORD='ninja' \
  -p '9000:9000' \
  --name invoiceninja \
  invoiceninja/invoiceninja:alpine-4
```
A list of environment variables can be found [here](https://github.com/invoiceninja/invoiceninja/blob/master/.env.example).


### With docker-compose

Running Invoice Ninja with docker-compose gives you everything to quickly start. Before starting please make sure you configured your setup correctly. You can do so by opening the `docker-compose.yml` and may change the follwing items.

:warning: The `docker-compose.yml` runs the new version 5 of Invoice Ninja which is still in alpha state. To stick to the version 4 please use `alpine-4` tag.

**Port**

_default: 80_  

This is the port where your Invoice Ninja is reachable, when you type in `http://<your-domain.com>`. If it should be different than `80` make sure to call your installation `http://<your-domain.com>:<YOUR-PORT>`, e. g. `http://<your-domain.com>:8080`.

```yml
ports: 
  - "8080:80" # To run it on port 8080
```

:warning: Make sure the port set is available and not occupied by another service on your host system.

**URL and application key**

_default: https://localhost_

For generating a proper application key see [generate an application key](#generate-an-application-key). Change the value where your Invoice Ninja installation should be reachable.

```yml
environment: 
  - APP_URL=http://localhost
````

**MYSQL root password**

_default: ninjaAdm1nPassword_

The mysql database server comes with two users: one for accessing the Invoice Ninja database and the `root` user. Please change the default password for `root` to something more special :wink:

**Volumes and directories**

_default: volumes_

This is the place where your uploaded files are stored. Normally this is a so called _volume_ which can be reused by different docker containers. One might prefer to store the files directly on the host system - for this the config section is prepared with what is called _bind-mounted host directory_. Just adjust the paths and Invoice Ninja stores the user files on the host system.

```yml
volumes:
  ...
  # Configure your mounted directories, make sure the folder 'public' and 'storage'
  # exist, before mounting them
  #-  public:/var/www/app/public
  #-  storage:/var/www/app/storage
  # you may use a bind-mounted host directory instead, so that it is harder to accidentally remove the volume and lose all your data!
  - ./docker/app/public:/var/www/app/public:rw,delegated
  - ./docker/app/storage:/var/www/app/storage:rw,delegated
```

The sample above stores the files on the post at `./docker/app/public` and `./docker/app/storage`.

:warning: If using bind-mounted host directories make sure they exists and have proper rights. See [here](#create-folders-for-data-persistence) for details.

## Docker secrets

:information_source: This feature is borrowed from [mariadb docker image](https://hub.docker.com/_/mariadb).

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the below listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in _/run/secrets/<secret_name>_ files.

Supported are these variables:  
`APP_KEY`, `API_SECRET`, `CLOUDFLARE_API_KEY`, `DB_USERNAME`, `DB_PASSWORD`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAILGUN_SECRET`, `S3_KEY`, `S3_SECRET`


## Debugging your Docker setup

Even when running your Invoice Ninja setup with Docker - errors can occur. Depending on where the error happens - the webserver, Invoice Ninja or the database - different log files can be responsible. 

### Show logs without `docker-compose`

If you are not running `docker-compose` you first need to find the container id for your php container with `docker ps`. Then you can run

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
