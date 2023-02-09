#!/bin/sh

php artisan db:seed --force

# Build up array of arguments...
if [[ ! -z "${IN_USER_EMAIL}" ]]; then
    email="--email ${IN_USER_EMAIL}"
fi

if [[ ! -z "${IN_PASSWORD}" ]]; then
    password="--password ${IN_PASSWORD}"
fi

php artisan ninja:create-account $email $password
php artisan ninja:react