#!/bin/sh -eu


if [ "--help" = "$1" ]; then
    echo [FLAGS]
    echo The CMD defined can be extended with flags for artisan commands
    echo
    echo Available flags can be displaced:
    echo docker run --rm invoiceninja/invoiceninja-debian frankenphp php-cli artisan help octane:frankenphp
    echo docker run --rm invoiceninja/invoiceninja-debian frankenphp php-cli artisan help queue:work
    echo docker run --rm invoiceninja/invoiceninja-debian frankenphp php-cli artisan help schedule:work
    echo
    echo Example:
    echo docker run -e LARAVEL_ROLE=worker invoiceninja/invoiceninja-debian --verbose --sleep=3 --tries=3 --max-time=3600
    echo
    echo [Deployment]
    echo Docker compose is recommended
    echo
    echo Example:
    echo https://github.com/invoiceninja/dockerfiles/blob/octane/debian/docker-compose.yml
    echo
    exit 0
fi

if [ "${LARAVEL_ROLE}" = "app" ] && { [ "$*" = 'frankenphp php-cli artisan octane:frankenphp' ] || [ "${1#-}" != "$1" ]; } ; then
    cmd="frankenphp php-cli artisan octane:frankenphp"
    
        if [ "$APP_ENV" = "production" ]; then
            frankenphp php-cli artisan optimize
        fi

        frankenphp php-cli artisan package:discover

        # Run migrations (if any)
        frankenphp php-cli artisan migrate --force

        # If first IN run, it needs to be initialized
        if [ "$(php -d opcache.preload='' artisan tinker --execute='echo Schema::hasTable("accounts") && !App\Models\Account::all()->first();')" = "1" ]; then
            echo "Running initialization..."

            frankenphp php-cli artisan db:seed --force

            if [ -n "${IN_USER_EMAIL}" ] && [ -n "${IN_PASSWORD}" ]; then
                frankenphp php-cli artisan ninja:create-account --email "${IN_USER_EMAIL}" --password "${IN_PASSWORD}"
            else
                echo "Initialization failed - Set IN_USER_EMAIL and IN_PASSWORD in .env"
                exit 1
            fi
        fi
fi

if [ "${LARAVEL_ROLE}" = "scheduler" ] && { [ "$*" = 'frankenphp php-cli artisan schedule:work' ] || [ "${1#-}" != "$1" ]; } ; then
    cmd="frankenphp php-cli artisan schedule:work"
fi

if [ "${LARAVEL_ROLE}" = "worker" ] && { [ "$*" = 'frankenphp php-cli artisan queue:work' ] || [ "${1#-}" != "$1" ]; } ; then
    cmd="frankenphp php-cli artisan queue:work"
fi

# Append flag(s) to role cmd
if [ "${1#-}" != "$1" ]; then
    set -- ${cmd} "$@"
else
    set -- ${cmd}
fi

exec "$@"
