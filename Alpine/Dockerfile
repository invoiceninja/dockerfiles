ARG PHP=8.3

FROM php:${PHP}-fpm-alpine AS prepare-app

USER www-data

RUN curl -sL "https://github.com/invoiceninja/invoiceninja/releases/latest/download/invoiceninja.tar.gz" | \
    tar -xz -C /var/www/html \
    && ln -s /var/www/html/resources/views/react/index.blade.php /var/www/html/public/index.html \
    && php artisan storage:link \
    # Workaround for application updates
    && mv /var/www/html/public /tmp/public

# ==================
# InvoiceNinja image
# ==================
FROM php:${PHP}-fpm-alpine

# PHP modules
ARG php_require="bcmath gd mbstring pdo_mysql zip"
ARG php_suggest="exif imagick intl pcntl soap"
ARG php_extra="opcache"
# Set up repositories and update/upgradeapk packages in one go
ARG REPO_LIST="main community"

# Install PHP extensions installer
COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

# Change the repositories to latest-stable for latest updates
RUN rm -f /etc/apk/repositories && \
    for repo in $REPO_LIST; do \
        echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/$repo" >> /etc/apk/repositories; \
    done && \
    # Update the packages for security
    apk upgrade --no-cache --available \
    # Install PHP Extensions
    # (Saxon has a compilation error with this script and need to be installed after with a patch)
    && install-php-extensions \
    ${php_require} \
    ${php_suggest} \
    ${php_extra} \
    # Install system dependencies, including fonts and Chromium dependencies
    && apk add --no-cache \
    # MariaDB-client replace mysql-client and execute the same functions 
    mariadb-client \
    # Install chromium 
    chromium \
    # Unicode support for PDF
    ttf-freefont \
    font-noto \
    font-noto-cjk \
    font-wqy-zenhei \
    fontconfig \
    mkfontscale \
    mkfontdir \
    # Required for script
    util-linux \
    linux-pam \
    shadow \
    supervisor \
    # Build dependencies for Saxon PHP Extension - add virtual package for easy removal
    make \
    g++ \
    autoconf \
    php83-dev \
    libxml2-dev \
    && rm -rf /var/cache/apk/* \
    # Prepare font directories
    && mkdir -p /usr/share/fonts/custom /usr/share/fonts/truetype /usr/share/fonts/misc \
    # Create config directory for chromium
    && mkdir -p /var/www/.config \
    && chown www-data:www-data /var/www/.config

# --- SaxonC Installation ---
WORKDIR /tmp/saxon
# Combined RUN instruction for downloading, patching, compiling, and installing SaxonC
# Detect and download the latest version of SaxonCHE (Open Source) according to the system architecture
# x86_64 (amd64) && aarm64 only as they are the only provided architectures from Saxonica
RUN UNAME_ARCH=$(uname -m); DOWNLOAD_ARCH_COMPONENT=""; \
    case "$UNAME_ARCH" in \
        x86_64) DOWNLOAD_ARCH_COMPONENT="linux-x86_64";; \
        aarch64|arm64) DOWNLOAD_ARCH_COMPONENT="linux-aarch64";; \
        *) echo "Error: Unsupported architecture: '$UNAME_ARCH'. Script needs Linux x86_64 or aarch64/arm64. Exiting." >&2; exit 1;; \
    esac; \
    echo "Detected architecture: ${UNAME_ARCH}"; \
    ALL_OUTPUT=$(curl -s https://www.saxonica.com/products/latest.xml | \
    grep -A 1 -E '<h2>SaxonC 13</h2>|<h2>SaxonC 12</h2>' | \
    awk '/<h2>SaxonC 13<\/h2>/ {f13=1;next} /<h2>SaxonC 12<\/h2>/ {if(!f13){f12=1;next}} {if(f13||f12){match($0, /[0-9]+(\.[0-9]+)*/);if(RSTART>0){v=substr($0, RSTART, RLENGTH); \
    if(f13){print "SaxonC 13: " v}else{print "SaxonC 12: " v}; \
    split(v,p,"."); \
    mv=p[1];dv=p[1]; \
    for(i=2;i<=length(p);i++){dv=dv"-"p[i]}; \
    if(length(p)==2){dv=dv"-0"}else if(length(p)==1){dv=dv"-0-0"}; \
    print mv,dv; exit}}}'); \
    if [ -z "$ALL_OUTPUT" ]; then \
        echo "Error: Could not determine latest SaxonC version." >&2; exit 1; \
    fi; \
    DETECTED_VERSION_DISPLAY_LINE=$(echo "$ALL_OUTPUT" | head -n 1); \
    MACHINE_READABLE_INFO=$(echo "$ALL_OUTPUT" | tail -n 1); \
    MAJOR_VER=$(echo "$MACHINE_READABLE_INFO" | awk '{print $1}'); \
    FORMATTED_VER=$(echo "$MACHINE_READABLE_INFO" | awk '{print $2}'); \
    echo "$DETECTED_VERSION_DISPLAY_LINE"; \
    CONSTRUCTED_URL="https://downloads.saxonica.com/SaxonC/HE/${MAJOR_VER}/SaxonCHE-${DOWNLOAD_ARCH_COMPONENT}-${FORMATTED_VER}.zip"; \
    echo "Downloading from: $CONSTRUCTED_URL"; \
    curl -L -o saxon.zip "$CONSTRUCTED_URL"; \
    unzip saxon.zip; \
    rm saxon.zip; \
    \
    # 1. Move the entire SaxonCHE distribution to /usr/local/SaxonCHE
    #    This ensures its structure is intact for the PHP extension's configure script.
    mv "SaxonCHE-${DOWNLOAD_ARCH_COMPONENT}-${FORMATTED_VER}/SaxonCHE" /usr/local/SaxonCHE; \
    \
    # 2. Move the PHP source to a temporary location for compilation
    mv "SaxonCHE-${DOWNLOAD_ARCH_COMPONENT}-${FORMATTED_VER}/php/src" /tmp/saxon; \
    \
    # 3. Clean up the original extracted directory from the zip (optional, but good for image size)
    rm -rf "SaxonCHE-${DOWNLOAD_ARCH_COMPONENT}-${FORMATTED_VER}"; \
    \
    # 4. Apply patch and compile Saxon PHP extension
    #    The configure script will now find libsaxonc-core-he.so at /usr/local/SaxonCHE/lib/
    cd /tmp/saxon/src && \
    # Patch to compile SaxonC correctly on Alpine
    sed -i 's/Z_TYPE_P(val) != NULL/Z_TYPE_P(val) != IS_NULL/g' php8_XsltExecutable.cpp && \
    phpize && \
    ./configure --with-saxon=/usr/local/SaxonCHE LDFLAGS="-L/usr/local/SaxonCHE/lib" && \
    make && \
    make install && \
    # Move the modules to the specific modules folder of PHP
    mv /tmp/saxon/src/modules/* $(php-config --extension-dir)/; \
    \
    # 5. NOW, after the PHP extension is compiled, move the core SaxonC shared libraries
    #    to a default linker path for runtime discovery.
    mv /usr/local/SaxonCHE/lib/*.so* /usr/local/lib/ && \
    \
    # 6. Enable the PHP extension
    echo "extension=saxon.so" > /usr/local/etc/php/conf.d/saxon.ini && \
    \
    # 7. Clean up build dependencies and temporary files
    apk del --no-cache make g++ autoconf php83-dev libxml2-dev && \
    rm -rf /tmp/*

WORKDIR /var/www/html

# Copy custom fonts (fonts-wqy-microhei & xfonts-wqy)
COPY fonts/*.ttf /usr/share/fonts/truetype/
COPY fonts/*.pcf /usr/share/fonts/misc/

# Configure PHP (Part 1)
RUN ln -s "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    # Generate font indexes and update cache
    && cd /usr/share/fonts/truetype && mkfontscale && mkfontdir \
    && cd /usr/share/fonts/misc && mkfontscale && mkfontdir \
    && fc-cache -fv

# Configure PHP (Part 2)   
COPY php/php.ini /usr/local/etc/php/conf.d/invoiceninja.ini
COPY php/php-fpm.conf /usr/local/etc/php-fpm.d/invoiceninja.conf
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup InvoiceNinja
COPY --from=prepare-app /var/www/html /var/www/html
COPY --from=prepare-app /tmp/public /tmp/public

# Add initialization script
COPY --chmod=0755 scripts/init.sh /usr/local/bin/init.sh

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD pgrep -f "php-fpm: master process"

ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]