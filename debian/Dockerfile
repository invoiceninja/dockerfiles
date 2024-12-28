FROM dunglas/frankenphp:1-php8.3-bookworm

ARG USER=ninja

# PHP modules
ARG php_require="bcmath gd pdo_mysql zip"
ARG php_suggest="exif imagick intl pcntl soap saxon-12.5.0"
ARG php_extra="opcache"

ENV APP_DIR=/app

# Create a system user
RUN	useradd -r ${USER}

# Allow to bind to privileged ports
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-client \
    gpg \
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
        && apt-get install -y --no-install-recommends google-chrome-stable \
        && mkdir /config/google-chrome \
        && chown ${USER}: /config/google-chrome; \
    elif [ "$(dpkg --print-architecture)" = "arm64" ]; then \
        apt-get install -y --no-install-recommends \
        chromium \
        && mkdir /config/chromium \
        && chown ${USER}: /config/chromium; \
    fi \
    # Cleanup
    && apt-get purge -y gpg \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN install-php-extensions \
        ${php_require} \
        ${php_suggest} \
        ${php_extra} \
        @composer

# Configure PHP
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Add initialization script
COPY --chmod=0755 scripts/init.sh /usr/local/bin/init.sh

# Prepare app directory
RUN rm -rf ${APP_DIR}/* \
    && chown ${USER}: ${APP_DIR}

# Create directory for artisan tinker (init.sh)
RUN mkdir /config/psysh \
    && chown ${USER}: /config/psysh

# Change owner for caddy directories
RUN chown -R ${USER}: \
    /data/caddy \
    /config/caddy

USER ${USER}

# Setup InvoiceNinja
RUN curl -s "https://api.github.com/repos/invoiceninja/invoiceninja/releases/latest" | \
        grep -o '"browser_download_url": "[^"]*invoiceninja.tar"' | \
        cut -d '"' -f 4 | \
        xargs curl -sL | \
        tar -oxz -C ${APP_DIR} \
    && ln -s ${APP_DIR}/resources/views/react/index.blade.php ${APP_DIR}/public/index.html \
    # Set permissions: directories 755, files 644
    && chmod -R a=r,u+w,a+X ${APP_DIR} \
    # Install dependencies
    && composer install --working-dir=${APP_DIR} --no-dev --no-scripts --no-autoloader \
    && composer dump-autoload --working-dir=${APP_DIR} --optimize \
    && frankenphp php-cli ${APP_DIR}/artisan storage:link

ENTRYPOINT ["/usr/local/bin/init.sh"]

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
