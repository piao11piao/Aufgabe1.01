FROM ruby:2.7.1-alpine

ENV BUNDLER_VERSION=2.0.2

RUN apk add --update --no-cache \
      binutils-gold \
      build-base \
      curl \
      file \
      g++ \
      gcc \
      git \
      less \
      libstdc++ \
      libffi-dev \
      libc-dev \
      linux-headers \
      postgresql-client \
      libxml2-dev \
      libxml2-dev \
      imagemagick \
      libxslt-dev \
      libgcrypt-dev \
      make \
      netcat-openbsd \
      nodejs \
      openssl \
      pkgconfig \
      postgresql-dev \
      tzdata \
      yarn \
      libc6-compat

RUN gem install bundler

WORKDIR /app

#COPY entrypoint.sh /app/entrypoint.sh

#WORKDIR /app/app
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN gem install pkg-config
#RUN gem install nokogiri
RUN gem install rake
RUN bundle lock --add-platform x86_64-linux
RUN bundle config build.nokogiri --use-system-libraries

#RUN bundle check || bundle install
RUN bundle config set specific_platform true
RUN bundle install
COPY package.json package.json 
COPY yarn.lock yarn.lock

RUN yarn install --check-files

COPY . .

#RUN bundle add activerecord-nulldb-adapter && rm config/credentials.yml.enc

# copy database.yml with credentials OR config via DB_URL
#RUN cp config/database.yml.example config/database.yml

#RUN DB_ADAPTER=nulldb bundle exec rake assets:precompile RAILS_ENV=production SECRET_KEY_BASE=foobar

#ENTRYPOINT ["/app/entrypoint.sh"]
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
