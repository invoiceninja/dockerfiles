ARG PHP_VERSION=7.2
ARG INVOICENINJA_VERSION

FROM php:${PHP_VERSION}-fpm-stretch

LABEL maintainer="Samuel Laulhau <sam@lalop.co>, Holger Lösken <holger.loesken@codedge.de>"

#####
# SYSTEM REQUIREMENT
#####
COPY ./debian/entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENV BUILD_DEPS \
        zlib1g-dev \
        git \
        libgmp-dev \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        build-essential \
        chrpath \
        libssl-dev \
        libxft-dev \
        libfreetype6 \
        libfontconfig1 \
        libfontconfig1-dev

RUN apt-get update \
    && apt-get install -y --no-install-recommends $BUILD_DEPS \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install iconv mbstring pdo pdo_mysql zip gd gmp opcache

ENV PHANTOMJS phantomjs-2.1.1-linux-x86_64
# Install PHANTOMJS
RUN curl -o ${PHANTOMJS}.tar.bz2 -SL https://bitbucket.org/ariya/phantomjs/downloads/${PHANTOMJS}.tar.bz2 \
    && tar xvjf ${PHANTOMJS}.tar.bz2 \
    && rm ${PHANTOMJS}.tar.bz2 \
    && mv ${PHANTOMJS} /usr/local/share \
    && ln -sf /usr/local/share/${PHANTOMJS}/bin/phantomjs /usr/local/bin \
    && rm -rf /var/lib/apt/lists/*

COPY ./config/php/php.ini /usr/local/etc/php/php.ini
COPY ./config/php/php-cli.ini /usr/local/etc/php/php-cli.ini

# Download and install IN
ENV INVOICENINJA_VERSION="${INVOICENINJA_VERSION}"

RUN curl -o ninja.zip -SL https://download.invoiceninja.com/ninja-v${INVOICENINJA_VERSION}.zip \
    && unzip -q ninja.zip -d /var/www/ \
    && rm ninja.zip \
    && mv /var/www/ninja /var/www/app  \
    && mv /var/www/app/storage /var/www/app/docker-backup-storage  \
    && mv /var/www/app/public /var/www/app/docker-backup-public  \
    && mkdir -p /var/www/app/public/logo /var/www/app/storage \
    && cp /var/www/app/.env.example /var/www/app/.env \
    && chmod -R 755 /var/www/app/storage  \
    && chown -R www-data:www-data /var/www/app/storage /var/www/app/bootstrap /var/www/app/public/logo /var/www/app/.env /var/www/app/docker-backup-storage /var/www/app/docker-backup-public\
    && rm -rf /var/www/app/docs /var/www/app/tests /var/www/ninja

# Override the environment settings from projects .env file
ENV LOG errorlog
ENV SELF_UPDATER_SOURCE ''
ENV PHANTOMJS_BIN_PATH /usr/local/bin/phantomjs


# use to be mounted into nginx for example
VOLUME /var/www/app/public

WORKDIR /var/www/app

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]
