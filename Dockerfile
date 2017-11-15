FROM ruby:2.3.1
RUN apt-get update -qq && apt-get upgrade -y

RUN apt-get install -y build-essential nodejs && apt-get clean

ENV PHANTOM_JS phantomjs-2.1.1-linux-x86_64

RUN wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2 && \
    tar xvjf $PHANTOM_JS.tar.bz2 && \
    mv $PHANTOM_JS /usr/local/share && \
    ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /bin/phantomjs && \
    rm $PHANTOM_JS.tar.bz2

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
