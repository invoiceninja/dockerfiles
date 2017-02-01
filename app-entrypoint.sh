#!/bin/bash
set -e

rsync -a /var/www/app/docker-new-storage/ /var/www/app/storage/
rsync -a /var/www/app/docker-new-public/ /var/www/app/public/

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

#if [ ! -e "/var/www/app/is-seeded" ]; then
	#php artisan db:seed --force
	#touch "/var/www/app/is-seeded"
#fi

echo 'start'
exec "$@"
