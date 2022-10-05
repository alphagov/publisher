ARG base_image=ghcr.io/alphagov/govuk-ruby-base:3.1.2
ARG builder_image=ghcr.io/alphagov/govuk-ruby-builder:3.1.2

FROM $builder_image AS builder

# TODO: Can ASSETS_PREFIX default to `/assets/publisher` within Publisher?
ENV GOVUK_APP_NAME=publisher ASSETS_PREFIX=/assets/publisher

WORKDIR /app
COPY Gemfile Gemfile.lock .ruby-version package.json yarn.lock /app/

RUN bundle install
RUN yarn install --production --frozen-lockfile
COPY . /app

RUN GOVUK_APP_DOMAIN=www.gov.uk GOVUK_WEBSITE_ROOT=www.gov.uk bundle exec rails assets:precompile


FROM $base_image

# TODO: don't set MONGODB_URI here. Move it to publishing-e2e-tests.
ENV MONGODB_URI=mongodb://mongo/govuk_content_development
# TODO: can ASSETS_PREFIX default to `/assets/publisher` within Publisher?
ENV GOVUK_APP_NAME=publisher ASSETS_PREFIX=/assets/publisher

COPY --from=builder /usr/bin/node* /usr/bin/
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /app /app/

WORKDIR /app
CMD bundle exec puma
