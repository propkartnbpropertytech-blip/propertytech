# 04 — AUTHENTICATION SECURITY

## 1. Authentication Lifecycle

PropKart implements a robust token-based authentication lifecycle combining short-lived JWT access tokens with rotating, cryptographic refresh tokens.

```text
User Credentials (Email + Password)
               │
               ▼
   [Rate Limit & Captcha Guard]
               │
               ▼
 [Argon2id / Bcrypt Hash Verification]
               │
               ▼
   [Issue Access Token + JTI]
   [Issue Rotating Refresh Token]
               │
               ▼
      Client Secure Storage
```

---

## 2. Password Security & Hashing Standards

1. **Algorithms**:
   - Modern password hashing standard: Argon2id (with Bcrypt fallback).
   - Work factor: Default 12 rounds for bcrypt / memory-hard Argon2id parameters.
2. **Password Invariants**:
   - Plaintext passwords are NEVER stored in database columns.
   - Passwords are NEVER logged (redacted automatically via `SecureLog` and backend logger filters).
   - Password hashes are NEVER returned in API responses (strictly stripped by `sanitizeUser`).
   - Passwords are NEVER passed in URL query parameters.

---

## 3. Access Token Architecture

- **Format**: JSON Web Token (JWT) signed using HMAC-SHA256 (`HS256`).
- **Signature Secret**: Sourced exclusively from `process.env.JWT_SECRET` (minimum 32-character high-entropy secret).
- **Mandatory Claims**:
  - `sub`: Unique user ID.
  - `role`: Role claim (`Super Admin`, `Admin`, `Sales`, `Telecaller`).
  - `iss`: Issuer (`propkart-api`).
  - `aud`: Audience (`propkart-client`).
  - `jti`: Cryptographically random UUID uniquely identifying the token instance.
  - `exp`: Short expiration window (default 15 minutes / 1 hour).
- **Enforcement Rules**:
  - Unsigned tokens are unconditionally rejected.
  - Algorithm confusion (e.g. `none`, `RS256` spoofed as `HS256`) is explicitly blocked.
  - Expired tokens fail verification (`jwt expired`).

---

## 4. Refresh Token Security & Rotation

1. **Generation**: 48-byte cryptographically secure random bytes formatted as base64url.
2. **Storage**: Refresh tokens are stored hashed (SHA-256) in Redis (`jwt:refresh:<sha256>`), preventing token theft in the event of database/cache exfiltration.
3. **Automatic Rotation**: On every refresh attempt (`/api/v1/auth/refresh`), the presented token is consumed and invalidated immediately. A brand-new refresh token and access token are issued.
4. **Reuse Detection (Family Revocation)**: Refresh tokens belong to a cryptographic token family (`jwt:refreshfam:<familyId>`). If an already-consumed refresh token is presented a second time (indicating replay attack or token theft), the entire token family is immediately revoked, terminating all active sessions for that user.

---

## 5. Session Revocation & Logout

- **Single Session Logout**: Adds the current access token `jti` to the Redis deny list (`jwt:deny:<jti>`) with a TTL matching token expiration, and deletes the associated refresh token.
- **Revoke All Sessions**: Wipes all registered session JTIs from `jwt:sessions:<userId>`, immediately invalidating all active client devices.
- **Client Side Purge**: Flutter client executes `SecureStorage().deleteToken()` and `SessionCleanup.clearLocalSession()`, wiping memory caches and storage keys.
