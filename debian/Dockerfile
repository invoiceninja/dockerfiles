ARG PHP=8.4

FROM php:${PHP}-fpm AS prepare-app

ARG URL=https://github.com/invoiceninja/invoiceninja/releases/latest/download/invoiceninja.tar.gz

ADD ${URL} /tmp/invoiceninja.tar.gz

RUN tar -xzf /tmp/invoiceninja.tar.gz -C /var/www/html \
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

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfcgi-bin \
    mariadb-client \
    gpg \
    supervisor \
    # Unicode support for PDF
    fonts-noto-cjk-extra \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    xfonts-wqy \
    # Install google-chrome-stable(amd64)/chromium(arm64)
    && if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
    gpg --dearmor -o /etc/apt/keyrings/google.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable; \
    elif [ "$(dpkg --print-architecture)" = "arm64" ]; then \
    apt-get install -y --no-install-recommends \
    chromium; \
    fi \
    # Create config directory for chromium/google-chrome-stable
    && mkdir /var/www/.config \
    && chown www-data:www-data /var/www/.config \
    # Cleanup
    && apt-get purge -y gpg \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    ${php_require} \
    ${php_suggest} \
    ${php_extra}

# Configure PHP
RUN ln -s "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY php/php.ini /usr/local/etc/php/conf.d/invoiceninja.ini

COPY php/php-fpm.conf /usr/local/etc/php-fpm.d/invoiceninja.conf

# Workaround: Disable SSL for mariadb-client for compatibility with MySQL
RUN echo "skip-ssl = true" >> /etc/mysql/mariadb.conf.d/50-client.cnf

# Setup supervisor
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup InvoiceNinja
COPY --from=prepare-app --chown=www-data:www-data /var/www/html /var/www/html
COPY --from=prepare-app --chown=www-data:www-data /tmp/public /tmp/public

# Add initialization script
COPY --chmod=0755 scripts/init.sh /usr/local/bin/init.sh

# Health check
HEALTHCHECK --start-period=100s \
    CMD REMOTE_ADDR=127.0.0.1 REQUEST_URI=/health REQUEST_METHOD=GET SCRIPT_FILENAME=/var/www/html/public/index.php cgi-fcgi -bind -connect 127.0.0.1:9000 | grep '{"status":"ok","message":"API is healthy"}'

ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
