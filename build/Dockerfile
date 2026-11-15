FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    flatpak ostree binutils xz-utils ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

COPY build/rebuild.sh build/reference.tar build/docker-entrypoint.sh build/install-and-open.sh /opt/claude-build/
COPY open3p.sh /opt/claude-build/open3p.sh
ENTRYPOINT ["bash", "/opt/claude-build/docker-entrypoint.sh"]
