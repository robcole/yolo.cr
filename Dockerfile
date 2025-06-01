# Multi-stage build for Crystal WebSocket Game Server
FROM crystallang/crystal:1.16.3-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY server/shard.yml server/shard.lock /app/server/
COPY client/shard.yml client/shard.lock /app/client/

# Install dependencies
RUN cd server && shards install --production
RUN cd client && shards install --production

# Copy source code
COPY server/src /app/server/src
COPY client/src /app/client/src

# Install ameba for linting
RUN cd server && shards install ameba
RUN cd client && shards install ameba

# Run linting
RUN cd server && ./bin/ameba src/
RUN cd client && ./bin/ameba src/

# Build binaries
RUN cd server && crystal build src/game_server.cr -o game_server --release --static
RUN cd client && crystal build src/game_client.cr -o game_client --release --static

# Runtime stage with minimal Alpine
FROM alpine:3.19 AS runtime

# Install runtime dependencies
RUN apk add --no-cache ca-certificates

WORKDIR /app

# Copy binaries from builder
COPY --from=builder /app/server/game_server /app/server/
COPY --from=builder /app/client/game_client /app/client/

# Create directories for state files
RUN mkdir -p /app/server /app/client

# Expose server port
EXPOSE 3000

# Default command runs the server
CMD ["/app/server/game_server"]