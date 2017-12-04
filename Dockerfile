FROM ruby:2.4.2
RUN apt-get update -qq && apt-get upgrade -y

RUN curl -sL https://deb.nodesource.com/setup_9.x | bash -
RUN apt-get install -y build-essential nodejs && apt-get clean
RUN npm install -g phantomjs-prebuilt@2 --unsafe-perm

ENV GOVUK_APP_NAME publisher
ENV MONGODB_URI mongodb://mongo/govuk_content_development
ENV TEST_MONGODB_URI mongodb://mongo/govuk_content_publisher_test
ENV PORT 3000
ENV RAILS_ENV development
ENV REDIS_HOST redis

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

CMD bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p $PORT -b '0.0.0.0'"
