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

php artisan config:cache
php artisan optimize
php artisan ninja:react

# Check if DB works, if not crash the app.
DB_READY=$(php artisan tinker --execute='echo app()->call("App\Utils\SystemHealth@dbCheck")["success"];')
if [ "$DB_READY" != "1" ]; then
    php artisan migrate:status # Print verbose error
    in_error "Error connecting to DB"
fi

php artisan migrate --force

# If first IN run, it needs to be initialized
IN_INIT=$(php artisan tinker --execute='echo Schema::hasTable("accounts") && !App\Models\Account::all()->first();')
if [ "$IN_INIT" == "1" ]; then
    docker_process_init_files /docker-entrypoint-init.d/*
fi
