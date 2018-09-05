ARG CVER="0.3.2"

FROM ubuntu:16.04 as builder

RUN apt-get update

# We need a PPA for libsodium on trusty:
RUN bash -c 'if [ "$(lsb_release -sc)" == "trusty" ]; then \
               apt-get install -y software-properties-common && \
               add-apt-repository ppa:chris-lea/libsodium && \
               apt-get update; \
             fi'

RUN apt-get install -y build-essential wget unzip git libdb-dev libleveldb-dev libsodium-dev zlib1g-dev libtinfo-dev WORKDIR

# install constellation
ARG CVER
ARG CREL="constellation-$CVER-ubuntu1604"

RUN wget -q https://github.com/jpmorganchase/constellation/releases/download/v$CVER/$CREL.tar.xz && \
    tar xfJ $CREL.tar.xz && \
    cp $CREL/constellation-node /usr/local/bin && chmod 0755 /usr/local/bin/constellation-node && \
    rm -rf $CREL

WORKDIR /constellation
COPY . .

#Constellation
EXPOSE ${CONSTELLATION_PORT}

ENTRYPOINT ["./constellation-start.sh"]