# Stage 1: Use pre-built base compiler image with Crystal + dependencies
ARG BASE_COMPILER_TAG=base-compiler-latest
ARG TARGETPLATFORM
FROM --platform=$TARGETPLATFORM docker.io/robcole/yolo.cr:${BASE_COMPILER_TAG} AS compiler

# The base compiler image already contains:
# - Crystal 1.16.3 + build tools (architecture-specific)
# - All shard dependencies compiled and ready
# - ameba installed for both server and client
# - Proper native binaries for the target architecture

# Stage 2: Build stage - compiles source code using the compiler image
FROM compiler AS builder

# Ensure we're in the right directory and check dependencies
WORKDIR /app

# Verify dependencies are available
RUN ls -la /app/server/ && ls -la /app/client/ && \
    echo "Server lib contents:" && ls -la /app/server/lib/ || echo "No server lib" && \
    echo "Client lib contents:" && ls -la /app/client/lib/ || echo "No client lib"

# Copy source code (this layer rebuilds when source changes)
COPY server/src /app/server/src
COPY client/src /app/client/src

# Run linting for code quality
RUN cd /app/server && ./bin/ameba src/ && \
    cd /app/client && ./bin/ameba src/

# Build fully static binaries with all dependencies linked
RUN cd /app/server && \
    crystal build src/game_server.cr -o game_server --release --static --no-debug --link-flags "-static" && \
    cd /app/client && \
    crystal build src/game_client.cr -o game_client --release --static --no-debug --link-flags "-static"

# Stage 3: Minimal runtime image - just OS + static binaries
# Use multi-platform compatible base
ARG TARGETPLATFORM
FROM --platform=$TARGETPLATFORM debian:bookworm-slim AS runtime

# Install only essential runtime dependencies for networking, health checks, and linting
RUN apt-get update && \
    apt-get install -y ca-certificates curl libyaml-0-2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -g 1000 gameapp && \
    useradd -r -u 1000 -g gameapp -s /bin/sh gameapp

WORKDIR /app

# Create directories and set ownership
RUN mkdir -p /app/server /app/client /app/server/bin /app/client/bin && \
    chown -R gameapp:gameapp /app

# Copy only the static binaries (no dependencies needed)
COPY --from=builder --chown=gameapp:gameapp /app/server/game_server /app/server/
COPY --from=builder --chown=gameapp:gameapp /app/client/game_client /app/client/

# Copy ameba binaries for linting support
COPY --from=builder --chown=gameapp:gameapp /app/server/bin/ameba /app/server/bin/
COPY --from=builder --chown=gameapp:gameapp /app/client/bin/ameba /app/client/bin/

# Switch to non-root user
USER gameapp

# Expose server port
EXPOSE 3000

# Health check using the static binary
HEALTHCHECK --interval=10s --timeout=5s --retries=3 --start-period=10s \
    CMD curl -f http://localhost:3000 || exit 1

# Default command runs the server
CMD ["/app/server/game_server"]