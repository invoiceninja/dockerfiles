DockerFile for invoice ninja (https://www.invoiceninja.com/)

This image is based on `php:7.0-fpm` official version.

To make your data persistent, you have to mount `/var/www/app/public/logo` and `/var/www/app/storage`.


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
  -e PHANTOMJS_SECRET=`gVBUWzLjRWQq0lLqiO5RnGHvugUn+OuszNvymIiGex4jtrqznQa278sxHNNZZuhls54FhXWs9wFqN2pYmy8zKHEsMJoi60CSMZ6hkMiOymCf1IbHr2SxmidXeYyW+ZO6QjW6T2SwiJQH2fUFN82/yxtKHaDMz+7ilNQjZ0RGCQI=`
  -p '80:80'
  invoiceninja/invoiceninja
```
A list of environment variables can be found [here](https://github.com/invoiceninja/invoiceninja/blob/master/.env.example)


### Generating random variables

Following variables should be random for your invoice ninja instance to be safe:

* `APP_KEY` --- to generate app key run following command::
        
      docker run -e APP_CIPHER='AES-256-CBC' -it --rm invoiceninja/invoiceninja php artisan key:generate
   
   Variable you need will be in the last line of output, in my case it was: `base64:WEMBumE5uARlC2PfrQ0WhcGN6lDTDwHubOGd3AyM7Ho=`
   
* `PHANTOMJS_SECRET` ---  Any random string with good entropy. For example to generate it run:: 

      cat /dev/urandom | head -c 128 | base64 -w0        

### With docker-compose

A pretty ready to use docker-compose configuration can be found into [`./docker-compose`](https://github.com/invoiceninja/dockerfiles/tree/master/docker-compose).
Rename `.env.example` into `.env` and change the environment's variable as needed.
The file assume that all your persistent data is mounted from `/srv/invoiceninja/`.
Once started the application should be accessible at http://localhost:8000/

### Know issue

Phantomjs doesn't work on linux alpine https://github.com/ariya/phantomjs/issues/14186
