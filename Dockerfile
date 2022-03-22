# Latest version of PHP base image: https://hub.docker.com/_/php?tab=tags
FROM php:8.1.4-fpm-bullseye AS runtime

ARG UNIQUE_ID_FOR_CACHEFROM=runtime

# Latest version of event-extension: https://pecl.php.net/package/event
ARG PHP_EVENT_VERSION=3.0.6

ENV SMTPHOST mail
ENV SMTPEHLO localhost

WORKDIR /var/www

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        ca-certificates \
        openssl \
        curl \
        msmtp-mta \
        # Dependency of the PHP intl-extension
        libicu67 \
        # Dependency of the PHP gd-extension
        libpng16-16 \
        libwebp6 \
        libjpeg62-turbo \
        libfreetype6 \
        # Dependency of PHP zip-extension
        libzip4 \
        # Dependency of PHP event-extension
        libevent-2.1-7 \
        libevent-openssl-2.1-7 \
        libevent-extra-2.1-7 \
    # Install packages that are needed for building PHP extensions
    && apt-get install --assume-yes --no-install-recommends \
        $PHPIZE_DEPS \
        # Dependency of the PHP intl-extension
        libicu-dev \
        # Dependencies of PHP gd-extension
        libpng-dev \
        libwebp-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        # Dependency of PHP zip-extension
        libzip-dev \
        # Dependency of PHP event-extension
        libevent-dev \
        libssl-dev \
    # Configure PHP gd-extension
    && docker-php-ext-configure gd \
        --enable-gd \
        --with-jpeg \
        --with-freetype \
        --with-webp \
    # Install PHP extensions
    && docker-php-ext-install -j "$(nproc --all)" \
        pdo_mysql \
        intl \
        opcache \
        pcntl \
        gd \
        bcmath \
        zip \
        # Dependency of PHP event-extension
        sockets \
    && pecl install "event-$PHP_EVENT_VERSION" \
    && docker-php-ext-enable --ini-name docker-php-ext-zz-event.ini event \
    # Purge packages that where only needed for building php extensions
    && apt-get purge --assume-yes \
        $PHPIZE_DEPS \
        libicu-dev \
        libpng-dev \
        libwebp-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libzip-dev \
        libevent-dev \
        libssl-dev \
    && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    # Cleanup
    && rm -rf /var/www/* \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

COPY files /

FROM runtime AS builder

ARG UNIQUE_ID_FOR_CACHEFROM=builder

# Latest version of Phive: https://api.github.com/repos/phar-io/phive/releases/latest
ARG PHIVE_VERSION=0.15.0
# Latest version of Composer: https://getcomposer.org/download
ARG COMPOSER_VERSION=2.2.9
# Latest version of Xdebug: https://pecl.php.net/package/xdebug
ARG XDEBUG_VERSION=3.1.3

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        # Needed for xdebug extension configuration
        $PHPIZE_DEPS \
        vim \
        git \
        unzip \
        sqlite3 \
        # Needed for phive:
        gnupg \
    # Install Phive
    && curl -fsSLo /usr/local/bin/phive "https://github.com/phar-io/phive/releases/download/$PHIVE_VERSION/phive-$PHIVE_VERSION.phar" \
    && curl -fsSLo /tmp/phive.phar.asc "https://github.com/phar-io/phive/releases/download/$PHIVE_VERSION/phive-$PHIVE_VERSION.phar.asc" \
    && gpg --keyserver keys.openpgp.org --recv-keys 0x9D8A98B29B2D5D79 \
    && gpg --verify /tmp/phive.phar.asc /usr/local/bin/phive \
    && chmod +x /usr/local/bin/phive \
    && phive update-repository-list \
    # Install Composer using Phive
    && phive install --global composer:$COMPOSER_VERSION --trust-gpg-keys CBB3D576F2A0946F \
    && rm -rf /root/.phive \
    # Install Xdebug PHP extension
    && pecl install "xdebug-$XDEBUG_VERSION" \
    && docker-php-ext-enable xdebug \
    && cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    # Cleanup
    && apt-get purge --assume-yes \
        $PHPIZE_DEPS \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

FROM builder AS builder_nodejs

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG UNIQUE_ID_FOR_CACHEFROM=builder_nodejs

RUN apt-get update \
    && curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install --assume-yes --no-install-recommends \
        gcc \
        g++ \
        make \
        nodejs \
    && npm -g install npm@latest \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

FROM builder_nodejs AS vscode

ARG UNIQUE_ID_FOR_CACHEFROM=vscode

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        openssh-client \
        sudo \
        # VSCode Live Share Extension dependencies
        libicu67 \
        libkrb5-3 \
        zlib1g \
        gnome-keyring \
        libsecret-1-0 \
        desktop-file-utils \
        x11-utils \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/*
