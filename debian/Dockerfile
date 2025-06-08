ARG PHP=8.3

FROM php:${PHP}-fpm AS prepare-app

USER www-data

RUN curl -sL "https://github.com/invoiceninja/invoiceninja/releases/latest/download/invoiceninja.tar.gz" | \
    tar -xz -C /var/www/html \
    && ln -s /var/www/html/resources/views/react/index.blade.php /var/www/html/public/index.html \
    && php artisan storage:link \
    # Workaround for application updates
    && mv /var/www/html/public /tmp/public

# ==================
# InvoiceNinja image
# ==================
FROM php:${PHP}-fpm

# PHP modules
ARG php_require="bcmath gd mbstring pdo_mysql zip"
ARG php_suggest="exif imagick intl pcntl saxon soap"
ARG php_extra="opcache"

# Install PHP extensions installer
COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Update the packages for security
RUN apt-get update \
    # Install PHP Extensions
    && install-php-extensions \
    ${php_require} \
    ${php_suggest} \
    ${php_extra} \
    # Install system dependencies
    && apt-get install -y --no-install-recommends \
    mariadb-client \
    supervisor \
    # Unicode support for PDF
    fonts-noto-cjk-extra \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    xfonts-wqy \
    # Install chromium
    chromium \
    # Create config directory for chromium
    && mkdir /var/www/.config \
    && chown www-data:www-data /var/www/.config \
    # Cleanup
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP
RUN ln -s "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY php/php.ini /usr/local/etc/php/conf.d/invoiceninja.ini
COPY php/php-fpm.conf /usr/local/etc/php-fpm.d/invoiceninja.conf

# Setup supervisor
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup InvoiceNinja
COPY --from=prepare-app /var/www/html /var/www/html
COPY --from=prepare-app /tmp/public /tmp/public

# Add initialization script
COPY --chmod=0755 scripts/init.sh /usr/local/bin/init.sh

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD pgrep -f "php-fpm: master process"

ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
