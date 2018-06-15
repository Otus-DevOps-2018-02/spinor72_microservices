FROM alpine:3.6 as builder

ENV APP_HOME /app
ENV GEM_HOME /usr/local/bundle

RUN mkdir "$APP_HOME"

# не проверяется DL3018 Pin versions in apk add. Instead of `apk add <package>` use `apk add <package>=<version>`
# hadolint ignore=DL3018
RUN apk --no-cache add ruby ruby-io-console ruby-bundler curl ruby-dev build-base \
 && rm -rf /usr/lib/ruby/gems/*/cache/* \
          /$GEMHOME/gems/*/cache/* \
          /var/cache/apk/* \
          /tmp/* \
          /var/tmp/*

WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/

RUN bundle install --without development test


FROM alpine:3.6

ENV APP_HOME /app
ENV GEM_HOME /usr/local/bundle
ENV RAILS_ENV production
# hadolint ignore=DL3018
RUN apk --no-cache add ruby  \
 && rm -rf /var/cache/apk/* \
          /tmp/* \
          /var/tmp/*

COPY --from=builder $GEM_HOME $GEM_HOME

RUN mkdir "$APP_HOME"
WORKDIR $APP_HOME
COPY . $APP_HOME

ENV PATH "$PATH:$GEM_HOME/bin"
ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
