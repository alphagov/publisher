# (unless we decide to use Bitnami instead)
ARG base_image=ruby:2.7.6-slim-buster

FROM $base_image AS builder

# TODO: have a separate build image which already contains the build-only deps.
RUN apt-get update -qy && apt-get upgrade -y && apt-get install -y build-essential curl git

RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install -y nodejs yarn && apt-get clean

# TODO: Can ASSETS_PREFIX default to `/assets/publisher` within Publisher?
ENV RAILS_ENV=production GOVUK_APP_NAME=publisher ASSETS_PREFIX=/assets/publisher
RUN mkdir /app

WORKDIR /app
COPY Gemfile Gemfile.lock .ruby-version package.json yarn.lock /app/

RUN bundle config set deployment 'true'
RUN bundle config set without 'development test'
RUN bundle install -j8 --retry=2
RUN yarn install --production --frozen-lockfile
COPY . /app

# TODO: We probably don't want assets in the image; remove this once we have a proper deployment process which uploads to (e.g.) S3.
RUN GOVUK_APP_DOMAIN=www.gov.uk GOVUK_WEBSITE_ROOT=www.gov.uk bundle exec rails assets:precompile

FROM $base_image

# TODO: MONGODB_URI shouldn't be set here but seems to be required by E2E tests, figure out why.
# TODO: Can ASSETS_PREFIX default to `/assets/publisher` within Publisher?
ENV GOVUK_PROMETHEUS_EXPORTER=true RAILS_ENV=production GOVUK_APP_NAME=publisher ASSETS_PREFIX=/assets/publisher MONGODB_URI=mongodb://mongo/govuk_content_development

COPY --from=builder /usr/bin/node* /usr/bin/
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /app /app/

WORKDIR /app
CMD bundle exec puma
