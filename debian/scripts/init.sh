#!/bin/sh
set -e

in_log() {
    local type="$1"
    shift
    printf '%s [%s] [Entrypoint]: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$type" "$*"
}

docker_process_init_files() {
    echo
    local f
    for f; do
        case "$f" in
        *.sh)
            # https://github.com/docker-library/postgres/issues/450#issuecomment-393167936
            # https://github.com/docker-library/postgres/pull/452
            if [ -x "$f" ]; then
                in_log INFO "$0: running $f"
                "$f"
            else
                in_log INFO "$0: sourcing $f"
                . "$f"
            fi
            ;;
        *) in_log INFO "$0: ignoring $f" ;;
        esac
        echo
    done
}

if [ "$*" = 'supervisord -c /etc/supervisor/conf.d/supervisord.conf' ]; then
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
        echo "Checking initialization status..."
        IN_INIT=$(php -d opcache.preload='' artisan tinker --execute='echo Schema::hasTable("accounts") && !App\Models\Account::all()->first();')
        echo "IN_INIT value: $IN_INIT"

        if [ "$IN_INIT" = "1" ]; then
            echo "Running initialization scripts..."
            docker_process_init_files /docker-entrypoint-init.d/*
        fi

        echo "Production setup completed"
        echo "IN_INIT value: $IN_INIT"

    fi

    echo "Starting supervisord..."
fi

exec "$@"
