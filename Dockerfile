# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.4.4
ARG DISTRO_NAME=bookworm

FROM ruby:$RUBY_VERSION-slim-$DISTRO_NAME as base

ARG DISTRO_NAME
ARG PG_MAJOR=17

# Common dependencies
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  build-essential \
  gnupg2 \
  curl \
  less \
  git \
  vim \
  libyaml-dev \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Install PostgreSQL dependencies
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
  gpg --dearmor -o /usr/share/keyrings/postgres-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/postgres-archive-keyring.gpg] https://apt.postgresql.org/pub/repos/apt" \
  $DISTRO_NAME-pgdg main | tee /etc/apt/sources.list.d/postgres.list > /dev/null
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=tmpfs,target=/var/log \
  apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  libpq-dev \
  postgresql-client-$PG_MAJOR

# Configure bundler
ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

ENV APP_HOME /pro-rails
WORKDIR $APP_HOME
COPY Gemfile $APP_HOME/Gemfile
COPY Gemfile.lock $APP_HOME/Gemfile.lock
RUN bundle install
COPY . $APP_HOME

EXPOSE 3000
# Use Bash as the default command
CMD ["/bin/bash"]
