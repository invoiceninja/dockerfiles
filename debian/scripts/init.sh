#!/bin/sh -eu

# Fallback to app
role=${LARAVEL_ROLE:-app}

# Set PDF generation browser path based on architecture
export SNAPPDF_CHROMIUM_PATH=/usr/bin/google-chrome-stable
if [ "$(dpkg --print-architecture)" = "arm64" ]; then
    export SNAPPDF_CHROMIUM_PATH=/usr/bin/chromium
fi

# Check for default CMD, flag(s) or empty CMD
if [ "$*" = 'frankenphp php-cli artisan octane:frankenphp' ] || [ "${1#-}" != "$1" ] || [ "$#" -eq  "0" ]; then

    if [ "--help" = "$1" ]; then
        echo [CMD]
        echo "This image will execute specific CMDs based on the environment variable LARAVEL_ROLE"
        echo
        echo "LARAVEL_ROLE=app:       frankenphp php-cli artisan octane:frankenphp (default)"
        echo "LARAVEL_ROLE=worker:    frankenphp php-cli artisan queue:work"
        echo "LARAVEL_ROLE=scheduler: frankenphp php-cli artisan schedule:work"
        echo
        echo [FLAGS]
        echo To the CMD defined by LARAVEL_ROLE can be extended with flags for artisan commands
        echo
        echo Available flags can be displaced:
        echo docker run --rm invoiceninja/invoiceninja-debian frankenphp php-cli artisan help octane:frankenphp
        echo docker run --rm invoiceninja/invoiceninja-debian frankenphp php-cli artisan queue:work
        echo docker run --rm invoiceninja/invoiceninja-debian frankenphp php-cli artisan schedule:work
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

    # Run app
    if [ "${role}" = "app" ]; then
        cmd="frankenphp php-cli artisan octane:frankenphp"

        # Check for required folders and create if needed, relevant for bind mounts
        # It is not possible to chown, as we are not executing this script as root
        [ -d /app/storage/framework/sessions ] || mkdir -p /app/storage/framework/sessions
        [ -d /app/storage/framework/views ] || mkdir -p /app/storage/framework/views
        [ -d /app/storage/framework/cache ] || mkdir -p /app/storage/framework/cache
        [ -d /app/storage/logs ] || mkdir -p /app/storage/logs

        if [ "$APP_ENV" = "production" ]; then
            frankenphp php-cli artisan optimize
        fi

        frankenphp php-cli artisan package:discover

        # Run migrations (if any)
        frankenphp php-cli artisan migrate --force

        # If first IN run, it needs to be initialized
        if [ "$(frankenphp php-cli artisan tinker --execute='echo Schema::hasTable("accounts") && !App\Models\Account::all()->first();')" = "1" ]; then
            echo "Running initialization..."

            frankenphp php-cli artisan db:seed --force

            if [ -n "${IN_USER_EMAIL}" ] && [ -n "${IN_PASSWORD}" ]; then
                frankenphp php-cli artisan ninja:create-account --email "${IN_USER_EMAIL}" --password "${IN_PASSWORD}"
            else
                echo "Initialization failed - Set IN_USER_EMAIL and IN_PASSWORD in .env"
                exit 1
            fi
        fi

        echo "Production setup completed"
    # Run worker
    elif [ "${role}" = "worker" ]; then
        cmd="frankenphp php-cli artisan queue:work"
    # Run scheduler
    elif [ "${role}" = "scheduler" ]; then
        cmd="frankenphp php-cli artisan schedule:work"
    # Invalid role
    else
        echo "Invalid role: ${role}"
        exit 1
    fi

    # Append flag(s) to role cmd
    if [ "${1#-}" != "$1" ]; then
        set -- ${cmd} "$@"
    else
        set -- ${cmd}
    fi
fi

exec "$@"
