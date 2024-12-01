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

# Ensure owner, file and directory permissions are correct
chown -R www-data:www-data /var/www/html/
find /var/www/html/ -type f -exec chmod 644 {} \;
find /var/www/html/ -type d -exec chmod 755 {} \;

# Clear and cache config in production
if [ "$APP_ENV" = "production" ]; then
    gosu www-data php artisan optimize
    gosu www-data php artisan package:discover
    gosu www-data php artisan migrate --force

    echo "Checking initialization status..."

    # If first IN run, it needs to be initialized
    echo "Checking initialization status..."
    IN_INIT=$(php artisan tinker --execute='echo Schema::hasTable("accounts") && !App\Models\Account::all()->first();')
    echo "IN_INIT value: $IN_INIT"

    if [ "$IN_INIT" = "1" ]; then
        echo "Running initialization scripts..."
        docker_process_init_files /docker-entrypoint-init.d/*
    fi

    echo "Production setup completed"
    echo "IN_INIT value: $IN_INIT"

fi

echo "Starting supervisord..."
# Start supervisord in the foreground
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
