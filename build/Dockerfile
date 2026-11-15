FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    flatpak ostree binutils xz-utils ca-certificates curl nodejs zstd \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://downloads.claude.ai/claude-desktop/key.asc -o /usr/share/keyrings/claude-desktop-archive-keyring.asc \
    && echo 'deb [signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main' > /etc/apt/sources.list.d/claude-desktop.list

COPY build/rebuild.sh build/reference.tar build/docker-entrypoint.sh build/install-and-open.sh build/extract-engine.cjs /opt/claude-build/
COPY open3p.sh /opt/claude-build/open3p.sh
ENTRYPOINT ["bash", "/opt/claude-build/docker-entrypoint.sh"]
