FROM node:24-bookworm-slim AS node
FROM ruby:3.1.7-slim-bookworm

ARG CONTAINER_USERID=1000
ARG APP_VERSION=0.0.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git libpq-dev libsqlite3-dev default-libmysqlclient-dev \
    libffi-dev libyaml-dev libxml2-dev libxslt1-dev chromium chromium-driver graphviz \
    && rm -rf /var/lib/apt/lists/*
COPY --from=node /usr/local/bin/node /usr/local/bin/node

RUN groupadd --gid 1000 tsp \
    && useradd --uid "$CONTAINER_USERID" --gid tsp --create-home tsp \
    && gem install bundler --version 2.5.23 --no-document

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_BUILD__FFI=--enable-system-libffi \
    BUNDLE_BUILD__NOKOGIRI=--use-system-libraries \
    BUNDLE_BUILD__NIO4R=--with-cflags=-Wno-return-type \
    BUNDLE_BUILD__SASSC=--disable-march-tune-native
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=3 --retry=3

COPY --chown=tsp:tsp . .
RUN chown tsp:tsp /app
USER tsp
RUN printf '%s\n' "$APP_VERSION" > VERSION

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
