ARG PHP_VERSION=8.4
ARG FRANKENPHP_VERSION=1
ARG DEBIAN_VERSION=trixie

FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}-${DEBIAN_VERSION} AS prepare-app

ARG URL=https://github.com/invoiceninja/invoiceninja/releases/latest/download/invoiceninja.tar.gz

ADD ${URL} /tmp/invoiceninja.tar.gz

RUN tar -xf /tmp/invoiceninja.tar.gz \
    && ln -s ./resources/views/react/index.blade.php ./public/index.html \
    # Symlink
    && php artisan storage:link \
    # Octane
    && php artisan octane:install --server=frankenphp

# ==================
# InvoiceNinja image
# ==================
FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}-${DEBIAN_VERSION}

ARG user=ninja

# PHP modules
ARG php_require="bcmath gd mbstring pdo_mysql zip"
ARG php_suggest="exif imagick intl pcntl soap"
ARG php_extra="opcache"
# SaxonC HE is installed on amd64 only: install-php-extensions builds a
# linux-arm64 download URL for the 12.x line, but Saxonica ships those builds
# as linux-aarch64, so there is no working arm64 install path (the arm64 URL 404s).
ARG php_amd64="saxon-12.5.0"

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
# IPE_SAXON_EDITION=HE: install the free Home Edition (XSLT 3.0 is enough for
# e-invoice transforms); the installer otherwise defaults to the commercial EE,
# whose distribution layout breaks the configure step. saxon is amd64-only (see above).
RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    IPE_SAXON_EDITION=HE install-php-extensions ${php_require} ${php_suggest} ${php_amd64} ${php_extra}; \
    else \
    install-php-extensions ${php_require} ${php_suggest} ${php_extra}; \
    fi

# Configure PHP
RUN ln -s "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"

COPY php/php.ini /usr/local/etc/php/conf.d/invoiceninja.ini

# Workaround: Disable SSL for mariadb-client for compatibility with MySQL
RUN echo "skip-ssl = true" >> /etc/mysql/mariadb.conf.d/50-client.cnf

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

HEALTHCHECK --start-period=100s CMD curl -f http://localhost/health

ENTRYPOINT ["/usr/local/bin/init.sh"]

CMD ["frankenphp", "php-cli", "artisan", "octane:frankenphp"]
