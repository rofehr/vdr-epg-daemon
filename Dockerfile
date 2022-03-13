FROM ubuntu:latest

LABEL maintainer="lapicidae"

COPY root/ /

ARG DEBIAN_FRONTEND="noninteractive" \
    LC_ALL="C" \
    S6VER="3.1.0.1"

ENV PATH="$PATH:/command"
ENV LANG="de_DE.UTF-8" \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0"

ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6VER/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6VER/s6-overlay-x86_64.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6VER/syslogd-overlay-noarch.tar.xz /tmp

RUN echo "**** install runtime packages ****" && \
      apt-get update -qq && \
      apt-get upgrade -qy && \
      apt-get install -qy \
        at \
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
        xz-utils \
        zlib1g-dev && \
      if [ ! -e /usr/bin/python-config ]; then ln -sf $(which python3-config) /usr/bin/python-config ; fi && \
    echo "**** s6-overlay ($S6VER) ****" && \
      cd /tmp && \
      tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
      tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    echo "**** syslogd-overlay ($S6VER) ****" && \
      tar -C / -Jxpf /tmp/syslogd-overlay-noarch.tar.xz && \
      touch /etc/s6-overlay/s6-rc.d/syslogd-prepare/dependencies.d/init && \
      patch /etc/s6-overlay/s6-rc.d/syslogd-log/run /build/syslogd-log_run.patch && \
      useradd --system --no-create-home --shell /bin/false syslog && \
      useradd --system --no-create-home --shell /bin/false sysllog && \
    echo "**** locale ****" && \
      localedef -i $(echo "$LANG" | cut -d "." -f 1) -c -f $(echo "$LANG" | cut -d "." -f 2) -A /usr/share/locale/locale.alias $LANG && \
      locale-gen $LANG && \
      update-locale LANG="$LANG" LANGUAGE="$(echo "$LANG" | cut -d "." -f 1):$(echo "$LANG" | cut -d "_" -f 1)" && \
    echo "**** bash tweaks ****" && \
      echo "[ -r /usr/bin/contenv2env ] && . /usr/bin/contenv2env" >> /etc/bash.bashrc && \
      echo "[ -r /etc/bash.aliases ] && . /etc/bash.aliases" >> /etc/bash.bashrc && \
      rm -rf /root/.bashrc && \
    echo "**** create epgd user ****" && \
      useradd --uid 911 --system --no-create-home --shell /bin/false epgd && \
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
    echo "**** get alternative eventsview ****" && \
      wget --quiet -P /defaults/config "https://github.com/MegaV0lt/vdr-plugin-skinflatplus/blob/master/contrib/eventsview-flatplus.sql" && \
    echo "**** get channellogos ****" && \
      cd /tmp && \
      git clone https://github.com/lapicidae/svg-channellogos.git chlogo && \
      chmod +x chlogo/tools/install && \
      chlogo/tools/install -c dark -p /tmp/channellogos -r && \
      tar -cpJf /defaults/channellogos.tar.xz -C /tmp/channellogos . &&\
    echo "**** change permissions ****" && \
      chown -R epgd:epgd /defaults && \
      chown -R epgd:epgd /epgd && \
      chown -R sysllog:sysllog /epgd/log && \
      chown root:root /usr/bin/contenv2env && \
      chmod 755 /usr/bin/contenv2env && \
      chown root:root /usr/bin/svdrpsend && \
      chmod 755 /usr/bin/svdrpsend && \
    echo "**** cleanup ****" && \
      apt-get purge -qy --auto-remove \
        build-essential \
        git \
        wget \
        '*-dev' && \
      apt-get clean && \
      rm -rf \
        /build \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/bin/python-config

WORKDIR /epgd

EXPOSE 9999

VOLUME ["/epgd/cache", "/epgd/config", "/epgd/epgimages"]

ENTRYPOINT ["/init"]
