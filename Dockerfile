FROM ubuntu:latest

LABEL maintainer="lapicidae"

WORKDIR /tmp

ENV LANG="de_DE.UTF-8"

ARG DEBIAN_FRONTEND="noninteractive" \
    LC_ALL="C"

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64-installer /tmp/

ADD https://github.com/just-containers/socklog-overlay/releases/download/v3.1.2-0/socklog-overlay-amd64.tar.gz /tmp/

RUN echo "**** install s6-overlay ****" && \
    chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer / && \
    tar xzf /tmp/socklog-overlay-amd64.tar.gz -C / && \
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
    if [ ! -e /usr/bin/python ]; then ln -sf $(which python3) /usr/bin/python ; fi && \
    echo "**** install build packages ****" && \
    apt-get install -qy \
      build-essential \
      git \
      libarchive-dev \
      libcurl4-openssl-dev \
      libimlib2-dev \
      libjansson-dev \
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
    if [ ! -e /usr/bin/python-config ]; then ln -sf $(which python3-config) /usr/bin/python-config ; fi && \
    echo "**** locale ****" && \
    localedef -i $(echo "$LANG" | cut -d "." -f 1) -c -f $(echo "$LANG" | cut -d "." -f 2) -A /usr/share/locale/locale.alias $LANG && \
    locale-gen $LANG && \
    echo "**** bash tweaks ****" && \
    echo -e "\n[ -r /usr/bin/contenv2env ] && . /usr/bin/contenv2env" >> /etc/bash.bashrc && \
    echo -e "\n[ -r /etc/bash.aliases ] && . /etc/bash.aliases" >> /etc/bash.bashrc && \
    echo "**** folders and symlinks ****" && \
    mkdir -p /defaults/channellogos && \
    mkdir -p /defaults/config && \
    mkdir -p /epgd/cache && \
    mkdir -p /epgd/epgimages && mkdir -p /var/cache/vdr && \
    ln -s /epgd/epgimages /var/cache/vdr/epgimages  && \
    mkdir -p /epgd/channellogos && mkdir -p /var/epgd/www && \
    ln -s /epgd/channellogos /var/epgd/www/channellogos && \
    mkdir -p /epgd/log && \
    echo "**** create abc user ****" && \
    groupmod -g 1000 users && \
    useradd -u 911 -U -d /epgd -s /bin/false abc && \
    usermod -G users abc && \
    echo "**** sendmail config ****" && \
    mv /etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf.bak && \
    ln -s /epgd/config/eMail.conf /etc/ssmtp/ssmtp.conf && \
    usermod -G mail abc && \
    echo "**** compile ****" && \
    cd /tmp && \
    git clone https://projects.vdr-developer.org/git/vdr-epg-daemon.git vdr-epg-daemon && \
    cd vdr-epg-daemon && \
    sed -i  's/CONFDEST     = $(DESTDIR)\/etc\/epgd/CONFDEST     = $(DESTDIR)\/defaults\/config/g' Make.config && \
    sed -i  's/INIT_SYSTEM  = systemd/INIT_SYSTEM  = none/g' Make.config && \
    git clone https://github.com/3PO/epgd-plugin-tvm.git ./PLUGINS/tvm && \
    git clone https://github.com/chriszero/epgd-plugin-tvsp.git ./PLUGINS/tvsp && \
    make all install && \
    echo "**** get channellogos ****" && \
    cd /tmp && \
    git clone https://github.com/lapicidae/svg-channellogos.git chlogo && \
    chmod +x chlogo/tools/install && \
    chlogo/tools/install -c dark -p /defaults/channellogos -r && \
    echo "**** cleanup ****" && \
    apt-get purge -qy --auto-remove \
      build-essential \
      git \
      wget \
      '*-dev' && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
      /tmp/* \
      /var/tmp/* \
      /usr/bin/python-config

# copy local files
COPY root/ /

WORKDIR /epgd

EXPOSE 9999

VOLUME ["/epgd/cache", "/epgd/config", "/epgd/epgimages"]

ENTRYPOINT ["/init"]
