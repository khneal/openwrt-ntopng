FROM alpine/git:2.49.0 as source
RUN time git clone \
    --branch=6.4-stable \
    https://github.com/ntop/ntopng.git
RUN cd ntopng \
    && git submodule init \
    && time git submodule update --remote

FROM alpine/git:2.49.0 as nDPI_source
RUN time git clone \
    https://github.com/ntop/nDPI.git

FROM docker.io/openwrt/sdk:latest
USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
# See https://github.com/ntop/ntopng/blob/dev/.github/workflows/build.yml#L17
# removed: libglib2.0 
RUN apt-get install -y \
      libxml2-dev \
      libpcap-dev \
      librrd-dev \
      redis-server \
      libsqlite3-dev \
      libhiredis-dev \
      libmaxminddb-dev \
      libcurl4-openssl-dev \
      libzmq3-dev \
      git \
      libjson-c-dev \
      autoconf \
      libtool \
      libssl-dev \
      cmake \
      ;

USER buildbot

COPY --from=nDPI_source --chown=buildbot:buildbot /git/nDPI nDPI
WORKDIR /builder/nDPI
RUN git checkout --detach 28ae2e14d815ee957b2c2838a3a24461912a5bfb
RUN ./autogen.sh
RUN make

WORKDIR /builder
COPY --from=source --chown=buildbot:buildbot /git/ntopng ntopng
WORKDIR /builder/ntopng
RUN git checkout --detach 6ce48d83ad4fd7d39b700e1caf9aea57bf258b32
RUN ./autogen.sh
RUN ./configure
RUN make
RUN make test

USER root
