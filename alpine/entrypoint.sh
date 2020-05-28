#!/usr/bin/env sh
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		mysql_error "Both $var and $fileVar are set (but are exclusive)"
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi


if [ ! -d /var/www/app/storage ]; then
    cp -Rp /var/www/app/docker-backup-storage /var/www/app/storage
else
    IN_STORAGE_BACKUP="$(ls /var/www/app/docker-backup-storage/)"
    for path in $IN_STORAGE_BACKUP; do
        if [ ! -e "/var/www/app/storage/$path" ]; then
            cp -Rp "/var/www/app/docker-backup-storage/$path" "/var/www/app/storage/"
        fi
    done
fi

if [ ! -d /var/www/app/public/logo ]; then
    cp -Rp /var/www/app/docker-backup-public/logo /var/www/app/public/logo
else
    IN_LOGO_BACKUP="$(ls /var/www/app/docker-backup-public/logo/)"
    for path in $IN_LOGO_BACKUP; do
        if [ ! -e "/var/www/app/public/logo/$path" ]; then
            cp -Rp "/var/www/app/docker-backup-public/logo/$path" "/var/www/app/public/logo/"
        fi
    done
fi

# compare public volume version with image version
if [ ! -e /var/www/app/public/version ] || [ "$INVOICENINJA_VERSION" != "$(cat /var/www/app/public/version)" ]; then
    cp -au /var/www/app/docker-backup-public/* /var/www/app/public/
    echo $INVOICENINJA_VERSION > /var/www/app/public/version
fi

# Set permission for mounted directories
chown invoiceninja:www-data /var/www/app/storage
chown invoiceninja:www-data /var/www/app/public

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


exec docker-php-entrypoint "$@"
