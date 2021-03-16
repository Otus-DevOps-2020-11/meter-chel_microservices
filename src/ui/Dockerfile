FROM ruby:2.2

#ENV POST_SERVICE_HOST=post \
#    POST_SERVICE_PORT=5000 \
#    COMMENT_SERVICE_HOST=comment \
#    COMMENT_SERVICE_PORT=9292 \
ENV APP_HOME=/app

RUN apt-get update -qq && \
    apt-get install -y build-essential

RUN mkdir $APP_HOME

WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

CMD ["puma"]
