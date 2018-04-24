FROM alpine:3.2

ENV APP_HOME /app
RUN mkdir "$APP_HOME"

WORKDIR $APP_HOME
# копирую файл зависимостей чтобы сруз установить их и удалить бандлер в один проход с пакетами
COPY Gemfile* $APP_HOME/
# не проверяется DL3018 Pin versions in apk add. Instead of `apk add <package>` use `apk add <package>=<version>`
# hadolint ignore=DL3018
RUN apk --no-cache add ruby ruby-io-console ruby-bundler curl ruby-dev build-base \
 && bundle install \
 && apk --no-cache del ruby-dev build-base ruby-bundler \
 && rm -rf /usr/lib/ruby/gems/*/cache/* \
          /var/cache/apk/* \
          /tmp/* \
          /var/tmp/*

COPY . $APP_HOME

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
