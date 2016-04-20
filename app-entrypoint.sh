#!/bin/bash
set -e


# if we're linked to MySQL, and we're using the root user, and our linked
# container has a default "root" password set up and passed through... :)
: ${DB_USERNAME:=root}
if [ "$DB_USERNAME" = 'root' ]; then
	: ${DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi

echo "DB_USERNAME=$DB_USERNAME" >> .env
echo "DB_PASSWORD=$DB_PASSWORD" >> .env

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
	cp -Rp /var/www/app/docker-backup-public-logo /var/www/app/public/logo
else
	IN_LOGO_BACKUP="$(ls /var/www/app/docker-backup-public-logo/)"
	for path in $IN_LOGO_BACKUP; do
		if [ ! -e "/var/www/app/public/logo/$path" ]; then
			cp -Rp "/var/www/app/docker-backup-public-logo/$path" "/var/www/app/public/logo/"
		fi
	done
fi

chown www-data .env

exec "$@"
