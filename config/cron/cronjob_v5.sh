#!/usr/bin/env sh

cd /var/www/app; php artisan schedule:run >> /dev/null 2>&1
