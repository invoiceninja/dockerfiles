FROM php:fpm


####
# composer
####
# Packages
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libbz2-dev \
    php-pear \
    curl \
    git \
  && rm -r /var/lib/apt/lists/*

# PHP Extensions
RUN docker-php-ext-install mcrypt zip bz2 mbstring \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install gd

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
####
# /composer
####


RUN apt-get update && apt-get install -y \
        libmcrypt-dev\
    && docker-php-ext-install iconv mcrypt \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install pdo pdo_mysql

ENV INVOICENINJA_VERSION 2.4.0
ENV INVOICENINJA_SHA1 3e9b63c1681b6923dc1a24399411c1abde6ef5ea

WORKDIR /var/www/

RUN curl -o invoiceninja.tar.gz -SL https://github.com/hillelcoren/invoice-ninja/archive/v${INVOICENINJA_VERSION}.tar.gz \
	&& echo "$INVOICENINJA_SHA1 *invoiceninja.tar.gz" | sha1sum -c - \
	&& tar -xzf invoiceninja.tar.gz \
    && rm -rf html \
    && ln -s invoice-ninja-${INVOICENINJA_VERSION}/public html \
	&& rm invoiceninja.tar.gz \
	&& chown -R www-data:www-data /var/www/ \
    && composer install --working-dir invoice-ninja-${INVOICENINJA_VERSION} -o

VOLUME /var/www/html


COPY app.php invoice-ninja-${INVOICENINJA_VERSION}/config/app.php

EXPOSE 80

CMD ["php-fpm"]
