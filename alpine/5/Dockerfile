ARG PHP_VERSION=8.2
ARG BAK_STORAGE_PATH=/var/www/app/docker-backup-storage/
ARG BAK_PUBLIC_PATH=/var/www/app/docker-backup-public/

# Get Invoice Ninja and install nodejs packages
FROM --platform=$BUILDPLATFORM node:lts-alpine as build

# Download Invoice Ninja
ARG INVOICENINJA_VERSION
ADD https://github.com/invoiceninja/invoiceninja/tarball/v$INVOICENINJA_VERSION /tmp/ninja.tar.gz

RUN set -eux; apk add curl unzip

# Extract Invoice Ninja
RUN mkdir -p /var/www/app \
    && tar --strip-components=1 -xf /tmp/ninja.tar.gz -C /var/www/app/ \
    && mkdir -p /var/www/app/public/logo /var/www/app/storage
    
# Download and extract the latest react application
RUN curl -LGO $(curl https://api.github.com/repos/invoiceninja/ui/releases/latest | grep "browser_download_url" | awk '{ print $2 }' | sed 's/,$//' | sed 's/"//g');
RUN cp invoiceninja-react.zip /tmp/invoiceninja-react.zip
RUN unzip /tmp/invoiceninja-react.zip 
RUN mkdir  /var/www/app/public/react/v$INVOICENINJA_VERSION/
RUN cp -r dist/react/* /var/www/app/public/react/v$INVOICENINJA_VERSION/
RUN cp -r dist/react/* /var/www/app/public/react/
          
RUN mkdir -p /var/www/app/public/tinymce_6.4.2/tinymce/js/
RUN cp -r dist/tinymce_6.4.2/* /var/www/app/public/tinymce_6.4.2/

# Download and extract the latest react application
# 
WORKDIR /var/www/app/

# Install node packages
ARG BAK_STORAGE_PATH
ARG BAK_PUBLIC_PATH
RUN --mount=target=/var/www/app/node_modules,type=cache \
    npm install \
    && npm run production \
    && mv /var/www/app/storage $BAK_STORAGE_PATH \
    && mv /var/www/app/public $BAK_PUBLIC_PATH  

# Prepare php image
FROM php:${PHP_VERSION}-fpm-alpine as prod

LABEL maintainer="David Bomba <turbo124@gmail.com>"

# Adding caching_sha2_password.so
# With this we get native support for caching_sha2_password
RUN apk add --no-cache mariadb-connector-c

RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Install PHP extensions
# https://hub.docker.com/r/mlocati/php-extension-installer/tags
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install chromium
RUN set -eux; \
    apk add --no-cache \
    font-isas-misc \
    supervisor \
    mysql-client \
    git \
    chromium \
    ttf-freefont

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
ARG INVOICENINJA_VERSION
ARG BAK_STORAGE_PATH
ARG BAK_PUBLIC_PATH
ENV INVOICENINJA_VERSION $INVOICENINJA_VERSION
ENV BAK_STORAGE_PATH $BAK_STORAGE_PATH
ENV BAK_PUBLIC_PATH $BAK_PUBLIC_PATH
COPY --from=build --chown=$INVOICENINJA_USER:$INVOICENINJA_USER /var/www/app /var/www/app

USER $UID
WORKDIR /var/www/app

# Do not remove this ENV
ENV IS_DOCKER true
RUN /usr/local/bin/composer install --no-dev --no-scripts --no-interaction 
RUN /usr/local/bin/composer dump-autoload --optimize --no-dev --classmap-authoritative --no-scripts --no-interaction 

# Override the environment settings from projects .env file
ENV APP_ENV production
ENV LOG errorlog
ENV SNAPPDF_EXECUTABLE_PATH /usr/bin/chromium-browser

ENTRYPOINT ["docker-entrypoint"]
CMD ["supervisord"]
