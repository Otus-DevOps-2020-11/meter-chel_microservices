FROM alpine:latest

#ENV POST_SERVICE_HOST=post \
#    POST_SERVICE_PORT=5000 \
#    COMMENT_SERVICE_HOST=comment \
#    COMMENT_SERVICE_PORT=9292 \
ENV APP_HOME=/app

RUN apk update \
    && apk add --no-cache ruby-full ruby-dev build-base \
    && gem install bundler:1.17.2

RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

CMD ["puma"]
