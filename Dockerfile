FROM debian:12-slim AS builder

ENV HOME="/root"
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:$HOME/.pub-cache/bin:${PATH}"
ENV FLUTTER_ROOT="/usr/local/flutter"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash \
        curl \
        git \
        wget \
        unzip \
        libstdc++6 \
        ca-certificates && \
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_ROOT"

RUN flutter doctor && \
    flutter config --enable-web

WORKDIR /app
COPY . .

RUN dart pub global activate melos && \
    melos bootstrap && \
    flutter build web --release --wasm

FROM nginx:1.27-alpine3.20-slim

COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -O /dev/null http://localhost || exit 1

CMD ["nginx", "-g", "daemon off;"]
