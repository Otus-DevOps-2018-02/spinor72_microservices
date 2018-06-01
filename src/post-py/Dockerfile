FROM python:3.6.0-alpine

WORKDIR /app
COPY ./requirements.txt /app
RUN apk add git gcc g++ --no-cache && pip install -r /app/requirements.txt
COPY . /app

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

ENTRYPOINT ["python", "post_app.py"]
