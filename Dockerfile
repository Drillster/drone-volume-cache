FROM alpine:3.4
MAINTAINER Michael de Wit <michael@drillster.com>

COPY cacher.sh /usr/local/
RUN mkdir /cache && apk add --no-cache bash rsync && chmod 755 /usr/local/cacher.sh
VOLUME /cache

ENTRYPOINT ["/usr/local/cacher.sh"]
