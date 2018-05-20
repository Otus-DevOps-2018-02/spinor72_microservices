FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git
RUN gem install bundler

WORKDIR /app
COPY . /app

COPY mongod.conf /etc/mongod.conf
COPY db_config /app/db_config
COPY start.sh /start.sh

RUN cd /app && bundle install
RUN chmod 0777 /start.sh

CMD ["/start.sh"]
