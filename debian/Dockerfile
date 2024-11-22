FROM php:8.2-fpm AS base
ARG saxon=12.5.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    gosu \
    default-mysql-client \
    supervisor \
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
    fonts-liberation \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \ 
    fonts-wqy-microhei \  
    fonts-wqy-zenhei \ 
    xfonts-wqy \      
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set permissions for www-data to execute    
RUN mkdir -p /var/www/.chrome/chrome-profile \
    && chown -R www-data:www-data /var/www/.chrome \
    && chmod -R 755 /var/www/.chrome \
    && chown root:root /usr/bin/google-chrome \
    && chmod 4755 /usr/bin/google-chrome \
    && chown -R root:root /opt/google/chrome \
    && chmod -R 755 /opt/google/chrome \
    && chown -R www-data:www-data /var/www

# Create required directories with proper permissions
RUN mkdir -p /tmp/chrome \
    && chown -R www-data:www-data /tmp/chrome \
    && chmod -R 755 /tmp/chrome
    
# Copy Install PHP extensions installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install Required PHP extensions.
RUN install-php-extensions \
    pdo_mysql \
    mysqli \     
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    opcache \
    redis \
    soap \
    imagick \
    curl \
    gmp \
    zip \
    @composer

# Configure PHP
COPY php/php.ini /usr/local/etc/php/conf.d/app.ini
COPY php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Configure Saxon
WORKDIR /opt

## fetch
RUN curl https://downloads.saxonica.com/SaxonC/HE/12/libsaxon-HEC-linux-x86_64-v${saxon}.zip --output saxon.zip
RUN unzip saxon.zip -d saxon
RUN cp saxon/libsaxon-HEC-linux-amd64-v${saxon}/libs/nix/libsaxon-hec-${saxon}.so /usr/lib/
WORKDIR /opt/saxon/libsaxon-HEC-linux-amd64-v${saxon}/Saxon.C.API
RUN phpize
RUN ./configure --enable-saxon
RUN make
RUN ls -al
RUN make install
RUN echo 'extension=saxon.so' > "/usr/local/etc/php/conf.d/app.ini"

# Copy scripts
COPY rootfs /

# Set working directory
WORKDIR /var/www/html

# Download and extract application
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

# Make executable
RUN chmod +x /usr/local/bin/init.sh

# Configure PHP-FPM
RUN sed -i "s/user = www-data/user = www-data/g" /usr/local/etc/php-fpm.d/www.conf \
    && sed -i "s/group = www-data/group = www-data/g" /usr/local/etc/php-fpm.d/www.conf

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