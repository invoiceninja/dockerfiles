ARG PHP_VERSION=7.2

FROM php:${PHP_VERSION}-fpm-alpine

LABEL maintainer="Samuel Laulhau <sam@lalop.co>, Holger Lösken <holger.loesken@codedge.de>"

#####
# SYSTEM REQUIREMENT
#####
ARG INVOICENINJA_VERSION
WORKDIR /var/www/app

COPY entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

RUN set -eux; \
    apk add --no-cache \
    gmp-dev \
    freetype-dev \
    libarchive-tools \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev\ 
    libzip-dev

RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include --with-webp-dir=/usr/include --with-freetype-dir=/usr/include/; \
	docker-php-ext-configure zip --with-libzip; \
	docker-php-ext-install -j$(nproc) \
       iconv \
       gd \
       gmp \
       mbstring \
       opcache \
       pdo \
       pdo_mysql \
       zip

COPY ./config/php/php.ini /usr/local/etc/php/php.ini
COPY ./config/php/php-cli.ini /usr/local/etc/php/php-cli.ini

# Separate user
ENV IN_USER=invoiceninja

RUN addgroup -S "$IN_USER" && \
    adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --ingroup "$IN_USER" \ 
    --no-create-home \
    "$IN_USER"; \
    addgroup "$IN_USER" www-data; \
    chown -R "$IN_USER":"$IN_USER" .

USER $IN_USER

# Download and install IN
ENV INVOICENINJA_VERSION="${INVOICENINJA_VERSION}"

RUN curl -s -o /tmp/ninja.zip -SL https://download.invoiceninja.com/ninja-v${INVOICENINJA_VERSION}.zip \
    && bsdtar --strip-components=1 -C /var/www/app -xf /tmp/ninja.zip \
    && rm /tmp/ninja.zip \
    && mv /var/www/app/storage /var/www/app/docker-backup-storage  \
    && mv /var/www/app/public /var/www/app/docker-backup-public  \
    && mkdir -p /var/www/app/public/logo /var/www/app/storage \
    && cp /var/www/app/.env.example /var/www/app/.env \
    && chmod -R 755 /var/www/app/storage  \
    && rm -rf /var/www/app/docs /var/www/app/tests

# Override the environment settings from projects .env file
ENV LOG errorlog
ENV SELF_UPDATER_SOURCE ''

# Use to be mounted into nginx
VOLUME /var/www/app/public

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]