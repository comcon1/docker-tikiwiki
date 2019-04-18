FROM montefuscolo/php:7.1-apache
MAINTAINER Fabio Montefuscolo <fabio.montefuscolo@gmail.com>

ARG TIKI_SOURCE="https://gitlab.com/tikiwiki/tiki/-/archive/17.x/tiki-17.x.tar.gz"
WORKDIR "/var/www/html"

# If you have https_proxy with SslBump, place it's cetificate
# in this variable to have curl and composer content cached
ARG HTTPS_PROXY_CERT=""

RUN echo "${HTTPS_PROXY_CERT}" > /usr/local/share/ca-certificates/https_proxy.crt \
    && update-ca-certificates \
    && curl -o tiki.tar.gz -L "${TIKI_SOURCE}" \
    && tar -C /var/www/html -zxf tiki.tar.gz --strip 1 \
    && composer install --working-dir /var/www/html/vendor_bundled --prefer-dist \
    && rm tiki.tar.gz \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

RUN { \
        echo "<?php"; \
        echo "    \$db_tiki        = getenv('TIKI_DB_DRIVER') ?: 'mysqli';"; \
        echo "    \$dbversion_tiki = getenv('TIKI_DB_VERSION') ?: '17';"; \
        echo "    \$host_tiki      = getenv('TIKI_DB_HOST') ?: 'db';"; \
        echo "    \$user_tiki      = getenv('TIKI_DB_USER');"; \
        echo "    \$pass_tiki      = getenv('TIKI_DB_PASS');"; \
        echo "    \$dbs_tiki       = getenv('TIKI_DB_NAME') ?: 'tikiwiki';"; \
        echo "    \$client_charset = 'utf8mb4';"; \
    } > /var/www/html/db/local.php \
    && {\
        echo "session.save_path=/var/www/sessions"; \
    }  > /usr/local/etc/php/conf.d/tiki_session.ini \
    && /bin/bash htaccess.sh \
    && chown -R root:root /var \
    && mkdir -p /var/www/sessions \
    && chown -R www-data /var/www/sessions \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && chown -R www-data /var/www/html/db/ \
    && chown -R www-data /var/www/html/dump/ \
    && chown -R www-data /var/www/html/img/trackers/ \
    && chown -R www-data /var/www/html/img/wiki/ \
    && chown -R www-data /var/www/html/img/wiki_up/ \
    && chown -R www-data /var/www/html/modules/cache/ \
    && chown -R www-data /var/www/html/temp/ \
    && chown -R www-data /var/www/html/templates/

VOLUME ["/var/www/html/files/","/var/www/html/img/trackers/","/var/www/html/img/wiki_up/","/var/www/html/img/wiki/","/var/www/html/modules/cache/","/var/www/html/storage/","/var/www/html/temp/","/var/www/sessions/"]
EXPOSE 80
CMD ["apache2-foreground"]
