FROM php:8.3-fpm AS base

ARG php_require="bcmath gd pdo_mysql zip"
ARG php_suggest="exif imagick intl pcntl soap saxon-12.5.0"
ARG php_extra="opcache"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
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
RUN ( curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o - || echo 'return 1' ) | sh -s \
        ${php_require} \
        ${php_suggest} \
        ${php_extra} \
        @composer

# Configure PHP
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Copy scripts
COPY rootfs /

USER www-data

WORKDIR /var/www/html

# Setup InvoiceNinja
RUN curl -s "https://api.github.com/repos/invoiceninja/invoiceninja/releases/latest" | \
        grep -o '"browser_download_url": "[^"]*invoiceninja.tar"' | \
        cut -d '"' -f 4 | \
        xargs curl -sL | \
        tar -oxz -C /var/www/html \
    && cp /var/www/html/resources/views/react/index.blade.php /var/www/html/public/index.html \
    # File permissions
    && find /var/www/html/ -type f -exec chmod 644 {} \; \
    # Directory permissions
    && find /var/www/html/ -type d -exec chmod 755 {} \; \
    # Install dependencies
    && composer install --no-dev --no-scripts --no-autoloader \
    && composer dump-autoload --optimize \
    && php artisan optimize \
    && php artisan storage:link \
    # Workaround for application updates
    && mv /var/www/html/public /tmp/public

USER root

# Setup supervisor
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add initialization script
COPY --chmod=0755 scripts/init.sh /usr/local/bin/init.sh

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD php -v || exit 1

ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
