ARG ruby_version=3.3
ARG base_image=ghcr.io/alphagov/govuk-ruby-base:$ruby_version
ARG builder_image=ghcr.io/alphagov/govuk-ruby-builder:$ruby_version


FROM --platform=$TARGETPLATFORM $builder_image AS builder

WORKDIR $APP_HOME
COPY Gemfile* .ruby-version ./
RUN bundle install
COPY package.json yarn.lock ./
RUN yarn install --production --frozen-lockfile --non-interactive --link-duplicates
COPY . .
RUN bootsnap precompile --gemfile .
RUN rails assets:precompile && rm -fr log node_modules


FROM --platform=$TARGETPLATFORM $base_image

ENV GOVUK_APP_NAME=publisher-on-pg

WORKDIR $APP_HOME
COPY --from=builder $BUNDLE_PATH $BUNDLE_PATH
COPY --from=builder $BOOTSNAP_CACHE_DIR $BOOTSNAP_CACHE_DIR
COPY --from=builder $APP_HOME .

RUN chown -R app:app app
USER app
CMD ["puma"]
