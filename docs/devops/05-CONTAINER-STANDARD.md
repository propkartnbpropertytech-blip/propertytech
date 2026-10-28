# 05 — CONTAINERIZATION & DOCKERFILE STANDARD

## 1. Multi-Stage Build Architecture
PropKart Backend utilizes a multi-stage Dockerfile (`builder` and `runner` stages) based on pinned LTS base image `node:22-bookworm-slim`.

```dockerfile
# Stage 1: Build & Dependencies
FROM node:22-bookworm-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Stage 2: Minimal Production Runtime
FROM node:22-bookworm-slim AS runner
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl postgresql-client-17 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
COPY src/ ./src/
COPY sql/ ./sql/
COPY scripts/ ./scripts/
USER node
EXPOSE 5001
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:5001/health/liveness || exit 1
CMD ["node", "src/server.js"]
```

## 2. Security Hardening Specifications
1. **Non-Root Execution:**
   - The runtime container switches to unprivileged user `USER node` (UID 1000). Root access inside the container is strictly prohibited.
2. **Minimal Image Attack Surface:**
   - Development dependencies (`eslint`, `nodemon`, `supertest`, `prettier`) are excluded from the runtime container.
   - Pinned `node:22-bookworm-slim` base image removes unnecessary compilers, shells, and package caches.
3. **Container Healthchecks:**
   - Native Docker `HEALTHCHECK` executes curl against `/health/liveness` every 30 seconds.
4. **Direct Process Execution:**
   - `CMD ["node", "src/server.js"]` ensures Node.js runs as PID 1 (or direct child of container init), allowing direct signal delivery for `SIGTERM` and `SIGINT` graceful shutdown.
