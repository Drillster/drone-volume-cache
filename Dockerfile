FROM alpine:3.4
MAINTAINER Michael de Wit <michael@drillster.com>

RUN mkdir /cache && apk add --no-cache bash rsync
COPY cacher.sh /usr/local/
RUN chmod 755 /usr/local/cacher.sh
VOLUME /cache

ENTRYPOINT ["/usr/local/cacher.sh"]
