# Multi-stage build for the Laravel/PHP 8.4 API (AD-004).
# Stage 1: install Composer dependencies in isolation from the runtime image.
FROM composer:2 AS vendor

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY . .
RUN composer dump-autoload --optimize

# Stage 2: runtime image. Serves the app via php-fpm by default; the same
# image also runs the Reverb websocket process (`php artisan reverb:start`)
# by overriding the container command in docker-compose.yml.
FROM php:8.4-fpm AS runtime

WORKDIR /var/www/html

COPY --from=vendor /app /var/www/html

EXPOSE 9000

CMD ["php-fpm"]
