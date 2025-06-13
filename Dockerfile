FROM alpine/git:2.49.0 as clone
RUN git clone --depth=1 https://github.com/ntop/ntopng.git


FROM docker.io/openwrt/sdk:latest
COPY --from=clone /git/ntopng ntopng
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
