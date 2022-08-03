ARG base_image=ghcr.io/alphagov/govuk-ruby-base:2.7.6
ARG builder_image=ghcr.io/alphagov/govuk-ruby-builder:2.7.6

FROM $builder_image AS builder

# TODO: Can ASSETS_PREFIX default to `/assets/publisher` within Publisher?
ENV GOVUK_APP_NAME=publisher ASSETS_PREFIX=/assets/publisher
RUN mkdir /app

WORKDIR /app
COPY Gemfile Gemfile.lock .ruby-version package.json yarn.lock /app/

RUN bundle install
RUN yarn install --production --frozen-lockfile
COPY . /app

# TODO: We probably don't want assets in the image; remove this once we have a proper deployment process which uploads to (e.g.) S3.
RUN bundle exec rails assets:precompile

FROM $base_image

# TODO: MONGODB_URI shouldn't be set here but seems to be required by E2E tests, figure out why.
# TODO: Can ASSETS_PREFIX default to `/assets/publisher` within Publisher?
ENV GOVUK_APP_NAME=publisher ASSETS_PREFIX=/assets/publisher MONGODB_URI=mongodb://mongo/govuk_content_development

COPY --from=builder /usr/bin/node* /usr/bin/
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /app /app/

WORKDIR /app
CMD bundle exec puma
