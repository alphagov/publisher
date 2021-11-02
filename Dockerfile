# TODO: make this default to govuk-ruby once it's being pushed somewhere public
# (unless we decide to use Bitnami instead)
ARG base_image=ruby:2.7.2-slim-buster

FROM $base_image AS builder
# TODO: have a separate build image which already contains the build-only deps.
RUN apt-get update -qy && apt-get upgrade -y
# TODO: Look to remove Node v9 (below) (E2E tests currently fail without it).
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash -
RUN apt-get update && apt-get install -y build-essential nodejs git npm && \
    npm install -g phantomjs-prebuilt@2 --unsafe-perm
# TODO: Can ASSETS_PREFIX default to `/assets/publisher` within Publisher?
ENV RAILS_ENV=production GOVUK_APP_NAME=publisher ASSETS_PREFIX=/assets/publisher
RUN mkdir /app
WORKDIR /app
COPY Gemfile Gemfile.lock .ruby-version /app/
RUN bundle config set deployment 'true'
RUN bundle config set without 'development test'
RUN bundle install -j8 --retry=2
COPY . /app
# TODO: We probably don't want assets in the image; remove this once we have a proper deployment process which uploads to (e.g.) S3.
RUN GOVUK_APP_DOMAIN=www.gov.uk GOVUK_WEBSITE_ROOT=www.gov.uk bundle exec rails assets:precompile

FROM $base_image
RUN apt-get update -qy && apt-get upgrade -y && \
    apt-get install -y nodejs
# TODO: MONGODB_URI shouldn't be set here but seems to be required by E2E tests, figure out why.
# TODO: Can ASSETS_PREFIX default to `/assets/publisher` within Publisher?
ENV RAILS_ENV=production GOVUK_APP_NAME=publisher ASSETS_PREFIX=/assets/publisher MONGODB_URI=mongodb://mongo/govuk_content_development
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /app /app/
WORKDIR /app
CMD bundle exec puma
