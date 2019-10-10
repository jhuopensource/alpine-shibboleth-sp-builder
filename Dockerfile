FROM alpine:3 AS builder
RUN apk add --no-cache boost-dev zlib openssl openssl-dev libcurl gcc g++ make zlib-dev xmlsec curl-dev fcgi-dev
WORKDIR /tmp
RUN wget https://shibboleth.net/downloads/log4shib/2.0.0/log4shib-2.0.0.tar.gz -O - | tar xz  && \
    wget https://shibboleth.net/downloads/service-provider/3.0.4/shibboleth-sp-3.0.4.tar.gz -O - | tar xz && \
    wget http://apache.cs.utah.edu//xerces/c/3/sources/xerces-c-3.2.2.tar.gz -O - | tar xz && \
    wget http://apache.osuosl.org/santuario/c-library/xml-security-c-2.0.2.tar.gz -O - | tar xz && \
    wget http://shibboleth.net/downloads/c++-opensaml/3.0.1/xmltooling-3.0.4.tar.gz -O - | tar xz && \
    wget http://shibboleth.net/downloads/c++-opensaml/3.0.1/opensaml-3.0.1.tar.gz  -O - | tar xz && \
    cd /tmp/log4shib-2.0.0 && \
    ./configure --prefix=/opt/shibboleth-sp && make install && \
    cd /tmp/xerces-c-3.2.2 && \
    ./configure --prefix=/opt/shibboleth-sp && make install && \
    cd /tmp/xml-security-c-2.0.2 && \
    export PKG_CONFIG_PATH=/opt/shibboleth-sp/lib/pkgconfig:$PKG_CONFIG_PATH && \
    ./configure --without-xalan --disable-static --with-xerces=/opt/shibboleth-sp \
    --prefix=/opt/shibboleth-sp  && make install && \
    cd /tmp/xmltooling-3.0.4 && \
    ./configure --with-xmlsec=/opt/shibboleth-sp --prefix=/opt/shibboleth-sp -C && make install  && \
    cd /tmp/opensaml-3.0.1 && \
    ./configure --with-log4shib=/opt/shibboleth-sp --prefix=/opt/shibboleth-sp  -C && make install && \
    cd /tmp/shibboleth-sp-3.0.4 && \
    ./configure --prefix=/opt/shibboleth-sp --with-fastcgi && make install

ENV NGINX_VERSION nginx-1.17.4

RUN apk --update add pcre-dev build-base && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    wget https://github.com/openresty/headers-more-nginx-module/archive/master.zip -O nginx-headers-more.zip && \
    unzip nginx-headers-more.zip && \
    wget https://github.com/nginx-shib/nginx-http-shibboleth/archive/master.zip -O nginx-shib.zip && \
    unzip nginx-shib.zip && \
    wget http://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxvf ${NGINX_VERSION}.tar.gz && \
    cd /tmp/src/${NGINX_VERSION} && \
    ./configure \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --add-module=/tmp/src/headers-more-nginx-module-master \
        --add-module=/tmp/src/nginx-http-shibboleth-master \
        --prefix=/etc/nginx \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --sbin-path=/usr/local/sbin/nginx && \
    make && \
    make install