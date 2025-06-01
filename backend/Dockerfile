# Multi-stage build for optimized production image
FROM rust:1.82-slim-bullseye AS builder
WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev curl && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency files first for better caching
COPY Cargo.toml Cargo.lock ./


# Copy the actual source code
COPY src ./src

# Build the application
RUN cargo build --release

# Create a new stage with a minimal image
FROM debian:bullseye-slim AS runtime
WORKDIR /app

# Install runtime dependencies and create non-root user
RUN apt-get update && \
    apt-get install -y ca-certificates libssl1.1 && \
    rm -rf /var/lib/apt/lists/* && \
    useradd --create-home --shell /bin/bash app && \
    chown app:app /app

# Copy only the binary from the builder stage
COPY --from=builder /app/target/release/backend /app/backend

# Copy the .env file
COPY .env /app/.env
RUN chown app:app /app/.env

# Switch to non-root user
USER app

# Set default environment variables (minimal defaults, should be overridden by .env)
ENV RUST_LOG=info

# Expose the port the app runs on
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the binary
CMD ["./backend"] 