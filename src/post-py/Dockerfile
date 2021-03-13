FROM python:3.6.0-alpine

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

WORKDIR /app
ADD . /app

RUN apk --no-cache --update add build-base gcc musl-dev && \
    pip install -r /app/requirements.txt && \
    apk del build-base

EXPOSE 5000

CMD ["python3", "post_app.py"]
