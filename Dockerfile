FROM 590183877722.dkr.ecr.ap-northeast-2.amazonaws.com/php:8.2-230308-v1

# set composer related environment variables
ENV PATH="/composer/vendor/bin:$PATH" \
    COMPOSER_ALLOW_SUPERUSER=1 \
#    COMPOSER_VENDOR_DIR=/var/www/vendor \
    COMPOSER_HOME=/composer

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer --ansi --version --no-interaction

# install application dependencies
WORKDIR /var/www/app
COPY ./composer.json ./composer.lock* ./
RUN composer install --no-scripts --no-autoloader --ansi --no-interaction

# add custom php-fpm pool settings, these get written at entrypoint startup
ENV FPM_PM_MAX_CHILDREN=20 \
    FPM_PM_START_SERVERS=2 \
    FPM_PM_MIN_SPARE_SERVERS=1 \
    FPM_PM_MAX_SPARE_SERVERS=3

# set application environment variables
ENV APP_NAME="ELSE" \
    APP_ENV=local \
    APP_DEBUG=true

# copy entrypoint files
COPY ./deploy/docker-php-* /usr/local/bin/
RUN chmod -R +x /usr/local/bin/docker-php-*
RUN dos2unix /usr/local/bin/docker-php-entrypoint
RUN dos2unix /usr/local/bin/docker-php-entrypoint-dev

# copy nginx configuration
COPY ./deploy/nginx.conf /etc/nginx/nginx.conf
COPY ./deploy/default.conf /etc/nginx/conf.d/default.conf

COPY ./deploy/php.ini /usr/local/etc/php/conf.d/php.override.ini

# copy application code
WORKDIR /var/www/app
COPY . .
RUN composer dump-autoload -o \
    && chown -R :www-data /var/www/app \
    && chmod -R 775 /var/www/app/storage /var/www/app/bootstrap/cache

EXPOSE 80

# run supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
