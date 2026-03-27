# Stage 1: Build Flutter web app (single frontend project)
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app

# When served behind this image's nginx (mapped e.g. localhost:8080->80), use that origin so /api is proxied.
ARG API_BASE_URL=http://localhost:8080
ENV API_BASE_URL=$API_BASE_URL

COPY . .
RUN flutter config --no-analytics && \
    flutter pub get && \
    flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

# Stage 2: Serve built files using Nginx
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
