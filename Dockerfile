FROM alpine/git:2.49.0 as source
RUN time git clone \
    --branch=6.4-stable \
    https://github.com/ntop/ntopng.git
RUN cd ntopng \
    && git submodule init \
    && time git submodule update --remote
RUN cd ntopng \
    && git checkout --detach 6ce48d83ad4fd7d39b700e1caf9aea57bf258b32
RUN time git clone \
    https://github.com/ntop/nDPI.git


FROM docker.io/openwrt/sdk:latest
COPY --from=source /git/ntopng ntopng
USER root
RUN apt-get update

# See https://github.com/ntop/ntopng/blob/dev/.github/workflows/build.yml#L17
# removed: libglib2.0 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libxml2-dev libpcap-dev librrd-dev redis-server libsqlite3-dev libhiredis-dev libmaxminddb-dev libcurl4-openssl-dev libzmq3-dev git libjson-c-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y autoconf libtool

WORKDIR /builder/ntopng
RUN ./autogen.sh
WORKDIR /builder
RUN git clone --depth=1 https://github.com/ntop/nDPI.git
WORKDIR /builder/nDPI
RUN ./autogen.sh
RUN make
WORKDIR /builder/ntopng
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libssl-dev
RUN ./configure
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y cmake
RUN make
RUN make test
RUN make install
