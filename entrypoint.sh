#!/bin/bash
set -e

DB_PORT=3306
mysqlcmd="mysql -uroot -h ${DB_HOST} -P ${DB_PORT} -p${MYSQL_ROOT_PASSWORD} "

function wait_for_db() {
  while [ ! "$(mysqladmin ping -h ${DB_HOST} -P ${DB_PORT} -u root \
              --password="${MYSQL_ROOT_PASSWORD}" --silent --connect_timeout=3)" ]; do
    echo "Database server is not available. Waiting 2 seconds..."
    sleep 2
  done
  echo "Database server is up !"
}

function create_db() {
  echo "Creating database..."
  $mysqlcmd -e "CREATE DATABASE IF NOT EXISTS ${DB_DATABASE};"
  [ $? -gt 0 ] && echo "Couldn't create database !!" && exit 1
	echo "Creating database user and assigning permissions..."
  $mysqlcmd -e " GRANT ALL ON ${DB_DATABASE}.* to '${DB_USERNAME}'@'%' identified by '${DB_PASSWORD}'";
  [ $? -gt 0 ] && echo "Couldn't create database user !!" && exit 1
	echo "Done."
}

#Wait for database to come up
wait_for_db
create_db

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
  echo 'clone public directory'
  cp -Rp /var/www/app/docker-backup-public/* /var/www/app/public/
  echo $INVOICENINJA_VERSION > /var/www/app/public/version
fi

#php artisan optimize --force
#php artisan migrate --force

#if [ ! -e "/var/www/app/is-seeded" ]; then
	#php artisan db:seed --force
	#touch "/var/www/app/is-seeded"
#fi

echo 'start'
exec "$@"
