FROM dunglas/frankenphp:1-php8.3-bookworm AS prepare-app

RUN curl -s "https://api.github.com/repos/invoiceninja/invoiceninja/releases/latest" | \
    grep -o '"browser_download_url": "[^"]*invoiceninja.tar.gz"' | \
    cut -d '"' -f 4 | \
    xargs curl -sL | \
    tar -xz --strip-components=1 \
    && ln -s ./resources/views/react/index.blade.php ./public/index.html \
    # Symlink
    && php artisan storage:link \
    # Octane
    && php artisan octane:install --server=frankenphp

# ==================
# InvoiceNinja image
# ==================
FROM dunglas/frankenphp:1-php8.3-bookworm

ARG user=ninja

# PHP modules
ARG php_require="bcmath gd pdo_mysql zip"
ARG php_suggest="exif imagick intl pcntl soap saxon-12.5.0"
ARG php_extra="opcache"

# Create a system user UID/GID=999
RUN	useradd -r ${user}

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
    && chown ${user}: /config/google-chrome; \
    elif [ "$(dpkg --print-architecture)" = "arm64" ]; then \
    apt-get install -y --no-install-recommends \
    chromium \
    && mkdir /config/chromium \
    && chown ${user}: /config/chromium; \
    fi \
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
RUN ln -s "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"

COPY php/php.ini /usr/local/etc/php/conf.d/invoiceninja.ini

# Create directory for artisan tinker (init.sh)
RUN mkdir /config/psysh \
    && chown ${user}: /config/psysh

# Change owner for caddy directories
RUN chown -R ${user}: \
    /data/caddy \
    /config/caddy

# InvoiceNinja
COPY --from=prepare-app --chown=${user}:${user} /app /app

# Add initialization script
COPY --chmod=0755 scripts/init.sh /usr/local/bin/init.sh

USER ${user}

ENTRYPOINT ["/usr/local/bin/init.sh"]

CMD ["frankenphp", "php-cli", "artisan", "octane:frankenphp"]
