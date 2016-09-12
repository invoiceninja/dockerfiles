FROM php:fpm

MAINTAINER Samuel Laulhau <sam@lalop.co>

#####
# SYSTEM REQUIREMENT
#####
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libmcrypt-dev zlib1g-dev git libgmp-dev \
        libfreetype6-dev libjpeg62-turbo-dev libpng12-dev \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install iconv mcrypt mbstring pdo pdo_mysql zip gd gmp \
    && rm -rf /var/lib/apt/lists/*

#####
# INSTALL COMPOSER
#####
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


#####
# DOWNLOAD AND INSTALL INVOICE NINJA
#####

ENV INVOICENINJA_VERSION 2.7

RUN curl -o invoiceninja.tar.gz -SL https://github.com/hillelcoren/invoice-ninja/archive/v${INVOICENINJA_VERSION}.tar.gz \
    && tar -xzf invoiceninja.tar.gz -C /var/www/ \
    && rm invoiceninja.tar.gz \
    && mv /var/www/invoiceninja-${INVOICENINJA_VERSION} /var/www/app \
    && chown -R www-data:www-data /var/www/app \
    && composer install --working-dir /var/www/app -o --no-dev --no-interaction --no-progress \
    && chown -R www-data:www-data /var/www/app/bootstrap/cache \
    && mv /var/www/app/storage /var/www/app/docker-backup-storage \
    && mv /var/www/app/public/logo /var/www/app/docker-backup-public-logo


######
# DEFAULT ENV
######
ENV DB_HOST mysql
ENV DB_DATABASE ninja
ENV APP_KEY SomeRandomString
ENV LOG errorlog
ENV APP_DEBUG 0
ENV APP_CIPHER rijndael-128
ENV SELF_UPDATER_SOURCE ''


#use to be mounted into nginx for exemple
VOLUME /var/www/app/public

WORKDIR /var/www/app

EXPOSE 80

COPY app-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
