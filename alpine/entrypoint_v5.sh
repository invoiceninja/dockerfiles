#!/usr/bin/env sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

BAK_STORAGE_PATH=/var/www/app/docker-backup-storage/
BAK_LOGO_PATH=/var/www/app/docker-backup-public/logo/

if [ ! -d /var/www/app/storage ]; then
    cp -Rp $BAK_STORAGE_PATH /var/www/app/storage
else
    if [ -d $BAK_STORAGE_PATH ]; then
        IN_STORAGE_BACKUP="$(ls $BAK_STORAGE_PATH)"
        for path in $IN_STORAGE_BACKUP; do
            if [ ! -e "/var/www/app/storage/$path" ]; then
                cp -Rp "$BAK_STORAGE_PATH/$path" "/var/www/app/storage/"
            fi
        done
    fi
fi

if [ ! -d /var/www/app/public/logo ] && [ -d $BAK_LOGO_PATH ]; then
    cp -Rp $BAK_LOGO_PATH /var/www/app/public/logo
else
    if [ -d $BAK_LOGO_PATH ]; then
        IN_LOGO_BACKUP="$(ls $BAK_LOGO_PATH)"
        for path in $IN_LOGO_BACKUP; do
            if [ ! -e "/var/www/app/public/logo/$path" ]; then
                cp -Rp "$BAK_LOGO_PATH/$path" "/var/www/app/public/logo/"
            fi
        done
    fi
fi

# compare public volume version with image version
if [ ! -e /var/www/app/public/version ] || [ "$INVOICENINJA_VERSION" != "$(cat /var/www/app/public/version)" ]; then
    cp -au /var/www/app/docker-backup-public/* /var/www/app/public/
    echo $INVOICENINJA_VERSION > /var/www/app/public/version
fi

# Set permission for mounted directories
chown invoiceninja:www-data /var/www/app/storage
chown invoiceninja:www-data /var/www/app/public

php artisan optimize

exec docker-php-entrypoint "$@"
