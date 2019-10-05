FROM jekyll/jekyll:stable

WORKDIR /srv/jekyll

RUN gem install jekyll-admin

CMD ["jekyll", "serve", "--watch", "--force-poll", "--trace"]