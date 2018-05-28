FROM golang:1.9.6-stretch
# as builder

ARG AUTOHEAL_VERSION='openshift-enterprise-autoheal-3.10.0-0.53.0'

RUN apt-get install git make
WORKDIR /go/src/github.com/openshift

RUN git clone  https://github.com/openshift/autoheal.git
WORKDIR /go/src/github.com/openshift/autoheal
RUN make build 
RUN cp _output/local/bin/linux/amd64/autoheal /bin
ADD config.yml /etc/autoheal/autoheal.yml
# FROM       alpine:3.2

# чтобы запутсился подсунем пустой фалйл
RUN cd /root && mkdir .kube && cd .kube && touch config
WORKDIR  /etc/autoheal

EXPOSE 9099

CMD [ "/bin/autoheal", "server", "--master", "localhost", "--logtostderr", "--config-file=/etc/autoheal/autoheal.yml" ]
