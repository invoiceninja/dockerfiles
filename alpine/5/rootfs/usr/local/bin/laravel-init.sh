#!/bin/sh

# usage: docker_process_init_files [file [file [...]]]
#    ie: docker_process_init_files /always-initdb.d/*
# process initializer files, based on file extensions
docker_process_init_files() {
    echo
    local f
    for f; do
        case "$f" in
        *.sh)
            # https://github.com/docker-library/postgres/issues/450#issuecomment-393167936
            # https://github.com/docker-library/postgres/pull/452
            if [ -x "$f" ]; then
                in_log "$0: running $f"
                "$f"
            else
                in_log "$0: sourcing $f"
                . "$f"
            fi
            ;;
        *) in_log "$0: ignoring $f" ;;
        esac
        echo
    done
}

php artisan config:cache
php artisan optimize

# Check if DB works, if not crash the app.
DB_READY=$(php artisan tinker --execute='try { DB::connection()->getPdo(); } catch (\Exception $e) { echo(1); return; } echo(0);')
if [ "$DB_READY" -ne "0" ]; then
    echo "Error connecting to DB"
    exit 1
fi

php artisan migrate --force

# If first IN run, it needs to be initialized
if [ ! -f /var/www/app/storage/.initialized ]; then
    docker_process_init_files /docker-entrypoint-init.d/*
    touch /var/www/app/storage/.initialized
fi
