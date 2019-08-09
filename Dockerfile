FROM ruby:2.6.3-alpine
RUN apk update && apk add --no-cache build-base
RUN mkdir /app
WORKDIR /app

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install
RUN apk del build-base

ADD . /app
CMD bundle exec ruby bin/redash_bot.rb
