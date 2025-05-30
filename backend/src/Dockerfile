FROM rust:1.82-slim-bullseye as builder
WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev curl && \
    rm -rf /var/lib/apt/lists/*

# Copy only the files needed for building
COPY Cargo.toml ./
COPY src ./src

# Build the application
RUN cargo build --release

# Create a new stage with a minimal image
FROM debian:bullseye-slim
WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates libssl1.1 && \
    rm -rf /var/lib/apt/lists/*

# Copy only the binary from the builder stage
COPY --from=builder /app/target/release/backend /app/backend

# Set environment variables
ENV RUST_LOG=info

# Run the binary
CMD ["./backend"] 