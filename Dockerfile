FROM composer:2 AS php-dependencies

WORKDIR /app
COPY composer.json ./
RUN composer update --no-dev --no-interaction --no-progress --prefer-dist --optimize-autoloader

FROM node:20-alpine AS frontend

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY resources ./resources
COPY webpack.mix.js ./
RUN npm run production

FROM linkstackorg/linkstack:latest

USER root
WORKDIR /htdocs

COPY . /htdocs
COPY --from=php-dependencies /app/vendor /htdocs/vendor
COPY --from=frontend /app/public /tmp/linkstack-public

RUN mkdir -p /htdocs/css /htdocs/js \
    && cp -R /tmp/linkstack-public/css/. /htdocs/css/ \
    && cp -R /tmp/linkstack-public/js/. /htdocs/js/ \
    && rm -rf /tmp/linkstack-public \
    && chown -R apache:apache /htdocs

USER apache:apache