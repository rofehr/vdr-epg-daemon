FROM ubuntu:latest

LABEL maintainer="lapicidae"

WORKDIR /tmp

ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="de_DE.UTF-8" \
    LANGUAGE="de_DE:de" \
    LC_ALL="de_DE.UTF-8" \
    START_EPGHTTPD="yes" \
    TZ="Europe/Berlin"

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.0.0.1/s6-overlay-amd64.tar.gz /tmp/

RUN echo "**** install s6-overlay ****" && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C / --exclude='./bin' && tar xzf /tmp/s6-overlay-amd64.tar.gz -C /usr ./bin && \
    echo "**** install runtime packages ****" && \
    apt-get update -qq && \
    apt-get install -qy \
      bsd-mailx \
      libarchive13 \
      libcurl4 \
      libimlib2 \
      libimlib2 \
      libjansson4 \
      libjpeg8 \
      libmariadb3 \
      libmicrohttpd12 \
      libpython3.8 \
      libxml2 \
      libxslt1.1 \
      locales \
      python3 \
      ssmtp \
      tzdata \
      unzip \
      uuid \
      wget \
      zlib1g && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    echo "**** install build packages ****" && \
    apt-get install -qy \
      build-essential \
      git \
      libarchive-dev \
      libcurl4-openssl-dev \
      libimlib2-dev \
      libjansson-dev \
      libjpeg-dev \
      libmariadb-dev-compat \
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
    rm -f /etc/localtime && \
    ln -s /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    locale-gen $LANG && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo "**** folders and symlinks ****" && \
    mkdir -p /defaults/channellogos && \
    mkdir -p /defaults/config && \
    mkdir -p /usr/lib/mysql/plugin && \
    mkdir -p /epgd/cache && \
    mkdir -p /epgd/epgimages && mkdir -p /var/cache/vdr && \
    ln -s /epgd/epgimages /var/cache/vdr/epgimages  && \
    mkdir -p /epgd/channellogos && mkdir -p /var/epgd/www && \
    ln -s /epgd/channellogos /var/epgd/www/channellogos && \
    echo "**** create abc user ****" && \
    groupmod -g 1000 users && \
    useradd -u 911 -U -d /epgd -s /bin/false abc && \
    usermod -G users abc && \
    echo "**** sendmail config ****" && \
    mv /etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf.bak && \
    ln -s /epgd/config/eMail.conf /etc/ssmtp/ssmtp.conf && \
    usermod -G mail abc && \
    echo "**** compile ****" && \
    git clone git://projects.vdr-developer.org/vdr-epg-daemon.git vdr-epg-daemon && \
    cd vdr-epg-daemon* && \
    sed -i  's/CONFDEST     = $(DESTDIR)\/etc\/epgd/CONFDEST     = $(DESTDIR)\/defaults\/config/g' Make.config && \
    sed -i  's/INIT_SYSTEM  = systemd/INIT_SYSTEM  = none/g' Make.config && \
    git clone https://github.com/3PO/epgd-plugin-tvm.git ./PLUGINS/tvm && \
    git clone https://github.com/chriszero/epgd-plugin-tvsp.git ./PLUGINS/tvsp && \
    make all install && \
    echo "**** get channellogos ****" && \
    cd /tmp && \
    git clone https://github.com/lapicidae/svg-channellogos.git chlogo && \
    chmod +x chlogo/tools/install && \
    chlogo/tools/install -c dark -p /epgd/channellogos -r && \
    echo "**** cleanup ****" && \
    apt-get remove -qy \
      build-essential \
      git \
      wget \
      '*-dev' && \
    apt-get purge -qy --auto-remove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && rm -f /usr/bin/python-config

# copy local files
COPY root/ /

EXPOSE 9999

VOLUME ["/epgd/cache", "/epgd/channellogos", "/epgd/config", "/epgd/epgimages"]

ENTRYPOINT ["/init"]
