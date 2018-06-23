FROM alpine:3.6

ENV APP_HOME /app
RUN mkdir "$APP_HOME"

WORKDIR $APP_HOME
COPY ./requirements.txt $APP_HOME

RUN apk add --no-cache python3 git gcc g++ python3-dev && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    pip3 install  -r "$APP_HOME/requirements.txt" && \
    python3 -m pip uninstall pip setuptools -y &&\
    apk del git gcc g++ python3-dev &&\
    rm -r /root/.cache

COPY . $APP_HOME
ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

ENTRYPOINT ["python3", "post_app.py"]
