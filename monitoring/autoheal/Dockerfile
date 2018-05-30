FROM golang:1.9.6-stretch  as builder

ARG AUTOHEAL_VERSION='openshift-enterprise-autoheal-3.10.0-0.53.0'

RUN apt-get install git make
WORKDIR /go/src/github.com/openshift

RUN git clone -b $AUTOHEAL_VERSION https://github.com/openshift/autoheal.git
WORKDIR /go/src/github.com/openshift/autoheal
RUN make build 

FROM debian:stretch-slim

COPY --from=builder /go/src/github.com/openshift/autoheal/_output/local/bin/linux/amd64/autoheal /bin/autoheal
ADD entrypoint.sh /bin/entrypoint
RUN chmod +x /bin/entrypoint && cd /root && mkdir .kube && cd .kube && touch config

ADD config.yml /etc/autoheal/config.yml.in
WORKDIR  /etc/autoheal

EXPOSE 9099

ENTRYPOINT /bin/entrypoint
