FROM ruby:3.3-alpine

RUN apk add --no-cache \
    build-base \
    sqlite-dev

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

COPY . .

CMD ["irb"]
