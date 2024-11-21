FROM php:8.2-fpm as base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    opcache \
    redis \
    zip \
    @composer

# Configure PHP
COPY php/php.ini /usr/local/etc/php/conf.d/app.ini
COPY php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Set working directory
WORKDIR /var/www/html

# Download and extract application in a single layer
RUN set -eux; \
    DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/invoiceninja/invoiceninja/releases/latest" | \
    grep -o '"browser_download_url": "[^"]*invoiceninja.tar"' | cut -d '"' -f 4) && \
    curl -L "$DOWNLOAD_URL" | tar -xvz -C /var/www/html && \
    rm -rf /var/www/html/ui && \
    chown -R www-data:www-data /var/www/html

# Install dependencies
RUN composer install --no-dev --no-scripts --no-autoloader

# Generate optimized autoloader and clear cache
RUN composer dump-autoload --optimize \
    && php artisan optimize \
    && php artisan view:cache \
    && php artisan config:cache \
    && php artisan route:cache

# Setup supervisor
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add initialization script
COPY scripts/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# Create volume directories
RUN mkdir -p \
    /var/www/html/storage/app/public \
    /var/www/html/storage/framework/cache \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/storage/logs \
    /var/www/html/public/uploads \
    /var/log/supervisor 

# Set permissions
RUN chown -R www-data:www-data \
    /var/www/html/storage \
    /var/www/html/bootstrap/cache \
    /var/www/html/public/uploads \
    /var/log/supervisor \
    && chmod -R 775 \
        /var/www/html/public/uploads \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        /var/log/supervisor 

USER www-data

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD php -v || exit 1

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]