#!/bin/bash
set -e

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

# docker command initdb
if [ "$@" == "initdb" ]; then
  echo 'initialize database'
  php artisan optimize --force
  php artisan migrate --force
  php artisan db:seed --force
fi

echo 'start app'
exec "$@"
