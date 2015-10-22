FROM php:fpm

RUN apt-get update \
    && apt-get install -y libmcrypt-dev zlib1g-dev git\
    && docker-php-ext-install iconv mcrypt mbstring pdo pdo_mysql zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV INVOICENINJA_VERSION 2.4.3
#ENV INVOICENINJA_SHA1 3e9b63c1681b6923dc1a24399411c1abde6ef5ea

ENV DB_HOST mysql
ENV LOG errorlog
ENV APP_DEBUG 0

WORKDIR /var/www/

RUN curl -o invoiceninja.tar.gz -SL https://github.com/hillelcoren/invoice-ninja/archive/v${INVOICENINJA_VERSION}.tar.gz \
#	&& echo "$INVOICENINJA_SHA1 *invoiceninja.tar.gz" | sha1sum -c - \
	&& tar -xzf invoiceninja.tar.gz \
    && mv invoice-ninja-${INVOICENINJA_VERSION} app \
    && rm -rf html \
    && ln -s app/public html \
	&& rm invoiceninja.tar.gz \
#	&& chown -R www-data:www-data /var/www/ \
    && composer install --working-dir app -o

VOLUME /var/www/html

VOLUME /var/www/app/storage

EXPOSE 80

CMD ["php-fpm"]
