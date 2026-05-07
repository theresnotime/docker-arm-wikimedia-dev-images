FROM docker-registry.wikimedia.org/dev/bookworm-php83:1.0.0

ENV XDEBUG_MODE=off
ARG INSTALL_WIKIDIFF2=true
ARG WIKIDIFF2_VERSION=1.14.1

# We don't want the default index.html for running PHP applications, and
# xdebug is a major performance drag, so disable it here (it's already
# been disabled for CLI PHP in bullseye-php81).

RUN apt-get update && apt-get install -yq php8.3-fpm php-pear

# Optionally install wikidiff2 (https://w.wiki/MpmQ)
RUN if [ "$INSTALL_WIKIDIFF2" = "true" ]; then \
        # wikidiff2 dependency
        apt-get install -yq libthai-dev; \
        # Get the release from releases.wikimedia.org
        curl -fsSL -A "docker-arm-wikimedia-dev-images" \
        "https://releases.wikimedia.org/wikidiff2/wikidiff2-${WIKIDIFF2_VERSION}.tar.gz" \
        -o /tmp/wikidiff2.tar.gz \
        && mkdir /tmp/wikidiff2 \
        && tar -xzf /tmp/wikidiff2.tar.gz -C /tmp/wikidiff2 --strip-components=1 \
        && cd /tmp/wikidiff2 \
        && phpize8.3 \
        && ./configure --with-php-config=php-config8.3 \
        && make \
        && make install \
        && echo "extension=wikidiff2.so" > /etc/php/8.3/mods-available/wikidiff2.ini \
        && phpenmod -v 8.3 wikidiff2 \
        && rm -rf /tmp/wikidiff2 /tmp/wikidiff2.tar.gz; \
    fi

# Clean up apt cache to reduce image size
RUN rm -rf /var/lib/apt/lists/*

# php-fpm configuration:
COPY ../files/mediawiki-fpm/docker/20-xdebug.ini /docker/20-xdebug.ini
COPY ../files/mediawiki-fpm/php-fpm.conf /etc/php/8.3/fpm/php-fpm.conf
RUN cp /docker/www.conf /etc/php/8.3/fpm/pool.d/www.conf

# MediaWiki-specific php.ini settings
# upload_max_filesize and post_max_size here match production, per T246930
RUN echo 'opcache.file_update_protection=0\n\
opcache.memory_consumption=256\n\
opcache.max_accelerated_files=24000\n\
opcache.max_wasted_percentage=10\n\
opcache.fast_shutdown=1\n\
zlib.output_compression=On\n\
upload_max_filesize=100M\n\
post_max_size=100M\n\
extension=ast.so\n' | tee -a /etc/php/8.3/fpm/php.ini /etc/php/8.3/cli/php.ini

# Install PECL extensions: ast (for phan), xdebug, xhprof
RUN (test -f "/etc/php/8.3/fpm/conf.d/20-xdebug.ini" && rm "/etc/php/8.3/fpm/conf.d/20-xdebug.ini" || true) \
    && pecl install ast \
    && pecl install xdebug-3.4.5 \
    && curl "https://github.com/tideways/php-xhprof-extension/archive/v5.0.4.tar.gz" -fsL -o ./xhprof.tar.gz \
    && tar xf ./xhprof.tar.gz \
    && cd ./php-xhprof-extension-5.0.4 \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && cd .. && rm -rf ./xhprof.tar.gz ./php-xhprof-extension-5.0.4 \
    && ln -s /docker/20-xdebug.ini "/etc/php/$PHP_VERSION/fpm/conf.d/20-xdebug.ini" \
    && ln -s /docker/20-xdebug.ini "/etc/php/$PHP_VERSION/cli/conf.d/20-xdebug.ini"

EXPOSE 9000
EXPOSE 9003

WORKDIR "/var/www/html/w"

ENTRYPOINT ["/bin/bash", "/php_entrypoint.sh"]
