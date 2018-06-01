ARG FLUENTD_VERSION=v0.12
FROM fluent/fluentd:${FLUENTD_VERSION}
RUN apk add ruby-dev build-base
RUN gem install fluent-plugin-elasticsearch --no-rdoc --no-ri --version 2.10.1 
RUN gem install fluent-plugin-grok-parser --no-rdoc --no-ri --version 2.1.6
ADD fluent.conf /fluentd/etc
# v1.2.1
