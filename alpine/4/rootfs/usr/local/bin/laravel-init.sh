#!/bin/sh

php artisan config:cache
php artisan optimize
php artisan migrate --force
