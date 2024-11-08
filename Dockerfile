FROM golang:alpine3.20 AS builder

RUN apk update && apk add git make

RUN git clone https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/lyrebird.git

RUN cd lyrebird && make build


FROM alpine:3.20

ENV PROXYCHAINS_CONF=/etc/proxychains.conf \
    TOR_CONF=/etc/torrc.default \
    TOR_LOG_DIR=/var/log/s6/tor

COPY --from=builder /go/lyrebird/lyrebird /usr/local/bin/lyrebird

#RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> \
#      /etc/apk/repositories && \
#    echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> \
#      /etc/apk/repositories && \
RUN    apk --no-cache add --update \
      openssl \
      proxychains-ng \
      s6 \
      curl \
      nmap \
      nmap-scripts \
      nmap-doc \
      nmap-nping \
      nmap-ncat \
#      tor@edge && \
      tor && \
    rm -rf /var/cache/apk/*

COPY etc /etc/
COPY run.sh bin /custom/bin/

RUN chmod +x /custom/bin/* && \
    mkdir -p "$TOR_LOG_DIR" && \
    chown tor $TOR_CONF && \
    chmod 0644 $PROXYCHAINS_CONF && \
    chmod 0755 \
      /etc/s6/*/log/run \
      /etc/s6/*/run

ENV PATH="/custom/bin:${PATH}"
ENTRYPOINT ["/custom/bin/run.sh"]

