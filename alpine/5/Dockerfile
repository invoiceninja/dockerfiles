ARG PHP_VERSION=8.3
ARG ALPINE_VERSION=3.20
ARG BAK_STORAGE_PATH=/var/www/app/docker-backup-storage/
ARG BAK_PUBLIC_PATH=/var/www/app/docker-backup-public/

# Get Invoice Ninja and install nodejs packages
FROM --platform=$BUILDPLATFORM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION}  AS nodebuild

# Download Invoice Ninja
ARG INVOICENINJA_VERSION
ARG REPOSITORY=invoiceninja/invoiceninja
ARG FILENAME=invoiceninja.tar

RUN mkdir -p /var/www/app

# Extract Invoice Ninja
RUN apk add --no-cache curl \
    && curl -s "https://api.github.com/repos/invoiceninja/invoiceninja/releases/latest" | \
    grep -o '"browser_download_url": "[^"]*invoiceninja.tar.gz"' | \
    cut -d '"' -f 4 | \
    xargs curl -sL | \
    tar -xz --strip-components=1 -C /var/www/app/ \
    && apk --purge del curl

RUN mkdir -p /var/www/app/public/logo /var/www/app/storage

WORKDIR /var/www/app

# Prepare php image
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS phpbuild

LABEL maintainer="David Bomba <turbo124@gmail.com>"

ARG php_require="bcmath gd pdo_mysql zip mbstring"
ARG php_suggest="exif imagick intl pcntl soap"
ARG php_extra="opcache"

RUN ln -s "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"

# Install chromium
RUN set -eux; \
    apk add --no-cache \
    font-isas-misc \
    supervisor \
    mariadb-client \
    mariadb-connector-c \
    chromium \
    # font-noto-cjk-extra \
    # font-wqy-zenhei \
    ttf-freefont \
    ttf-dejavu

COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    ${php_require} \
    ${php_suggest} \
    ${php_extra}

# Install PHP extensions
# RUN ( curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o - || echo 'return 1' ) | sh -s \
#     ${php_require} \
#     ${php_suggest} \
#     ${php_extra}

# Copy files
COPY rootfs /

## Create user
ARG UID=1500
ENV INVOICENINJA_USER invoiceninja

RUN addgroup --gid=$UID -S "$INVOICENINJA_USER" \
    && adduser --uid=$UID \
    --disabled-password \
    --gecos "" \
    --home "/var/www/app" \
    --ingroup "$INVOICENINJA_USER" \
    "$INVOICENINJA_USER"

WORKDIR /var/www/app

# Set up app
ARG INVOICENINJA_VERSION
ARG BAK_STORAGE_PATH
ARG BAK_PUBLIC_PATH
ENV INVOICENINJA_VERSION $INVOICENINJA_VERSION
ENV BAK_STORAGE_PATH $BAK_STORAGE_PATH
ENV BAK_PUBLIC_PATH $BAK_PUBLIC_PATH
COPY --from=nodebuild --chown=$INVOICENINJA_USER:$INVOICENINJA_USER /var/www/app /var/www/app

USER $UID
WORKDIR /var/www/app

# Do not remove this ENV
ENV IS_DOCKER true
FROM --platform=$BUILDPLATFORM nodebuild AS dependencybuild

WORKDIR /var/www/app
COPY --from=phpbuild /var/www/app /var/www/app

# # Install node packages
ARG BAK_STORAGE_PATH
ARG BAK_PUBLIC_PATH

RUN mv /var/www/app/storage $BAK_STORAGE_PATH \
    && mv /var/www/app/public $BAK_PUBLIC_PATH

FROM phpbuild AS prod

COPY --from=dependencybuild --chown=$INVOICENINJA_USER:$INVOICENINJA_USER /var/www/app /var/www/app

# Override the environment settings from projects .env file
ENV APP_ENV production
ENV LOG errorlog
ENV SNAPPDF_EXECUTABLE_PATH /usr/bin/chromium-browser

ENTRYPOINT ["docker-entrypoint"]
CMD ["supervisord"]
