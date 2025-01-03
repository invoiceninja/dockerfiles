#!/bin/sh -eu

# Fallback to app
role=${LARAVEL_ROLE:-app}

# Check for default CMD, flag(s) or empty CMD
if [ "$*" = 'frankenphp php-cli artisan octane:frankenphp' ] || [ "${1#-}" != "$1" ] || [ "$#" -eq  "0" ]; then

    # Run app
    if [ "${role}" = "app" ]; then
        cmd="frankenphp php-cli artisan octane:frankenphp"

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
