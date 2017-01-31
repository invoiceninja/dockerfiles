#!/bin/bash
set -e

# overwrite updated files in the persistent volumes
rsync -a /var/www/app/docker-new-storage/ /var/www/app/storage/
rsync -a /var/www/app/docker-new-public/ /var/www/app/public/

#php artisan optimize --force
#php artisan migrate --force

#if [ ! -e "/var/www/app/is-seeded" ]; then
	#php artisan db:seed --force
	#touch "/var/www/app/is-seeded"
#fi

echo 'start'
exec "$@"
