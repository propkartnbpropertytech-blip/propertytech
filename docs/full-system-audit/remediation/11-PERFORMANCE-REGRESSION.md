# 11 — Performance regression

No P50, P95, or P99 samples were taken.

The full backend suite finished its assertions in about 50 seconds. That is a test-process time, not an API latency.

The live telecaller lock test showed the second session blocked until its 400 ms statement timeout. That is the lock working, not a latency budget for allocation.
