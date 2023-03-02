# docker build . -t meow/meowd:latest
# docker run --rm -it cosmoscontracts/meowd:latest /bin/sh
FROM golang:1.18-alpine3.15 AS go-builder

# this comes from standard alpine nightly file
#  https://github.com/rust-lang/docker-rust-nightly/blob/master/alpine3.12/Dockerfile
# with some changes to support our toolchain, etc
RUN set -eux; apk add --no-cache ca-certificates build-base;

#libc-dev, gcc, linux-headers, eudev-dev are used for cgo and ledger installation
RUN apk upgrade --no-cache && apk add bash git make libgcc libc-dev gcc linux-headers eudev-dev jq curl

WORKDIR /go/src/github.com/thesixnetwork/meow
COPY . /go/src/github.com/thesixnetwork/meow/

# See https://github.com/CosmWasm/wasmvm/releases
# Reqired for wasmd (smart contracts support)
ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.0.0/libwasmvm_muslc.aarch64.a /lib/libwasmvm_muslc.aarch64.a
ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.0.0/libwasmvm_muslc.x86_64.a /lib/libwasmvm_muslc.x86_64.a
RUN sha256sum /lib/libwasmvm_muslc.aarch64.a | grep 7d2239e9f25e96d0d4daba982ce92367aacf0cbd95d2facb8442268f2b1cc1fc
RUN sha256sum /lib/libwasmvm_muslc.x86_64.a | grep f6282df732a13dec836cda1f399dd874b1e3163504dbd9607c6af915b2740479

# Copy the library you want to the final location that will be found by the linker flag `-lwasmvm_muslc`
RUN cp /lib/libwasmvm_muslc.$(uname -m).a /lib/libwasmvm_muslc.a

# force it to use static lib (from above) not standard libgo_cosmwasm.so file
RUN LEDGER_ENABLED=false BUILD_TAGS=muslc make build
RUN file /go/src/github.com/thesixnetwork/meow/build/meowd

## Final image for running meowd
# --------------------------------------------------------
FROM alpine:3.15

WORKDIR /root
COPY --from=go-builder /go/src/github.com/thesixnetwork/meow/build/meowd /usr/bin/meowd
# install necessary libraries for binary to run
RUN apk upgrade --no-cache && apk add bash git libgcc jq curl
# RUN mkdir -p /root/.meow
COPY docker/* /opt/
RUN chmod +x /opt/*.sh

WORKDIR /opt

# Blockchain API
EXPOSE 1317
# Tendermint p2p
EXPOSE 26656
# Tendermint node
EXPOSE 26657


CMD ["meowd"]