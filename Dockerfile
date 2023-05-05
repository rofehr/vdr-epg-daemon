FROM ubuntu:latest

LABEL maintainer="lapicidae"

COPY root/ /

ARG DEBIAN_FRONTEND="noninteractive" \
    S6VER="3.1.5.0" \
    inVM="true"

ENV PATH="$PATH:/command"
ENV LANG="de_DE.UTF-8" \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
    S6_VERBOSITY="1"

ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6VER/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6VER/s6-overlay-x86_64.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6VER/syslogd-overlay-noarch.tar.xz /tmp

RUN /usr/bin/bash -c '/install.sh'

WORKDIR /epgd

EXPOSE 9999

VOLUME ["/epgd/cache", "/epgd/config", "/epgd/epgimages"]

ENTRYPOINT ["/init"]
