FROM ubuntu:bionic

LABEL maintainer="lapicidae"

WORKDIR /tmp

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/

RUN echo "**** install s6-overlay ****" && \
    tar zxf /tmp/s6-overlay-amd64.tar.gz -C / && \
    echo "**** install runtime packages ****" && \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qy \
      libarchive13 \
      libcurl4 \
      libimlib2 \
      libimlib2 \
      libjansson4 \
      libjpeg8 \
      libjpeg8 \
      libmariadbclient18 \
      libmicrohttpd12 \
      libpython3.6 \
      libxml2 \
      libxslt1.1 \
      locales \
      python3 \
      tzdata \
      unzip \
      uuid \
      wget \
      zlib1g && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    echo "**** install build packages ****" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qy \
      build-essential \
      git \
      libarchive-dev \
      libcurl4-openssl-dev \
      libimlib2-dev \
      libimlib2-dev \
      libjansson-dev \
      libjpeg-dev \
      libjpeg-dev \
      libmariadbclient-dev \
      libmicrohttpd-dev \
      libssl-dev \
      libtiff-dev \
      libxml2-dev \
      libxslt1-dev \
      python3-dev \
      uuid-dev \
      zlib1g-dev && \
    if [ ! -e /usr/bin/python-config ]; then ln -sf python3-config /usr/bin/python-config ; fi && \
    echo "**** timezone and locale ****" && \
    echo "Europe/Berlin" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    locale-gen de_DE.UTF-8 && \
    echo "**** folders and symlinks ****" && \
    mkdir -p /defaults/channellogos && \
    mkdir -p /defaults/config && \
    mkdir -p /usr/lib/mysql/plugin && \
    mkdir -p /config && \
    mkdir -p /epgd/cache && \
    mkdir -p /epgd/epgimages && mkdir -p /var/cache/vdr && \
    ln -s /epgd/epgimages /var/cache/vdr/epgimages  && \
    mkdir -p /epgd/channellogos && mkdir -p /var/epgd/www && \
    ln -s /epgd/channellogos /var/epgd/www/channellogos && \
    echo "**** compile ****" && \
    wget https://projects.vdr-developer.org/git/vdr-epg-daemon.git/snapshot/vdr-epg-daemon-1.1.159.tar.gz && \
    tar xzf vdr-epg-daemon-1.1.159.tar.gz && \
    cd vdr-epg-daemon* && \
    sed -i  's/CONFDEST     = $(DESTDIR)\/etc\/epgd/CONFDEST     = $(DESTDIR)\/defaults\/config/g' Make.config && \
    sed -i  's/INIT_SYSTEM  = systemd/INIT_SYSTEM  = none/g' Make.config && \
    sed -i  's/CURL_GLOBAL_NOTHING/CURL_GLOBAL_SSL/' ./lib/curl.c && cat ./lib/curl.c && \
    git clone https://github.com/3PO/epgd-plugin-tvm.git ./PLUGINS/tvm && \
    git clone https://github.com/chriszero/epgd-plugin-tvsp.git ./PLUGINS/tvsp && \
    sed -i  's/CURL_GLOBAL_NOTHING/CURL_GLOBAL_SSL/' ./lib/curl.c && cat ./lib/curl.c && \
    make all install && \
    echo "**** get channellogos ****" && \
    cd /tmp && \
    wget https://github.com/FrodoVDR/channellogos/archive/master.tar.gz && \
    tar xzf master.tar.gz && \
    cp -r channellogos-master/logos-orig/* /defaults/channellogos/ && \
    echo "**** cleanup ****" && \
    apt-get remove -qy \
      build-essential \
      git \
      wget \
      *-dev && \
    apt-get purge -qy --auto-remove && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    if [ -e /usr/bin/python-config ]; then rm /usr/bin/python-config ; fi

# copy local files
COPY root/ /

ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="de_DE.UTF-8" \
    LANGUAGE="de_DE:de" \
    LC_ALL="de_DE.UTF-8"

EXPOSE 9999

VOLUME ["/epgd/cache", "/epgd/channellogos", "/epgd/config", "/epgd/epgimages"]

ENTRYPOINT ["/init"]