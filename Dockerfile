FROM ruby:alpine

# Add build base for make - gem requires
RUN apk add --no-cache \
    build-base \
    ruby-dev

RUN gem install --no-document \
    bundler \
    tzinfo \
    tzinfo-data
#    jekyll \
#    jekyll-admin
#
#RUN gem install i18n
##RUN gem install ruby_dep --version 1.5.0
##RUN gem install listen --version 3.1.5
##RUN gem install rouge --version 3.11.0

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle install

WORKDIR /srv/jekyll

RUN ls -la

#CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--force-poll", "--trace"]
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0"]
