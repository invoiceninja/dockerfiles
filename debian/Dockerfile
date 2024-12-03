FROM php:8.3-fpm AS base

ARG saxon=12.5.0

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-mysql-client \
    gpg \
    gosu \
    supervisor \
    # Unicode support for PDF
    fonts-noto-cjk-extra \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    xfonts-wqy \
    && if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        mkdir -p /etc/apt/keyrings \
        && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
            gpg --dearmor -o /etc/apt/keyrings/google.gpg \
        && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
        && apt-get update \
        && apt-get install -y --no-install-recommends google-chrome-stable \
        && mkdir -p /var/www/.config/google-chrome \
        && chown -R www-data:www-data /var/www/.config/google-chrome; \
    elif [ "$(dpkg --print-architecture)" = "arm64" ]; then \
        apt-get install -y --no-install-recommends \
            # Packages for chrome
            fonts-liberation \
            libasound2 \
            libatk-bridge2.0-0 \
            libatk1.0-0 \
            libatspi2.0-0 \
            libcups2 \
            libdbus-1-3 \
            libdrm2 \
            libgbm1 \
            libgtk-3-0 \
            libnspr4 \
            libnss3 \
            libwayland-client0 \
            libxcomposite1 \
            libxdamage1 \
            libxfixes3 \
            libxkbcommon0 \
            libxrandr2 \
            xdg-utils \
            && mkdir -p /var/www/.chrome/chrome-profile \
            && chown -R www-data:www-data /var/www/.chrome/chrome-profile; \
    fi \
    && apt-get purge -y gpg \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Required PHP extensions.
RUN ( curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o - || echo 'return 1' ) | sh -s \
    bcmath \
    exif \
    gd \
    gmp \
    imagick \
    intl \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    redis \
    saxon-${saxon} \
    soap \
    zip \
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
        xargs curl -L | \
        tar -oxvz -C /var/www/html \
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

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
