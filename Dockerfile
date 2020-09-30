FROM ruby:2.7.1
RUN apt-get update -qq && apt-get upgrade -y
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash -
RUN apt-get update && apt-get install -y nodejs && apt-get install npm -y
RUN npm install -g phantomjs-prebuilt@2 --unsafe-perm
RUN gem install foreman

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

RUN GOVUK_APP_DOMAIN=www.gov.uk GOVUK_WEBSITE_ROOT=www.gov.uk RAILS_ENV=production bundle exec rails assets:precompile

HEALTHCHECK CMD curl --silent --fail localhost:$PORT || exit 1

CMD foreman run web
