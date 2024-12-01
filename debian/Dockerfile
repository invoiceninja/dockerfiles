FROM php:8.3-fpm AS base

ARG saxon=12.5.0

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    default-mysql-client \
    gnupg2 \
    gosu \
    supervisor \
    # Unicode support for PDF
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    # Packages to be checked
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

# # Configure chrome
RUN chown www-data:www-data /var/www \
    && if [ "$(dpkg --print-architecture)" = "arm64" ]; then \
        mkdir -p /var/www/.chrome/chrome-profile \
        && chmod -R 755 /var/www/.chrome; \
    fi

# Install PHP extensions installer
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

USER www-data

# Download and extract application
RUN set -eux; \ 
    DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/invoiceninja/invoiceninja/releases/latest" | \
    grep -o '"browser_download_url": "[^"]*invoiceninja.tar"' | cut -d '"' -f 4) && \
    curl -L "$DOWNLOAD_URL" | tar -oxvz -C /var/www/html

RUN cp /var/www/html/resources/views/react/index.blade.php /var/www/html/public/index.html

# Set working directory
WORKDIR /var/www/html

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

# Create upload directories
RUN mkdir -p /var/www/html/public/uploads \
    && chmod -R 775 /var/www/html/public/uploads

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD php -v || exit 1

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
