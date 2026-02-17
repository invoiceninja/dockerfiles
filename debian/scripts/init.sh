#!/bin/sh -eu

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

    # Sync public folder from image to volume
    echo "Updating public folder..."
    rsync -a --delete /tmp/public/ /var/www/html/public/
    echo "Public folder is up to date"

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
