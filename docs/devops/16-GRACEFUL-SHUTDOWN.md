# 16 — PROCESS LIFECYCLE & GRACEFUL SHUTDOWN RUNBOOK

## 1. Problem Statement & Motivation
During container restarts, rolling deployments, or orchestrator scaling, processes receive OS signals (`SIGTERM` or `SIGINT`). Without explicit graceful termination handlers:
- In-flight HTTP transactions are abruptly severed, resulting in HTTP 502/504 errors on clients.
- Active PostgreSQL connections are terminated without releasing locks, leading to deadlocks.
- Scheduled cron jobs or background queue pollers are interrupted mid-batch, causing duplicate processing.

## 2. Graceful Shutdown Implementation Architecture
Implemented in `src/server.js`:

```javascript
export async function gracefulShutdown(signal = "SIGTERM", { exit = true } = {}) {
    if (isShuttingDown) return;
    isShuttingDown = true;
    logger.info(`[Shutdown] Received ${signal}. Initiating graceful shutdown sequence...`);

    const forceTimeout = setTimeout(() => {
        logger.error("[Shutdown] Shutdown deadline exceeded. Forcefully killing process.");
        if (exit) process.exit(1);
    }, 10000);
    forceTimeout.unref();

    try {
        // 1. Terminate background cron and polling workers
        stopCronScheduler();

        // 2. Stop accepting incoming HTTP traffic
        if (httpServer && httpServer.listening) {
            await new Promise((resolve) => httpServer.close(() => resolve()));
        }

        // 3. Gracefully close Redis cache connection
        await cacheService.close();

        // 4. Drain and close PostgreSQL database pool
        if (exit) await dbPool.end();

        clearTimeout(forceTimeout);
        logger.info("[Shutdown] Graceful shutdown completed cleanly.");
        if (exit) process.exit(0);
    } catch (err) {
        logger.error(`[Shutdown] Error: ${err.message}`);
        if (exit) process.exit(1);
    }
}
```

## 3. Signal Flow Sequence
1. **Signal Interception:** Process catches `SIGTERM` (orchestrator stop) or `SIGINT` (Ctrl+C).
2. **Force-Kill Deadline:** A 10-second watchdog timer starts. If cleanup takes > 10s, the process exits with code 1.
3. **Worker Cancellation:** Background intervals in `cron.service.js` are cleared via `stopCronScheduler()`.
4. **Listener Close:** `httpServer.close()` stops listening for new TCP connections while allowing in-flight requests up to 10s to complete cleanly.
5. **Cache Disconnect:** Active Redis client closes connections gracefully.
6. **Pool Drain:** PostgreSQL pool connections are gracefully drained.
