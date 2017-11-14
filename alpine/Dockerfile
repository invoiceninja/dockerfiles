FROM php:7.0-fpm-alpine

MAINTAINER Samuel Laulhau <sam@lalop.co>

#####
# SYSTEM REQUIREMENT
#####
ENV PHANTOMJS phantomjs-2.1.1-linux-x86_64
RUN apk update \
 && apk add --no-cache libmcrypt-dev git gmp-dev freetype-dev libjpeg-turbo-dev \
            coreutils chrpath fontconfig libpng-dev

RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install iconv mcrypt mbstring pdo pdo_mysql zip gd gmp opcache \
    && echo "php_admin_value[error_reporting] = E_ALL & ~E_NOTICE & ~E_WARNING & ~E_STRICT & ~E_DEPRECATED">>/usr/local/etc/php-fpm.d/www.conf
    
RUN cd /usr/share \
    && curl  -L https://github.com/Overbryd/docker-phantomjs-alpine/releases/download/2.11/phantomjs-alpine-x86_64.tar.bz2 | tar xj \
    && ln -s /usr/share/phantomjs/phantomjs /usr/local/bin/phantomjs
    

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

#####
# INSTALL COMPOSER
#####
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


#####
# DOWNLOAD AND INSTALL INVOICE NINJA
#####

ENV INVOICENINJA_VERSION 3.9.1

RUN curl -o invoiceninja.tar.gz -SL https://github.com/hillelcoren/invoice-ninja/archive/v${INVOICENINJA_VERSION}.tar.gz \
    && tar -xzf invoiceninja.tar.gz -C /var/www/ \
    && rm invoiceninja.tar.gz \
    && mv /var/www/invoiceninja-${INVOICENINJA_VERSION} /var/www/app \
    && chown -R www-data:www-data /var/www/app \
    && composer install --working-dir /var/www/app -o --no-dev --no-interaction --no-progress \
    && chown -R www-data:www-data /var/www/app/bootstrap/cache \
    && mv /var/www/app/storage /var/www/app/docker-backup-storage \
    && mv /var/www/app/public /var/www/app/docker-backup-public \
    && rm -rf /var/www/app/docs /var/www/app/tests


######
# DEFAULT ENV
######
ENV DB_HOST mysql
ENV DB_DATABASE ninja
ENV DB_USERNAME ninja
ENV DB_PASSWORD ninja
ENV APP_KEY SomeRandomString
ENV LOG errorlog
ENV APP_DEBUG 0
ENV APP_CIPHER rijndael-128
ENV SELF_UPDATER_SOURCE ''
ENV PHANTOMJS_BIN_PATH /usr/local/bin/phantomjs


#use to be mounted into nginx for exemple
VOLUME /var/www/app/public

WORKDIR /var/www/app

COPY entrypoint.sh /usr/local/bin/invoice-entrypoint
# RUN chmod +x /usr/local/bin/invoice-entrypoint

ENTRYPOINT ["invoice-entrypoint"]
CMD ["php-fpm"]
