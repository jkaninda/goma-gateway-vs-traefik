# Load generator image:
#   wrk  — closed-loop, maximum-throughput test (same tool as the original benchmark)
#   oha  — open-loop, fixed-rate test with coordinated-omission correction and JSON output
FROM ghcr.io/hatoo/oha:1.17.0 AS oha
FROM debian:trixie-slim
RUN apt-get update && apt-get install -y --no-install-recommends wrk curl jq ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY --from=oha /bin/oha /usr/local/bin/oha
ENTRYPOINT ["bash"]
