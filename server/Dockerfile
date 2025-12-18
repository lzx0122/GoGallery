# --- Build stage ---
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY . .
RUN apk add --no-cache git && go mod download && go build -o api ./cmd/api

# --- Run stage ---
FROM alpine:latest
WORKDIR /app
# 安裝 ffmpeg 用於影片處理
RUN apk add --no-cache ffmpeg
COPY --from=builder /app/api ./api
COPY --from=builder /app/migrations ./migrations
EXPOSE 8080
ENV GIN_MODE=release
CMD ["./api"]