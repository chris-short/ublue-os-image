ARG BASE_IMAGE="bazzite-gnome"
ARG IMAGE="bazzite-gnome"
ARG TAG_VERSION="stable"

FROM scratch AS ctx
COPY / /

FROM ghcr.io/ublue-os/${BASE_IMAGE}:${TAG_VERSION}

ARG BASE_IMAGE="${BASE_IMAGE}"
ARG IMAGE="${IMAGE}:${TAG_VERSION}"
ARG SET_X=""

RUN --mount=type=bind,from=ctx,src=/,dst=/ctx \
    /ctx/build.sh