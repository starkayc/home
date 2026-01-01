# Based on https://github.com/iv-org/invidious/blob/master/docker/Dockerfile
FROM crystallang/crystal:1.18.2-alpine AS builder

RUN apk add --no-cache sqlite-static yaml-static

WORKDIR /patchy

COPY ./shard.yml ./shard.yml
COPY ./shard.lock ./shard.lock
RUN shards install --production

COPY ./src/ ./src/
# TODO: .git folder is required for building – this is destructive.
# See definition of CURRENT_BRANCH, CURRENT_COMMIT and CURRENT_VERSION.
COPY ./.git/ ./.git/

# Copy public folder to image
COPY ./public/ ./public/
COPY ./locales/ ./locales/

RUN --mount=type=cache,target=/root/.cache/crystal \
	crystal build ./src/patchy.cr \
	--release \
	--static --warnings all -s -p -t

FROM alpine:3.23 AS builder-ffmpeg

ARG FFMPEG_VERSION=6.1.2
ARG PREFIX=/opt/ffmpeg
ENV CCACHE_DIR=/root/.ccache
ENV USE_CCACHE=1

RUN mkdir /opt/.ccache

RUN apk add --no-cache \
	build-base \
	coreutils \
	gcc \
	ccache \
	yasm \
	libvpx-dev \
	aom-dev \
	x264-dev \
	x265-dev \
	libwebp-dev \
	libjxl-dev \
	libpng-dev \
	libjpeg-turbo-dev \
	aom-dev

RUN cd /tmp/ && \
	wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
	tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz

# Compile ffmpeg.
RUN --mount=type=cache,target=/root/.ccache \
	cd /tmp/ffmpeg-${FFMPEG_VERSION} && \
	./configure \
		--enable-version3 \
		--enable-gpl \
		--enable-nonfree \
		--enable-small \
		--enable-libaom \
		--enable-libx264 \
		--enable-libx265 \
		--enable-libvpx \
		--enable-libwebp \
		--enable-libjxl \
		--disable-librtmp \
		--disable-lzma \
		--disable-debug \
		--disable-doc \
		--disable-ffplay \
		--disable-ffprobe \
		--disable-protocols \
		--enable-protocol=file,pipe \
		--disable-network \
		--cc="ccache cc" --cxx="ccache c++" \
		--extra-cflags="-I${PREFIX}/include" \
		--extra-ldflags="-L${PREFIX}/lib" \
		--extra-libs="-lpthread -lm" \
		--prefix="${PREFIX}" && \
	make && make install && make distclean

# Cleanup.
RUN rm -rf /var/cache/apk/* /tmp/*

FROM alpine:3.23
# shared-mime-info is required so Crystal is able to guess the mime types
# of uploaded/retrieved files using the file `/etc/mime.types` provided
# by that package.
# This is subject to change with
# https://github.com/crystal-lang/crystal/issues/15763
RUN apk add --no-cache \
	tini \
	mailcap \
	libvpx \
	x264-libs \
	x265-libs \
	aom-libs \
	libwebp \
	libwebpmux \
	libjxl \
	libpng \
	libjpeg

RUN rm -rf /var/cache/apk/* /tmp/*

WORKDIR /patchy

# Default environment variables for the container
ENV UPLOADER_FILES=/data/files
ENV UPLOADER_THUMBNAILS=/data/thumbnails
ENV UPLOADER_DB=/data/db/db.sqlite3

RUN adduser -u 10000 -S patchy

RUN mkdir -p /data && chown -R 10000:10000 /data

COPY --from=builder --chown=patchy:patchy /patchy/patchy /patchy
COPY --from=builder-ffmpeg /opt/ffmpeg/bin/ffmpeg /usr/bin/ffmpeg

EXPOSE 8080

USER patchy

ENTRYPOINT ["/sbin/tini", "--"]

CMD [ "/patchy/patchy" ]