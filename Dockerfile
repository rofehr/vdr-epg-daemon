FROM ubuntu:latest

LABEL maintainer="lapicidae"

COPY root/ /

ENV LANG="de_DE.UTF-8"

ARG DEBIAN_FRONTEND="noninteractive" \
    LC_ALL="C" \
    S6VER="2.2.0.3" \
    SOCKVER="3.1.2-0"

ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6VER/s6-overlay-amd64-installer /tmp/

ADD https://github.com/just-containers/socklog-overlay/releases/download/v$SOCKVER/socklog-overlay-amd64.tar.gz /tmp

RUN echo "**** install runtime packages ****" && \
    apt-get update -qq && \
    apt-get upgrade -qy && \
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
      passwd \
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
    echo "**** s6-overlay ($S6VER) & socklog-overlay ($SOCKVER) ****" && \
    chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer / && \
    tar xzf /tmp/socklog-overlay-amd64.tar.gz -C / && \
    echo "**** locale ****" && \
    localedef -i $(echo "$LANG" | cut -d "." -f 1) -c -f $(echo "$LANG" | cut -d "." -f 2) -A /usr/share/locale/locale.alias $LANG && \
    locale-gen $LANG && \
    update-locale LANG="$LANG" LANGUAGE="$(echo "$LANG" | cut -d "." -f 1):$(echo "$LANG" | cut -d "_" -f 1)" && \
    echo "**** bash tweaks ****" && \
    echo "[ -r /usr/bin/contenv2env ] && . /usr/bin/contenv2env" >> /etc/bash.bashrc && \
    echo "[ -r /etc/bash.aliases ] && . /etc/bash.aliases" >> /etc/bash.bashrc && \
    rm -rf /root/.bashrc && \
    echo "**** create epgd user ****" && \
    useradd --system --no-create-home --shell /bin/false epgd && \
    usermod -a -G users epgd && \
    echo "**** folders and symlinks ****" && \
    mkdir -p /defaults/channellogos && \
    mkdir -p /defaults/config && \
    mkdir -p /epgd/cache && \
    mkdir -p /epgd/epgimages && mkdir -p /var/cache/vdr && \
    ln -s /epgd/epgimages /var/cache/vdr/epgimages  && \
    mkdir -p /epgd/channellogos && mkdir -p /var/epgd/www && \
    ln -s /epgd/channellogos /var/epgd/www/channellogos && \
    mkdir -p /epgd/log && \
    echo "**** SMTP client ****" && \
    apt-get install -qy msmtp-mta && \
    wget --quiet -O /etc/msmtprc "https://git.marlam.de/gitweb/?p=msmtp.git;a=blob_plain;f=doc/msmtprc-system.example" && \
    chmod 640 /etc/msmtprc && \
    usermod -a -G mail epgd && \
    echo "**** compile ****" && \
    cd /tmp && \
    git clone https://projects.vdr-developer.org/git/vdr-epg-daemon.git vdr-epg-daemon && \
    cd vdr-epg-daemon && \
    sed -i 's/CONFDEST     = $(DESTDIR)\/etc\/epgd/CONFDEST     = $(DESTDIR)\/defaults\/config/g' Make.config && \
    sed -i 's/INIT_SYSTEM  = systemd/INIT_SYSTEM  = none/g' Make.config && \
    git clone https://github.com/3PO/epgd-plugin-tvm.git ./PLUGINS/tvm && \
    git clone https://github.com/chriszero/epgd-plugin-tvsp.git ./PLUGINS/tvsp && \
    make all install && \
    echo "**** get channellogos ****" && \
    cd /tmp && \
    git clone https://github.com/lapicidae/svg-channellogos.git chlogo && \
    chmod +x chlogo/tools/install && \
    chlogo/tools/install -c dark -p /tmp/channellogos -r && \
    tar -cpJf /defaults/channellogos.tar.xz -C /tmp/channellogos . &&\
    echo "**** change permissions ****" && \
    chown -R epgd:epgd /defaults && \
    chown -R epgd:epgd /epgd && \
    chown -R nobody:nogroup /epgd/log && \
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

WORKDIR /epgd

EXPOSE 9999

VOLUME ["/epgd/cache", "/epgd/config", "/epgd/epgimages"]

ENTRYPOINT ["/init"]
