DockerFile for invoice ninja (https://www.invoiceninja.com/)

This image is based on `php:7` official version.

The easiest way to try this image is by cloning this repos and run `docker-compose run`.

To make your data persistant, you have to mount `/var/www/app/public/logo` and `/var/www/app/storage`.
