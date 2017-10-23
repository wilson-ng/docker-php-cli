FROM php:7.1-cli

MAINTAINER Wilson <frozalid.wilson@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive

RUN \
    apt-get update \
    && apt-get install -y \
        wget \
        git \
        apt-utils \
        redis-server \
        libmcrypt-dev \
        libxslt-dev \
        libsqlite3-dev \
        imagemagick \
        libmagickwand-dev \
        wkhtmltopdf \
        libssl-dev \
        libgmp-dev \
        libicu-dev \
        libssl-dev \
        libuv-dev \
        libelf1 \
        openssl \
        pkg-config \
        uuid-dev \
        zlib1g-dev \
        libpng-dev \
        libpq-dev

#Install Ca Certificates
RUN \
    mkdir /usr/local/share/ca-certificates/cacert.org \
    && wget -P /usr/local/share/ca-certificates/cacert.org http://www.cacert.org/certs/root.crt http://www.cacert.org/certs/class3.crt \
    && update-ca-certificates

#Install Mongodb
RUN \
    mkdir -p /data/db \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 \
    && echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list \
    && apt-get update \
    && apt-get install -y mongodb-org

RUN \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list \
    && echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 \
    && apt-get update \
    && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
    && apt-get install -y oracle-java8-installer

#Elasticsearch 1.7.6
RUN \
    curl -L -O https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.6.tar.gz \
    && tar -zxf elasticsearch-1.7.6.tar.gz -C /opt/ \
    && rm -rf elasticsearch-1.7.6.tar.gz

#Elasticsearch 2.4.6
RUN \
    curl -L -O https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.4.6/elasticsearch-2.4.6.tar.gz \
    && tar -zxf elasticsearch-2.4.6.tar.gz -C /opt/ \
    && rm -rf elasticsearch-2.4.6.tar.gz

RUN pecl install mongodb \
    && docker-php-ext-enable mongodb

RUN pecl install redis \
    && docker-php-ext-enable redis

RUN pecl install imagick \
    && docker-php-ext-enable imagick

RUN docker-php-ext-install -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    gd \
    mcrypt \
    bcmath \
    zip \
    pcntl \
    xsl \
    gmp \
    pdo_sqlite \
    pdo_pgsql \
    intl

# Config PHP and NGINX
RUN \
    mkdir -p /run/php \
    && chown root:root /run/php \
    && touch /usr/local/etc/php/php.ini \
    && echo "Asia/Jakarta" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata \
    && echo "date.timezone = Asia\/Jakarta" > /usr/local/etc/php/php.ini \
    && echo "upload_max_filesize = 250M" > /usr/local/etc/php/php.ini \
    && echo "memory_limit = 512M" > /usr/local/etc/php/php.ini \
    && echo "post_max_size = 250M" > /usr/local/etc/php/php.ini

# Clear cache
RUN \
    apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT service redis-server restart && mongod --fork --logpath /var/log/mongodb.log && bash
