# --- Build stage ---
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN apk add --no-cache git && go mod download && go build -o api ./cmd/api

# --- Run stage ---
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/api ./api
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/SYSTEM_CONTEXT.md ./SYSTEM_CONTEXT.md
EXPOSE 8080
ENV GIN_MODE=release
CMD ["./api"]