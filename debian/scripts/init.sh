#!/usr/bin/env bash
set -Eeuo pipefail

# Allows the value of VAR to be read from the file at VAR_FILE for Docker compose's secrets feature
# (ie: APP_KEY_FILE=/run/secrets/app_key fills in APP_KEY).
file_env() {
    local var="${1:?missing variable name}"
    local file_var="${var}_FILE"

    if [[ -n "${!var:-}" && -n "${!file_var:-}" ]]; then
        echo "ERROR: both ${var} and ${file_var} are set (but are exclusive)" >&2
        exit 1
    fi

    if [[ -z "${!var:-}" && -n "${!file_var:-}" ]]; then
        local file="${!file_var}"
        [[ -f "$file" ]] || {
            echo "ERROR: ${file_var} points to missing file: ${file}" >&2
            exit 1
        }
        export "$var"="$(<"$file")" # trailing newline of the secret file is stripped
        unset "$file_var"          # keep the _FILE path out of the app environment
    fi
}

# Secrets that may be provided as files (add more as needed)
for var in \
    APP_KEY \
    DB_USERNAME DB_PASSWORD \
    REDIS_PASSWORD \
    MAIL_USERNAME MAIL_PASSWORD \
    IN_PASSWORD \
    AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY \
    R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY \
    NORDIGEN_SECRET_ID NORDIGEN_SECRET_KEY \
    GOCARDLESS_CLIENT_SECRET \
    ; do
    file_env "$var"
done

# Set PDF generation browser path based on architecture
if [ "$(dpkg --print-architecture)" = "amd64" ]; then
    export SNAPPDF_CHROMIUM_PATH=/usr/bin/google-chrome-stable
elif [ "$(dpkg --print-architecture)" = "arm64" ]; then
    export SNAPPDF_CHROMIUM_PATH=/usr/bin/chromium
fi

if [ "$*" = 'supervisord -c /etc/supervisor/supervisord.conf' ]; then

    # Check for required folders and create if needed
    [ -d /var/www/html/public ] || mkdir -p /var/www/html/public
    [ -d /var/www/html/storage/app/public ] || mkdir -p /var/www/html/storage/app/public
    [ -d /var/www/html/storage/framework/sessions ] || mkdir -p /var/www/html/storage/framework/sessions
    [ -d /var/www/html/storage/framework/views ] || mkdir -p /var/www/html/storage/framework/views
    [ -d /var/www/html/storage/framework/cache ] || mkdir -p /var/www/html/storage/framework/cache

    # Workaround for application updates
    if [ "$(ls -A /tmp/public)" ]; then
        echo "Updating public folder..."
        rm -rf /var/www/html/public/.htaccess \
            /var/www/html/public/.well-known \
            /var/www/html/public/*
        cp -r /tmp/public/* \
            /tmp/public/.htaccess \
            /tmp/public/.well-known \
            /var/www/html/public/ &&
            rm -rf /tmp/public/.htaccess \
                /tmp/public/.well-known \
                /tmp/public/*

    fi
    echo "Public Folder is up to date"

    # Ensure owner, file and directory permissions are correct
    chown -R www-data:www-data \
        /var/www/html/public \
        /var/www/html/storage
    find /var/www/html/public \
        /var/www/html/storage \
        -type f -exec chmod 644 {} \;
    find /var/www/html/public \
        /var/www/html/storage \
        -type d -exec chmod 755 {} \;

    # Clear and cache config in production
    if [ "${APP_ENV}" = "production" ]; then
        runuser -u www-data -- php artisan migrate --force
        runuser -u www-data -- php artisan cache:clear # Clear after the migration
        runuser -u www-data -- php artisan ninja:design-update
        runuser -u www-data -- php artisan optimize

        # If first IN run, it needs to be initialized
        if [ "$(runuser -u www-data -- php artisan tinker --execute='echo Schema::hasTable("accounts") && !App\Models\Account::all()->first();')" = "1" ]; then
            echo "Running initialization..."

            runuser -u www-data -- php artisan db:seed --force

            if [ -n "${IN_USER_EMAIL}" ] && [ -n "${IN_PASSWORD}" ]; then
                runuser -u www-data -- php artisan ninja:create-account --email "${IN_USER_EMAIL}" --password "${IN_PASSWORD}"
            else
                echo "Initialization failed - Set IN_USER_EMAIL and IN_PASSWORD in .env"
                exit 1
            fi

        fi
        echo "Production setup completed"
    fi

    echo "Starting supervisord..."
fi

exec "$@"
