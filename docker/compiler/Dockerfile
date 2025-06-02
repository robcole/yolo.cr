# Base compiler image with Crystal, ameba, and all build dependencies
# Use Ubuntu/Debian for both architectures - no Alpine anywhere
# Note: ARM64 support limited until Crystal has official ARM64 releases

# Use official Crystal image as base (Ubuntu-based)
FROM crystallang/crystal:1.16.3 AS base

# Install additional dependencies for both architectures
RUN apt-get update && \
    apt-get install -y git curl ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# For future ARM64 support, add architecture detection:
# ARG TARGETARCH
# RUN if [ "$TARGETARCH" = "arm64" ]; then \
#       echo "ARM64 Crystal support coming soon - requires official Crystal ARM64 releases"; \
#     fi

# Use single base for now (Crystal will add ARM64 support in future releases)
FROM base AS final

# Set working directory
WORKDIR /app

# Copy dependency manifests for caching
COPY server/shard.yml server/shard.lock /app/server/
COPY client/shard.yml client/shard.lock /app/client/

# Install and compile all dependencies (no cache mounts for base image)
# This ensures dependencies are permanently stored in the image layers
RUN cd server && \
    shards install --production && \
    shards install ameba && \
    cd ../client && \
    shards install --production && \
    shards install ameba

# Ensure dependencies are accessible for build operations
# Keep as root - user creation will be handled in runtime stage if needed
RUN chmod -R 755 /app

# Default command for interactive use
CMD ["/bin/sh"]