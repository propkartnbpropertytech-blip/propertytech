# 14 — SESSION & TOKEN SECURITY ARCHITECTURE

## 1. Token Lifecycles & Security Bounds

| Token Type | Storage Mechanism | Expiration Window | Revocation Mechanism | Cryptographic Algorithm |
| :--- | :--- | :---: | :--- | :---: |
| **Access Token** | SecureStorage (Mobile) / Memory (Web) | 15 min - 1 hour | Blacklist by `jti` in Redis (`jwt:deny:<jti>`) | HMAC-SHA256 (`HS256`) |
| **Refresh Token** | SecureStorage (Mobile) / Memory / Cookie | 7 - 30 days | Invalidate SHA-256 hash in Redis | 48-byte cryptographically secure random bytes |
| **Web Cookie Session** | HttpOnly, SameSite=Strict, Secure Cookie | Browser session | Cleared via `Set-Cookie` on logout | AES-256-GCM / Signed cookie |

---

## 2. Refresh Token Rotation & Family Tracking

PropKart protects against token replay and session hijacking via **Token Family Revocation**:
1. When a client calls `/api/v1/auth/refresh` with raw refresh token `R1`:
   - Server computes `H1 = sha256(R1)`.
   - Server queries Redis for `jwt:refresh:H1`.
2. **Legitimate Path**:
   - `H1` is found in Redis.
   - Server immediately deletes `jwt:refresh:H1` (single-use consumption).
   - Server generates `R2`, computes `H2 = sha256(R2)`, stores `jwt:refresh:H2`, and issues `R2` + new access token.
3. **Replay Attack Path**:
   - Attacker attempts to replay already-consumed `R1`.
   - `H1` is missing from Redis.
   - The server detects an unauthorized replay attempt, triggers `logSecurityEvent("refresh_reuse_or_invalid")`, looks up the associated `familyId`, and immediately deletes all sessions belonging to that token family.

---

## 3. Flutter Client Token Storage Hardening

1. **Android**: Uses `FlutterSecureStorage` with `AndroidOptions(encryptedSharedPreferences: true)`. Keys are protected using hardware-backed Android KeyStore.
2. **iOS / macOS**: Uses Apple Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
3. **Web**: Uses memory-backed tokens or HttpOnly secure cookies. No sensitive credentials are stored in plaintext `localStorage`.
4. **Log Redaction**: `SecureLog.redact` scrubs JWTs (`eyJ...`) from debug logs.
