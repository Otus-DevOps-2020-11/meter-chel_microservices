FROM ruby:2.2

ENV COMMENT_DATABASE_HOST=comment_db COMMENT_DATABASE=comments APP_HOME=/app

RUN apt-get update -qq && apt-get install -y build-essential

RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

CMD ["puma"]
