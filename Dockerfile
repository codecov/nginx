FROM ubuntu

MAINTAINER James Martinez <jamescmartinez@gmail.com>

# Install prerequisites for Nginx compile
RUN apt-get update && \
    apt-get install -y wget \
                       tar \
                       gcc \
                       libpcre3-dev \
                       zlib1g-dev \
                       make \
                       libssl-dev \
                       libluajit-5.1-dev \
                       perl \
                       curl \
                       build-essential \
                       software-properties-common \
                       libreadline7 \
                       lua5.3 \
                       liblua5.3-dev

# Setup prerequisites for openresty (http://openresty.org/en/)
RUN apt-get update && \
    apt-get install -y gnupg && \
    wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add - && \
    add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" && \
    apt-get update && \
    apt-get install -y openresty

#symlink lua5.3 to lua --otherwise we can't find it below.
RUN ln -s /usr/bin/lua5.3 /usr/bin/lua && \
    ln -s /usr/bin/lua5.3 /usr/local/lua \
    && lua5.3 -v \
    && /usr/local/lua -v


# Download Nginx
WORKDIR /tmp
RUN wget http://nginx.org/download/nginx-1.13.6.tar.gz -O nginx.tar.gz && \
    mkdir nginx && \
    tar xf nginx.tar.gz -C nginx --strip-components=1

# Download Nginx modules
RUN wget https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz -O ngx_devel_kit.tar.gz && \
    mkdir ngx_devel_kit && \
    tar xf ngx_devel_kit.tar.gz -C ngx_devel_kit --strip-components=1
RUN wget https://github.com/openresty/set-misc-nginx-module/archive/v0.32.tar.gz -O set-misc-nginx-module.tar.gz && \
    mkdir set-misc-nginx-module && \
    tar xf set-misc-nginx-module.tar.gz -C set-misc-nginx-module --strip-components=1
RUN wget https://github.com/openresty/lua-nginx-module/archive/v0.10.13.tar.gz -O lua-nginx-module.tar.gz && \
    mkdir lua-nginx-module && \
    tar xf lua-nginx-module.tar.gz -C lua-nginx-module --strip-components=1

RUN wget https://github.com/openresty/luajit2/archive/v2.1-20190329.tar.gz -O luajit-21.tar.gz && \
    mkdir luajit-21 && \
    tar xf luajit-21.tar.gz -C luajit-21 --strip-components=1 && ls && \
    cd luajit-21 && make && make install

RUN find / -name '*luajit*'

ENV LUAJIT_LIB=/usr/local/lib/libluajit-5.1.a
ENV LUAJIT_INC=/usr/local/include/luajit-2.1

# Build Nginx
WORKDIR nginx
RUN ./configure --sbin-path=/usr/local/sbin \
                --conf-path=/etc/nginx/nginx.conf \
                --pid-path=/var/run/nginx.pid \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --with-http_ssl_module \
                --add-module=/tmp/ngx_devel_kit \
                --add-module=/tmp/set-misc-nginx-module \
                --add-module=/tmp/lua-nginx-module && \
    make && \
    make install

# Apply Nginx config
ADD nginx.conf /etc/nginx/nginx.conf

# Expose ports
EXPOSE 8888

# Set default command
CMD ["nginx", "-g", "daemon off;"]
