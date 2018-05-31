ARG FLUENTD_VERSION=v0.12
FROM fluent/fluentd:${FLUENTD_VERSION}
RUN gem install fluent-plugin-elasticsearch --no-rdoc --no-ri --version 1.9.5
RUN gem install fluent-plugin-grok-parser --no-rdoc --no-ri --version 1.0.0
ADD fluent.conf /fluentd/etc
# v1.2.1
