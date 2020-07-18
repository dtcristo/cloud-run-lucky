FROM crystallang/crystal:0.35.1 AS builder

RUN set -ex && \
    apt-get update && \
    apt-get install -y libc6-dev libevent-dev libpcre2-dev libpng-dev libssl1.0-dev libyaml-dev zlib1g-dev curl && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y nodejs yarn && \
    rm -rf /var/lib/apt/lists/*

RUN set -ex && \
    git clone https://github.com/luckyframework/lucky_cli && \
    cd lucky_cli/ && \
    git checkout v0.23.1 && \
    shards install && \
    crystal build src/lucky.cr --release && \
    mv lucky /usr/local/bin/lucky && \
    cd ../ && \
    rm -rf lucky_cli/

RUN mkdir /app
WORKDIR /app/

COPY package.json yarn.lock ./
RUN yarn install

COPY shard.* ./
RUN shards install

COPY . ./
RUN set -ex && \
    yarn prod && \
    lucky build.release

FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y libc6-dev libevent-dev libpcre2-dev libpng-dev libssl1.0-dev libyaml-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /app
WORKDIR /app/
COPY --from=builder /app/public/ ./public/
COPY --from=builder /app/bin/ ./bin/
COPY --from=builder /app/start_server ./

ENV LUCKY_ENV=production
ENV SECRET_KEY_BASE=+ix4d1L8LrwkP5ytR4ykLF1pUGyRxK99QwPLIs5UuUQ=
ENV HOST=0.0.0.0
ENV PORT=5000
ENV APP_DOMAIN=unused
ENV DATABASE_URL=unused
ENV SEND_GRID_KEY=unused

CMD ["./start_server"]
