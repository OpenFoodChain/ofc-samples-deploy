FROM ubuntu:16.04 as kmd_builder

ARG KOMODO_BRANCH
ARG KOMODO_REPO
ARG DPOW_NOTARIZER
ARG KMD_NOTARIZER

ENV KOMODO_HOME /home/komodo
COPY *.patch /tmp/

ENV BUILD_PACKAGES="build-essential pkg-config libcurl3-gnutls-dev libc6-dev libevent-dev m4 g++-multilib autoconf libtool ncurses-dev unzip git python zlib1g-dev wget bsdmainutils automake libboost-all-dev libssl-dev libprotobuf-dev protobuf-compiler libqt4-dev libqrencode-dev libdb++-dev curl libcurl3-gnutls-dev libgomp1 libsodium-dev jq"

RUN apt update && \
    apt install -y $BUILD_PACKAGES

RUN useradd -u 3003 -m komodo

USER komodo
WORKDIR ${KOMODO_HOME}

# RUN git clone https://github.com/jl777/komodo && \
RUN git clone ${KOMODO_REPO} && \
    cd komodo && \
    git checkout ${KOMODO_BRANCH} && \
    git apply -v /tmp/*.patch
RUN cd komodo && ./zcutil/fetch-params.sh
RUN cd komodo && ./zcutil/build.sh -j$(nproc)

# RUN if [ "$DPOW_NOTARIZER" -eq 1 -o "$KMD_NOTARIZER" -eq 1 ]; then echo "Building notarizer!"; \
# RUN cd komodo/src && \
#    git checkout ${DPOW_BRANCH} && \
#    gcc -o /tmp/notarizer cc/dapps/notarizer.c -lm && \
#    cp cc/dapps/pubkeys /tmp
#    # gcc -o /home/komodo/komodo/src/notarizer cc/dapps/notarizer.c -lm ;fi

USER root
RUN apt remove --purge -y $BUILD_PACKAGES $(apt-mark showauto) && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf ${KOMODO_HOME}/depends

RUN apt update && \
    apt install -y curl libcurl3-gnutls-dev libgomp1

# FROM alpine:latest as notarizer
# COPY --from=kmd_builder  /home/komodo/komodo/src/notarizer /bin

FROM ubuntu:16.04 as kmd_minimal
RUN mkdir -p /usr/local/notarizer
RUN useradd -u 3003 -m komodo
ENV KOMODO_HOME /home/komodo

COPY --from=kmd_builder  /home/komodo/komodo/src/komodod /bin
COPY --from=kmd_builder  /home/komodo/komodo/src/komodo-cli /bin
COPY --from=kmd_builder  /home/komodo/.zcash-params /home/komodo/.zcash-params
# COPY --from=notarizer  /bin/notarizer /bin

# PK NOTARIZER COPY --from=notarizer /tmp/notarizer /usr/bin
# PK NOTARIZER COPY --from=notarizer /tmp/pubkeys /usr/local/notarizer/

RUN apt update && \
    apt install -y libcurl3-gnutls-dev curl libgomp1

# confd
RUN curl -L -o /usr/local/bin/confd https://github.com/kelseyhightower/confd/releases/download/v0.15.0/confd-0.15.0-linux-amd64 && \
    chmod +x /usr/local/bin/confd

ADD entrypoint.sh /usr/local/bin
ADD start-komodod.sh /usr/local/bin
COPY confd/ "${KOMODO_HOME}"/confd
RUN chown -R komodo:komodo "${KOMODO_HOME}"/confd

ENV PATH="~/komodo/src/:${PATH}"

USER komodo
WORKDIR "${KOMODO_HOME}"
RUN mkdir ${KOMODO_HOME}/.komodo && \
    mkdir ${KOMODO_HOME}/.bitcoin && \
    touch ${KOMODO_HOME}/.komodo/komodo.conf && \
    chown komodo:komodo "${KOMODO_HOME}"/.komodo/komodo.conf

VOLUME ["/home/komodo/.komodo"]

ENTRYPOINT ["entrypoint.sh"]
CMD ["start-komodod.sh"]
