FROM php:fpm

#####
# SYSTEM REQUIREMENT
#####
RUN apt-get update \
    && apt-get install -y libmcrypt-dev zlib1g-dev git\
    && docker-php-ext-install iconv mcrypt mbstring pdo pdo_mysql zip \
    && rm -rf /var/lib/apt/lists/*

#####
# INSTALL COMPOSER
#####
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


#####
# DOWNLOAD AND INSTALL INVOICE NONJA
#####

ENV INVOICENINJA_VERSION 2.4.2
#ENV INVOICENINJA_SHA1 3e9b63c1681b6923dc1a24399411c1abde6ef5ea

RUN curl -o invoiceninja.tar.gz -SL https://github.com/hillelcoren/invoice-ninja/archive/v${INVOICENINJA_VERSION}.tar.gz
# RUN echo "$INVOICENINJA_SHA1 *invoiceninja.tar.gz" | sha1sum -c -
RUN tar -xzf invoiceninja.tar.gz -C /var/www/
RUN rm invoiceninja.tar.gz
RUN mv /var/www/invoiceninja-${INVOICENINJA_VERSION} /var/www/app
RUN chown -R www-data:www-data /var/www/app
RUN composer install --working-dir /var/www/app -o --no-dev --no-interaction


######
# DEFAULT ENV
######
ENV DB_HOST mysql
ENV DB_DATABASE ninja
ENV APP_KEY SomeRandomString
ENV LOG errorlog
ENV APP_DEBUG 0


#use to be mounted into nginx for exemple
VOLUME /var/www/app/public

WORKDIR /var/www/app

EXPOSE 80

COPY app-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
