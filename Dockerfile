FROM php:7.3-apache

MAINTAINER Antonio Saiful Islam (finallyantonio@gmail.com)

ADD vhost.conf /etc/nginx/conf.d/default.conf

# Get repository and install wget and vim
RUN apt-get update && apt-get install --no-install-recommends -y \
		apt-utils \
        wget \
        gnupg \
        git \
        unzip \
        curl \
        apt-transport-https

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=. --filename=composer
RUN mv composer /usr/local/bin/

# Install PHP extensions deps
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libmagickwand-dev \
        imagemagick \
        libmcrypt-dev \
        zlib1g-dev \
        libicu-dev \
        g++ \
        unixodbc-dev \
        libxml2-dev \
        libaio-dev \
        libmemcached-dev \
        freetds-dev \
        libssl-dev \
        openssl \
        libzip-dev \
        unixodbc-dev \
        mariadb-client

# RUN ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

#Download appropriate package for the OS version
#Choose only ONE of the following, corresponding to your OS version


#Ubuntu 16.04
RUN curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list


# exit
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools
# RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
# RUN 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
# RUN source ~/.bashrc
# optional: for unixODBC development headers
RUN apt-get install unixodbc-dev


RUN docker-php-ext-install pdo pdo_mysql mysqli
RUN a2enmod rewrite

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/local/bin \
        --filename=composer

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure pdo_dblib --with-libdir=/lib/x86_64-linux-gnu \
    && docker-php-ext-configure intl \
    && pecl install sqlsrv-5.6.1 \
    && pecl install pdo_sqlsrv-5.6.1 \
    && pecl install redis \
    && pecl install memcached \
    && pecl install xdebug \
    && pecl install imagick \
    && pecl install mcrypt-1.0.3 \
    && docker-php-ext-install \
            iconv \
            mbstring \
            intl \
            gd \
            mysqli \
            pdo_mysql \
            pdo_dblib \
            soap \
            sockets \
            zip \
            pcntl \
            ftp \
            bcmath \
    && docker-php-ext-enable \
            sqlsrv \
            pdo_sqlsrv \
            redis \
            memcached \
            opcache \
            imagick \
            xdebug

# Install APCu and APC backward compatibility
RUN pecl install apcu \
    && pecl install apcu_bc-1.0.5 \
    && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
    && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

# Clean repository
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY . /var/www/html/

RUN cd /var/www/html && composer install

CMD php artisan serve --host=0.0.0.0 --port=8181

EXPOSE 8181