FROM alpine:3 AS builder
RUN apk add --no-cache boost-dev zlib openssl openssl-dev libcurl gcc g++ make zlib-dev xmlsec curl-dev fcgi-dev