FROM python:3.6.0-alpine

ENV POST_DATABASE_HOST=post_db POST_DATABASE=posts

WORKDIR /app
ADD . /app

RUN pip install --upgrade pip && \
    apk --no-cache --update add build-base && \
    pip install -r /app/requirements.txt && \
    apk del build-base

CMD ["python3", "post_app.py"]
