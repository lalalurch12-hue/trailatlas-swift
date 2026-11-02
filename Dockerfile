FROM swift:6.2-noble@sha256:e508ef1e4be68087f720de622b91cbf1e32799a7aa96134b35e6f1a1d656db7a AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends pkg-config zlib1g-dev && rm -rf /var/lib/apt/lists/*
COPY Package.swift Package.resolved ./
COPY Sources ./Sources
RUN swift build -c release --jobs 2

FROM swift:6.2-noble-slim@sha256:ff2ea46c9f6a394881a4971420b06b34a7e8298bb55f4eae1bf4e4fc989f7317
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates tzdata && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/.build/release/TrailAtlas /app/TrailAtlas
COPY Resources /app/Resources
ENV PORT=10000
ENV DATA_DIR=/tmp/trailatlas
EXPOSE 10000
USER 65534:65534
CMD ["/app/TrailAtlas"]
