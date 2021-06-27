ARG PHP_VERSION=7.4
ARG BAK_STORAGE_PATH=/var/www/app/docker-backup-storage/
ARG BAK_PUBLIC_PATH=/var/www/app/docker-backup-public/

# Get Invoice Ninja and install nodejs packages
FROM --platform=$BUILDPLATFORM node:lts-alpine as build
ARG INVOICENINJA_VERSION
ARG BAK_STORAGE_PATH
ARG BAK_PUBLIC_PATH

# Download Invoice Ninja
ADD https://github.com/invoiceninja/invoiceninja/tarball/v$INVOICENINJA_VERSION /tmp/ninja.tar.gz

# Extract Invoice Ninja
RUN mkdir -p /var/www/app \
    && tar --strip-components=1 -xf /tmp/ninja.tar.gz -C /var/www/app/ \
    && mkdir -p /var/www/app/public/logo /var/www/app/storage \
    && mv /var/www/app/.env.example /var/www/app/.env \
    && rm -rf /var/www/app/docs /var/www/app/tests

WORKDIR /var/www/app/

# Install node packages
RUN npm install --production \
    && npm run production \
    && rm -rf node_modules \
    && mv /var/www/app/storage $BAK_STORAGE_PATH \
    && mv /var/www/app/public $BAK_PUBLIC_PATH  

# Prepare php image
FROM php:${PHP_VERSION}-fpm-alpine3.13 as prod
ARG INVOICENINJA_VERSION
ARG BAK_STORAGE_PATH
ARG BAK_PUBLIC_PATH

LABEL maintainer="David Bomba <turbo124@gmail.com>"

RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Install PHP extensions
# https://hub.docker.com/r/mlocati/php-extension-installer/tags
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    gmp \
    mysqli \
    opcache \
    pdo_mysql \
    zip \
    @composer \
    && rm /usr/local/bin/install-php-extensions

# Install chromium
RUN set -eux; \
    apk add --no-cache \
    supervisor \
    mysql-client \
    git \
    chromium \
    ttf-freefont

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

# Set up app
ENV INVOICENINJA_VERSION $INVOICENINJA_VERSION
ENV BAK_STORAGE_PATH $BAK_STORAGE_PATH
ENV BAK_PUBLIC_PATH $BAK_PUBLIC_PATH
COPY --from=build --chown=$INVOICENINJA_USER:$INVOICENINJA_USER /var/www/app /var/www/app

USER $UID
WORKDIR /var/www/app

# Do not remove this ENV
ENV IS_DOCKER true
RUN /usr/local/bin/composer install --no-dev --quiet

# Override the environment settings from projects .env file
ENV APP_ENV production
ENV LOG errorlog
ENV SNAPPDF_EXECUTABLE_PATH /usr/bin/chromium-browser

ENTRYPOINT ["docker-entrypoint"]
CMD ["supervisord"]
