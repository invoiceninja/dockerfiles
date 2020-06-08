#!/usr/bin/env sh
set -e

# logging functions
in_log() {
        local type="$1"; shift
        printf '%s [%s] [Entrypoint]: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$type" "$*"
}

in_error() {
        in_log ERROR "$@" >&2
        exit 1
}

# Indirect expansion (ie) is not supported in bourne shell. That's why we are using this "magic" here.
ie_gv() {
        eval "echo \$$1"
}

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
        local var="$1"
        local fileVar="${var}_FILE"
        local def="${2:-}"

        if [ "$(ie_gv ${var})" != ""  ] && [ "$(ie_gv ${fileVar})" != "" ]; then
                in_error "Both $var and $fileVar are set (but are exclusive)"
        fi

        local val="$def"
        if [ "$(ie_gv ${var})" != "" ]; then
                val=$(ie_gv ${var})
        elif [ "$(ie_gv ${fileVar})" != "" ]; then
                val=`cat $(ie_gv ${fileVar})`
        fi

        export "$var"="$val"
        unset "$fileVar"
}

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

# Set permission for web server to create/update files
chown -R invoiceninja:www-data /var/www/app/storage /var/www/app/public /var/www/app/bootstrap

# Initialize values that might be stored in a file
file_env 'APP_KEY'
file_env 'API_SECRET'
file_env 'CLOUDFLARE_API_KEY'
file_env 'DB_USERNAME'
file_env 'DB_PASSWORD'
file_env 'MAIL_USERNAME'
file_env 'MAIL_PASSWORD'
file_env 'MAILGUN_SECRET'
file_env 'S3_KEY'
file_env 'S3_SECRET'

# Run Laravel stuff
php artisan config:cache
php artisan optimize

exec docker-php-entrypoint "$@"
