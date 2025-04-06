# syntax=docker/dockerfile:1.4
# Użycie rozszerzonego frontendu BuildKit

# Etap 1: aplikacja Go
FROM golang:1.20-alpine AS builder

ARG VERSION
ENV APP_VERSION=${VERSION}

WORKDIR /app

RUN --mount=type=secret,id=sshkey \
    apk add --no-cache git openssh && \
    mkdir -p ~/.ssh && \
    cp /run/secrets/sshkey ~/.ssh/id_ed25519 && \
    chmod 600 ~/.ssh/id_ed25519 && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts && \
    GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519" git clone git@github.com:valdegor/pawcho6.git . && \
    go mod tidy && go build -o app

# Etap Nginx
FROM nginx:alpine

ARG VERSION
ENV APP_VERSION=${VERSION}

LABEL org.opencontainers.image.source="https://github.com/valdegor/pawcho6" \
      org.opencontainers.image.description="Aplikacja Go + Nginx dla lab 6" \
      org.opencontainers.image.authors="Bohdan"

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/app /app/app

RUN printf "server {\n\
    listen 80;\n\
    location / {\n\
        proxy_pass http://127.0.0.1:8080;\n\
    }\n\
}\n" > /etc/nginx/conf.d/default.conf

WORKDIR /app

HEALTHCHECK CMD wget -q --spider http://localhost || exit 1

CMD sh -c "./app & nginx -g 'daemon off;'"

EXPOSE 80
