ARG PHP_IMAGE_TAG=7.2-fpm-alpine

FROM php:${PHP_IMAGE_TAG}

LABEL maintainer="Samuel Laulhau <sam@lalop.co>"

#####
# SYSTEM REQUIREMENT
#####
WORKDIR /var/www/app

ENV PHANTOMJS phantomjs-2.1.1-linux-x86_64

RUN apk update \
 && apk add --no-cache \
    coreutils \
    chrpath \
    fontconfig \
    git \
    gmp-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install iconv mbstring pdo pdo_mysql zip gd gmp opcache \
    && echo "php_admin_value[error_reporting] = E_ALL & ~E_NOTICE & ~E_WARNING & ~E_STRICT & ~E_DEPRECATED">>/usr/local/etc/php-fpm.d/www.conf
    
RUN cd /usr/share \
    && curl -L https://github.com/Overbryd/docker-phantomjs-alpine/releases/download/2.11/phantomjs-alpine-x86_64.tar.bz2 | tar xj \
    && ln -s /usr/share/phantomjs/phantomjs /usr/local/bin/phantomjs

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
    "$IN_USER" && \
    chown -R "$IN_USER":"$IN_USER" .

USER $IN_USER

# Download and install IN
ENV INVOICENINJA_VERSION 4.5.18

RUN curl -s -o /tmp/ninja.zip -SL https://download.invoiceninja.com/ninja-v${INVOICENINJA_VERSION}.zip \
    && unzip /tmp/ninja.zip -d /var/www/app -q \
    && rm /tmp/ninja.zip

RUN echo "$(pwd)" && ls -la .



RUN mv /var/www/app/storage /var/www/app/docker-backup-storage  \
    && mv /var/www/app/public /var/www/app/docker-backup-public  \
    && mkdir -p /var/www/app/public/logo /var/www/app/storage \
    && touch /var/www/app/.env \
    && chmod -R 755 /var/www/app/storage  \
    && rm -rf /var/www/app/docs /var/www/app/tests /var/www/ninja

######
# DEFAULT ENV
######
ENV LOG errorlog
ENV SELF_UPDATER_SOURCE ''
ENV PHANTOMJS_BIN_PATH /usr/local/bin/phantomjs


# Use to be mounted into nginx
VOLUME /var/www/app/public

COPY entrypoint.sh /usr/local/bin/invoice-entrypoint
# RUN chmod +x /usr/local/bin/invoice-entrypoint

ENTRYPOINT ["invoice-entrypoint"]
CMD ["php-fpm"]
