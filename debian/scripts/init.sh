#!/bin/sh -eu

app_dir=${APP_DIR:-/app}
role=${LARAVEL_ROLE:-app}

if [ "$*" = 'frankenphp run --config /etc/caddy/Caddyfile --adapter caddyfile' ]; then

    if [ "${role}" = "app" ]; then
        if [ "$APP_ENV" = "production" ]; then
            frankenphp php-cli "${app_dir}"/artisan optimize
        fi

        frankenphp php-cli "${app_dir}"/artisan package:discover

        frankenphp php-cli "${app_dir}"/artisan migrate --force

        # If first IN run, it needs to be initialized
        if [ "$(frankenphp php-cli "${app_dir}"/artisan tinker --execute='echo Schema::hasTable("accounts") && !App\Models\Account::all()->first();')" = "1" ]; then
            echo "Running initialization..."

            frankenphp php-cli "${app_dir}"/artisan db:seed --force

            if [ -n "${IN_USER_EMAIL}" ] && [ -n "${IN_PASSWORD}" ]; then
                frankenphp php-cli "${app_dir}"/artisan ninja:create-account --email "${IN_USER_EMAIL}" --password "${IN_PASSWORD}"
            else
                echo "Initialization failed - Set IN_USER_EMAIL and IN_PASSWORD in .env"
                exit 1
            fi
        fi
        echo "Production setup completed"
    elif [ "${role}" = "worker" ]; then
        exec frankenphp php-cli "${app_dir}"/artisan queue:work -v --sleep=3 --tries=3 --max-time=3600
    elif [ "${role}" = "scheduler" ]; then
        exec frankenphp php-cli "${app_dir}"/artisan schedule:work -v
    else
        echo "Invalid role: ${role}"
        exit 1
    fi

fi

exec "$@"
