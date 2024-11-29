FROM php:8.3-fpm AS base

ARG saxon=12.5.0

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    default-mysql-client \
    gnupg2 \
    gosu \
    supervisor \
    # Packages to be checked
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    libonig-dev \
    libpng-dev \
    libxml2-dev \
    xfonts-wqy \
    && if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        mkdir -p /etc/apt/keyrings \
        && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google.gpg \
        && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
        && apt-get update \
        && apt-get install -y --no-install-recommends google-chrome-stable; \
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
            xdg-utils; \
    fi \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set permissions for www-data to execute    
RUN mkdir -p /var/www/.chrome/chrome-profile \
    && chown -R www-data:www-data /var/www/.chrome \
    && chmod -R 755 /var/www/.chrome \
    && if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        chown root:root /usr/bin/google-chrome \
        && chmod 4755 /usr/bin/google-chrome \
        && chown -R root:root /opt/google/chrome \
        && chmod -R 755 /opt/google/chrome; \
    fi \
    && chown -R www-data:www-data /var/www

# Create required directories with proper permissions
RUN mkdir -p /tmp/chrome \
    && if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        chown -R www-data:www-data /tmp/chrome \
        && chmod -R 755 /tmp/chrome; \
    fi

# Copy Install PHP extensions installer
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install Required PHP extensions.
RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    gmp \
    imagick \
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

# Set working directory
WORKDIR /var/www/html

# Download and extract application
RUN set -eux; \ 
    DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/invoiceninja/invoiceninja/releases/latest" | \
    grep -o '"browser_download_url": "[^"]*invoiceninja.tar"' | cut -d '"' -f 4) && \
    curl -L "$DOWNLOAD_URL" | tar -xvz -C /var/www/html && \
    chown -R www-data:www-data /var/www/html

USER www-data

# Install dependencies
RUN composer install --no-dev --no-scripts --no-autoloader

# Generate optimized autoloader and clear cache
RUN composer dump-autoload --optimize \
    && php artisan optimize \
    && php artisan storage:link

USER root

# Setup supervisor
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add initialization script
COPY --chmod=0755 scripts/init.sh /usr/local/bin/init.sh

# Create volume directories
RUN mkdir -p \
    /var/www/html/storage/app/public \
    /var/www/html/storage/framework/cache \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/storage/logs \
    /var/www/html/public/uploads \
    /var/run \
    /var/log/supervisor 

RUN cp /var/www/html/resources/views/react/index.blade.php /var/www/html/public/index.html

# Set permissions
RUN chown -R www-data:www-data \
    /var/www/html/storage \
    /var/www/html/bootstrap/cache \
    /var/www/html/public/uploads \
    /var/run \
    /var/log/supervisor \
    && chmod -R 775 \
        /var/www/html/public/uploads \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        /var/run \
        /var/log/supervisor 

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD php -v || exit 1

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
