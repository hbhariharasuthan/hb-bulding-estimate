# Stage 1: Build Flutter web app (single frontend project)
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app

COPY . .
RUN flutter config --no-analytics && \
    flutter pub get && \
    flutter build web --release

# Stage 2: Serve built files using Nginx
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
