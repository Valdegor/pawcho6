# Etap 1: budowanie aplikację Go
FROM golang:1.20-alpine AS builder

ARG VERSION
ENV APP_VERSION=${VERSION}

WORKDIR /app
COPY main.go .
RUN go mod init example.com/myapp && go build -o app

# Etap 2: nginx + aplikacja Go jako backend
FROM nginx:alpine

ARG VERSION
ENV APP_VERSION=${VERSION}

# dodawanie narzędzia do uruchomienia Go binarki
RUN apk add --no-cache ca-certificates

# kopiowanie aplikacji
COPY --from=builder /app/app /app/app

# konfiguracja nginx (reverse proxy do Go)
RUN printf "server {\n\
    listen 80;\n\
    location / {\n\
        proxy_pass http://127.0.0.1:8080;\n\
    }\n\
}\n" > /etc/nginx/conf.d/default.conf

# katalog roboczy
WORKDIR /app

# HEALTHCHECK
HEALTHCHECK CMD wget -q --spider http://localhost || exit 1

# Uruchomienie
CMD sh -c "./app & nginx -g 'daemon off;'"

EXPOSE 80
