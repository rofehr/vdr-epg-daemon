#!/bin/bash

baseIMAGE=${baseIMAGE:-"debian"}
baseTAG=${baseTAG:-"stable-slim"}
imageTag=${imageTag:-"vdr-epg-daemon"}
EPGD_DEV=${EPGD_DEV:-"false"}

epgdREPO='https://github.com/horchi/vdr-epg-daemon.git'


if [ "$EPGD_DEV" = 'true' ]; then
    gitDIR=$(mktemp -d --suffix '_epgdGIT')
    git clone --quiet "$epgdREPO" "$gitDIR"
    cd "$gitDIR" || exit 1

    printf -v epgdVersion '%s' "$(git describe --tags)"
    printf -v epgdRevision '%s' "$(git log --pretty=format:'%H' -n 1)"

    cd "$OLDPWD" || exit 1
    rm -rf "$gitDIR"
else
    printf -v epgdVersion '%s' "$(git ls-remote --tags --sort=-version:refname --refs "$epgdREPO" | head -n 1 | cut -d/ -f3)"
    printf -v epgdRevision '%s' "$(git ls-remote -t "${epgdREPO}" "${epgdVersion}" | cut -f 1)"
fi

printf -v dateTime '%(%Y-%m-%dT%H:%M:%S%z)T'
printf -v baseDIGEST '%s' "$(docker image pull "${baseIMAGE}":"${baseTAG}" | grep -i digest | cut -d ' ' -f 2)"

docker build \
    --progress=plain \
    --tag "${imageTag}" \
    --build-arg baseIMAGE="${baseIMAGE}" \
    --build-arg baseTAG="${baseTAG}" \
    --build-arg baseDIGEST="${baseDIGEST}" \
    --build-arg dateTime="${dateTime}" \
    --build-arg epgdRevision="${epgdRevision}" \
    --build-arg epgdVersion="${epgdVersion}" \
    --build-arg EPGD_DEV="${EPGD_DEV}" \
    .
