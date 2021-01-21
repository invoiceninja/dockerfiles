ARG PHP_VERSION=7.2
ARG BAK_STORAGE_PATH=/var/www/app/docker-backup-storage/
ARG BAK_PUBLIC_PATH=/var/www/app/docker-backup-public/

FROM php:${PHP_VERSION}-fpm-alpine

LABEL maintainer="David Bomba <turbo124@gmail.com>"

#####
# SYSTEM REQUIREMENT
#####
ARG INVOICENINJA_VERSION
ARG BAK_STORAGE_PATH
ARG BAK_PUBLIC_PATH
ENV BAK_STORAGE_PATH $BAK_STORAGE_PATH
ENV BAK_PUBLIC_PATH $BAK_PUBLIC_PATH
WORKDIR /var/www/app

COPY entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint \
    && mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Install PHP extensions
# https://hub.docker.com/r/mlocati/php-extension-installer/tags
COPY --from=mlocati/php-extension-installer:1.1.41 /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    gd \
    gmp \
    opcache \
    pdo_mysql \
    zip

COPY ./config/php/php.ini /usr/local/etc/php/conf.d/in-php.ini

# Separate user
ENV INVOICENINJA_USER=invoiceninja

RUN addgroup --gid=1500 -S "$INVOICENINJA_USER" && \
    adduser --uid=1500 \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --ingroup "$INVOICENINJA_USER" \ 
    --no-create-home \
    "$INVOICENINJA_USER"; \
    addgroup "$INVOICENINJA_USER" www-data; \
    chown -R "$INVOICENINJA_USER":"$INVOICENINJA_USER" .

USER 1500

# Download and install IN
ENV INVOICENINJA_VERSION="${INVOICENINJA_VERSION}"

RUN curl -o /tmp/ninja.zip -L https://download.invoiceninja.com/ninja-v${INVOICENINJA_VERSION}.zip \
    && unzip -q /tmp/ninja.zip -d /tmp/ \
    && mv /tmp/ninja/* /var/www/app \
    && rm -rf /tmp/ninja* \
    && mv /var/www/app/storage $BAK_STORAGE_PATH  \
    && mv /var/www/app/public $BAK_PUBLIC_PATH  \
    && mkdir -p /var/www/app/public/logo /var/www/app/storage \
    && chmod -R 755 /var/www/app/storage  \
    && rm -rf /var/www/app/docs /var/www/app/tests

# Override the environment settings from projects .env file
ENV LOG errorlog
ENV SELF_UPDATER_SOURCE ''

# Use to be mounted into nginx
VOLUME /var/www/app/public

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]