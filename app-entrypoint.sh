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

chown www-data:www-data /var/www/app/.env

# widely inspired from https://github.com/docker-library/wordpress/blob/c674e9ceedf582705e0ad8487c16b42b37a5e9da/fpm/docker-entrypoint.sh#L128
TERM=dumb php -- "$DB_HOST" "$DB_USERNAME" "$DB_PASSWORD" "$DB_DATABASE" <<'EOPHP'
<?php
$stderr = fopen('php://stderr', 'w');
list($host, $port) = explode(':', $argv[1], 2);
$maxTries = 20;
do {
	try {
		$connection = new Pdo("mysql:dbname={$argv[4]};host={$host};port={$port}", $argv[2], $argv[3]);
		fwrite($stderr, 'MySQL ready'. "\n");
		exit(0);
	} catch (PDOException $e) {
    fwrite($stderr, 'MySQL Connection Error: ' . $e->getMessage(). "\n");
		if (--$maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while (true);
EOPHP

#php artisan optimize --force
#php artisan migrate --force

if [ ! -e "/var/www/app/is-seeded" ]; then
	#php artisan db:seed --force
	#touch "/var/www/app/is-seeded"
fi

echo 'start'
exec "$@"
