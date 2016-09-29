DockerFile for invoice ninja (https://www.invoiceninja.com/)

This image is based on `php:7` official version.

The easiest way to test Invoice Ninja with docker is by copying the exemple directory and run `docker-compose up`.
The first launch could be slow because we create all tables and seed the database, but once youe see `NOTICE: ready to handle connections` all is ready.

To make your data persistant, you have to mount `/var/www/app/public/logo` and `/var/www/app/storage`.
