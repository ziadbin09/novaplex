FROM alpine:3.19

ARG PB_VERSION=0.22.20

RUN apk add --no-cache unzip ca-certificates curl

RUN curl -fsSL \
    "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip" \
    -o pocketbase.zip \
    && unzip pocketbase.zip \
    && rm pocketbase.zip \
    && mv pocketbase /usr/local/bin/pocketbase

VOLUME /pb_data
EXPOSE 8080

# Railway injects $PORT — PocketBase binds to it
CMD sh -c "pocketbase serve --http=0.0.0.0:${PORT:-8080} --dir=/pb_data"
