# Rust 1.85+ includes stable support for Rust 2024 edition crates.
FROM rust:1.85-bookworm AS builder

WORKDIR /app

COPY . .
RUN cargo build --release
RUN test "$(stat -c%s /app/target/release/easy_todo_sync_server)" -gt 3000000

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/easy_todo_sync_server /app/easy_todo_sync_server
COPY --from=builder /app/migrations /app/migrations

ENV PORT=8787
ENV HOST=0.0.0.0
EXPOSE 8787

CMD ["/app/easy_todo_sync_server"]
