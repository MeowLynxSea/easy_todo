# Rust 1.85+ includes stable support for Rust 2024 edition crates.
FROM rust:1.85-bookworm AS builder

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
RUN mkdir -p src && echo "fn main() {}" > src/main.rs
RUN cargo build --release

COPY . .
RUN cargo build --release

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/easy_todo_sync_server /app/easy_todo_sync_server
COPY --from=builder /app/migrations /app/migrations

ENV PORT=8787
EXPOSE 8787

CMD ["/app/easy_todo_sync_server"]
