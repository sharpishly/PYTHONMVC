FROM php:8.1-fpm
# Installing dependencies
RUN apt-get update && apt-get install -y \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    default-mysql-client \  # Added MySQL client for testing
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd
# Installing Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
# Setting working directory
WORKDIR /var/www/html
# Copying application code
COPY ./sharpishly.com/website/public /var/www/html/sharpishly
COPY ./dev.sharpishly.com /var/www/html/dev_sharpishly
# Setting permissions
RUN chown -R www-data:www-data /var/www/html/sharpishly \
    && chown -R www-data:www-data /var/www/html/dev_sharpishly \
    && chmod -R 755 /var/www/html/sharpishly \
    && chmod -R 755 /var/www/html/dev_sharpishly
# Exposing port for PHP-FPM
EXPOSE 9000
# Starting PHP-FPM
CMD ["php-fpm"]