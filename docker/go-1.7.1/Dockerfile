# Go cross compiler (xgo): Go 1.7.1
#
# Released under the MIT license.

FROM elasticlic/xgo-base

# Configure the root Go distribution and bootstrap based on it
ENV GO_VERSION 171

RUN \
  export ROOT_DIST=https://storage.googleapis.com/golang/go1.7.1.linux-amd64.tar.gz     && \
  export ROOT_DIST_SHA=43ad621c9b014cde8db17393dc108378d37bc853aa351a6c74bf6432c1bbd182 && \
  \
  $BOOTSTRAP_PURE
