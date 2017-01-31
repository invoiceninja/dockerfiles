FROM php:7.0-fpm

MAINTAINER Samuel Laulhau <sam@lalop.co>

#####
# SYSTEM REQUIREMENT
#####
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libmcrypt-dev zlib1g-dev git libgmp-dev \
        libfreetype6-dev libjpeg62-turbo-dev libpng12-dev rsync \
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

ENV INVOICENINJA_VERSION 3.0.3

RUN curl -o invoiceninja.tar.gz -SL https://github.com/hillelcoren/invoice-ninja/archive/v${INVOICENINJA_VERSION}.tar.gz \
    && tar -xzf invoiceninja.tar.gz -C /var/www/ \
    && rm invoiceninja.tar.gz 

RUN cp -r /var/www/invoiceninja-${INVOICENINJA_VERSION} /var/www/app \
    && cp -r /var/www/invoiceninja-${INVOICENINJA_VERSION}/storage /var/www/app/docker-new-storage \
    && cp -r /var/www/invoiceninja-${INVOICENINJA_VERSION}/public /var/www/app/docker-new-public \
    && rm -rf /var/www/invoiceninja-${INVOICENINJA_VERSION} \
    && chown -R www-data:www-data /var/www/app \
    && composer install --working-dir /var/www/app -o --no-dev --no-interaction --no-progress \
    && chown -R www-data:www-data /var/www/app/bootstrap/cache #\
    # && echo ${INVOICENINJA_VERSION} > /var/www/app/storage/version.txt


######
# DEFAULT ENV
######
ENV DB_HOST db
ENV DB_DATABASE ninja
ENV APP_KEY SomeRandomString
ENV LOG errorlog
ENV APP_DEBUG 0
ENV APP_CIPHER rijndael-128
ENV SELF_UPDATER_SOURCE ''


#use to be mounted into nginx for exemple
VOLUME ["/var/www/app/public","/var/www/app/storage"]

WORKDIR /var/www/app

EXPOSE 80

COPY app-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
