FROM ruby:2.2
# не проверяется DL3008 Pin versions in apt get install. Instead of `apt-get install <package>` use `apt-get install <package>=<version>`
# hadolint ignore=DL3008
RUN apt-get update -qq && apt-get install -y build-essential --no-install-recommends \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV APP_HOME /app
RUN mkdir "$APP_HOME"
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/
RUN bundle install
COPY . $APP_HOME

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

CMD ["puma"]
