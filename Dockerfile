FROM php:7.2-fpm-stretch

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    libmcrypt-dev \
    libpng-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    curl \
    gnupg \
    git \
    libbz2-dev \
    mariadb-client \
    libc-client2007e-dev \
    libkrb5-dev \
    libicu-dev \
    libpq-dev \
    libsqlite3-dev \
    libpspell-dev \
    libzip-dev \
    unzip \
    libmagickwand-dev \
    libldap2-dev \
    dirmngr \
    && apt-get clean && \
  apt-cache search aspell | egrep -i "dictionary for (gnu )?aspell" | awk '{print $1}' | xargs apt-get install -y && \
  rm -rf /var/lib/apt/lists/*

RUN pecl install redis && \
  docker-php-ext-enable redis && \
  CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" pecl install imagick-3.4.3 && \
  docker-php-ext-enable imagick && \
  docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
  docker-php-ext-configure zip --with-libzip && \
  docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
  docker-php-ext-install -j$(nproc) ldap gd imap bcmath bz2 calendar exif gettext intl opcache pdo_mysql pdo_pgsql pspell zip

RUN curl -Lo composer-setup.php https://getcomposer.org/installer && \
  curl -Ss https://composer.github.io/installer.sha384sum | sha384sum -c && \
  php composer-setup.php --install-dir=/usr/bin --filename=composer && \
  rm composer-setup.php

ARG RC_VERSION=1.3.6
ENV TZ=UTC

RUN cd /opt && \
  gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys F3E4C04BB3DB5D4215C45F7F5AB2BAA141C4F7D5 && \
  curl -Lo roundcube.tgz https://github.com/roundcube/roundcubemail/releases/download/${RC_VERSION}/roundcubemail-${RC_VERSION}.tar.gz && \
  curl -Lo roundcube.tgz.asc https://github.com/roundcube/roundcubemail/releases/download/${RC_VERSION}/roundcubemail-${RC_VERSION}.tar.gz.asc && \
  gpg --verify roundcube.tgz.asc && \
  tar -zxf roundcube.tgz && \
  rm roundcube.tgz roundcube.tgz.asc && \
  mv roundcubemail-${RC_VERSION} roundcube && \
  cd /opt/roundcube/ && \
  mv composer.json-dist composer.json && \
  composer install --no-dev && \
  composer require --update-no-dev pear/net_ldap2:~2.2.0 kolab/Net_LDAP3:dev-master && \
  bin/install-jsdeps.sh && \
  curl -Lo mime.types https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types && \
  mkdir /data /data/temp /data/logs /data/enigma /data/db && \
  chown -R www-data: /data && \
  rm -r /opt/roundcube/plugins/enigma/home && \
  ln -s /data/enigma /opt/roundcube/plugins/enigma/home

WORKDIR /opt/roundcube
VOLUME /opt/roundcube
VOLUME /data
