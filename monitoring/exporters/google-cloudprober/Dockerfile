FROM   alpine:3.2
ARG CLOUDPROBER_VERSION

ENV CLOUDPROBER_ZIP cloudprober-$CLOUDPROBER_VERSION-linux-x86_64
ENV CLOUDPROBER_URL https://github.com/google/cloudprober/releases/download/$CLOUDPROBER_VERSION

WORKDIR /tmp

RUN apk --no-cache add ca-certificates && \
    wget  $CLOUDPROBER_URL/$CLOUDPROBER_ZIP.zip  && \
    unzip  $CLOUDPROBER_ZIP.zip  && \
    mv  cloudprober-$CLOUDPROBER_VERSION-linux-x86_64/cloudprober /usr/local/bin && \
    rm -f -R $CLOUDPROBER_ZIP && \
    rm -f -R $CLOUDPROBER_ZIP.zip

COPY cloudprober.cfg /etc/cloudprober.cfg
 
EXPOSE 9313
WORKDIR /usr/local/bin
ENTRYPOINT [ "cloudprober" , "--logtostderr"]
