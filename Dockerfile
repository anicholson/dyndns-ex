FROM alpine:latest as base

RUN apk update && \
    apk add erlang elixir git curl

RUN mix local.hex --force && \
    mix local.rebar --force

FROM base as builder

RUN mkdir /app
WORKDIR /app

ENV MIX_ENV=prod
ADD . /app
RUN mix deps.get --only prod
RUN mix release

FROM base as release

RUN mkdir /app
WORKDIR /app

COPY --from=builder /app/_build/prod/rel/dyndns /app

EXPOSE 4000

ENTRYPOINT ["/app/bin/dyndns", "start"]