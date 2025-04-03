#!/bin/sh -eu

# Set PDF generation browser path based on architecture
if [ "$(dpkg --print-architecture)" = "amd64" ]; then
    export SNAPPDF_CHROMIUM_PATH=/usr/bin/google-chrome-stable
elif [ "$(dpkg --print-architecture)" = "arm64" ]; then
    export SNAPPDF_CHROMIUM_PATH=/usr/bin/chromium
fi

if [ "$*" = 'supervisord -c /etc/supervisor/conf.d/supervisord.conf' ]; then

    # Check for required folders and create if needed
    [ -d /var/www/html/storage/framework/sessions ] || mkdir -p /var/www/html/storage/framework/sessions
    [ -d /var/www/html/storage/framework/views ] || mkdir -p /var/www/html/storage/framework/views
    [ -d /var/www/html/storage/framework/cache ] || mkdir -p /var/www/html/storage/framework/cache

    # Workaround for application updates
    if [ "$(ls -A /tmp/public)" ]; then
        echo "Updating public folder..."
        rm -rf /var/www/html/public/.htaccess \
            /var/www/html/public/.well-known \
            /var/www/html/public/*
        mv /tmp/public/* \
            /tmp/public/.htaccess \
            /tmp/public/.well-known \
            /var/www/html/public/
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
    if [ "$APP_ENV" = "production" ]; then
        runuser -u www-data -- php artisan optimize
        runuser -u www-data -- php artisan package:discover
        runuser -u www-data -- php artisan migrate --force

        # If first IN run, it needs to be initialized
        if [ "$(php -d opcache.preload='' artisan tinker --execute='echo Schema::hasTable("accounts") && !App\Models\Account::all()->first();')" = "1" ]; then
            echo "Running initialization..."

            php artisan db:seed --force

            if [ -n "${IN_USER_EMAIL}" ] && [ -n "${IN_PASSWORD}" ]; then
                php artisan ninja:create-account --email "${IN_USER_EMAIL}" --password "${IN_PASSWORD}"
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