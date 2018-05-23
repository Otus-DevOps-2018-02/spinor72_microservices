FROM golang:alpine as builder

ARG PERCONA_MONGODB_EXPORTER_VERSION

RUN apk --no-cache add git make gcc build-base
WORKDIR /go/src/github.com/percona

RUN git clone  --branch $PERCONA_MONGODB_EXPORTER_VERSION --depth 1  https://github.com/percona/mongodb_exporter.git
RUN cd mongodb_exporter && make build


FROM       alpine:3.2
EXPOSE     9216
WORKDIR  /usr/local/bin
COPY --from=builder /go/src/github.com/percona/mongodb_exporter .

ENTRYPOINT [ "mongodb_exporter" ]
