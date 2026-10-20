# PROPKART — CONFIGURATION & ENVIRONMENT ARCHITECTURE
**Version:** 1.0.0  
**Status:** CANONICAL CONFIGURATION SPECIFICATION (STEP 1 FOUNDATION)  
**Date:** October 19, 2026  
**Scope:** Multi-Environment Topology, Secret Hygiene & Fail-Safe Isolation  

---

## 1. Multi-Environment Topology

PropKart defines four distinct operational environments:

| Environment | Purpose | Backend URL | PostgreSQL Database | Storage Engine |
| :--- | :--- | :--- | :--- | :--- |
| **Development (`local`)** | Local workstation development and feature coding. | `http://127.0.0.1:5001/api/v1` | Local PostgreSQL 16 (Port 54329 / 54350) | In-Memory / Local Disk / Cloudinary Dev |
| **Testing (`test`)** | Automated CI/CD, unit tests, integration contract suites. | In-memory Mock / Test Server | Local ephemeral PostgreSQL (`test` db) | Local Mock Storage |
| **Staging (`staging`)** | Pre-production testing, QA sign-off, client verification. | `https://staging-api.nbpropertytech.com/api/v1` | Staging PostgreSQL (isolated Supabase project) | Cloudinary Staging Folder |
| **Production (`production`)**| Live enterprise CRM operations across Web, Mobile, VPS. | `https://api-propkart.nbpropertytech.com/api/v1`| Production PostgreSQL (Hostinger VPS Supabase) | Cloudinary Production & AWS S3 |

---

## 2. Environment Isolation & Fail-Safe Defense

### 2.1 Backend Environment Isolation Guard (`src/config/env.js`)
To prevent accidental connection to production databases during local development or test runs, the backend implements `assertEnvIsolation()`:
1. **Local Guard:** If `APP_ENV=local`, the backend strictly refuses to boot if `SUPABASE_URL` or `DATABASE_URL` matches production hostnames (`nbpropertytech.com`, `200.234.36.120`, `api-propkart`). It throws an immediate fatal error:
   ```text
   [env] LOCAL environment must never use Hostinger/production Supabase URL. Refusing to start.
   ```
2. **Production Guard:** If `APP_ENV=production`, the backend strictly refuses to boot if `DATABASE_URL` points to `localhost` or `127.0.0.1`.
3. **Missing Config Fail-Fast:** If `.env.local` is missing when `APP_ENV=local`, it halts execution instead of falling back to default production settings.

### 2.2 Flutter Environment Isolation Guard (`lib/core/config/app_env.dart`)
1. In Flutter release builds (`kReleaseMode`), if `API_BASE_URL` resolves to `localhost` or `127.0.0.1`, `AppEnv` throws a `StateError` to prevent publishing builds pointed to local development servers.
2. In Flutter debug builds, if `API_BASE_URL` resolves to production endpoints without explicit override, it throws an error to prevent dirtying production data.

---

## 3. Configuration Inventory & Credentials Registry

### 3.1 Frontend Configuration Matrix (`c:\NB\propkart`)
Managed via Dart compile-time defines (`--dart-define`) and `lib/core/config/app_env.dart`:

| Key | Description | Default Local Value | Production Source |
| :--- | :--- | :--- | :--- |
| `APP_ENV` | Environment name (`local`, `staging`, `production`) | `local` | Build flag `--dart-define=APP_ENV=production` |
| `API_BASE_URL` | Base URL for REST API | `http://127.0.0.1:5001/api/v1` | `--dart-define=API_BASE_URL=https://api-propkart.nbpropertytech.com/api/v1` |
| `SENTRY_DSN` | Sentry crash reporting DSN | Sentry ingest DSN | `--dart-define=SENTRY_DSN=...` |
| `GLITCHTIP_DSN`| GlitchTip fallback monitoring DSN | Empty string (disabled) | Optional build flag |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud identifier | `jdvya1gl` | Shared public cloud name |
| `CLOUDINARY_API_KEY` | Public client upload API key | `131871686761399` | Shared public API key |

### 3.2 Backend Configuration Matrix (`C:\NB\PropKart-Backend`)
Managed via `.env.local` / `.env.production` through `envalid` and `dotenv`:

| Key | Description | Type / Constraints | Security Classification |
| :--- | :--- | :--- | :--- |
| `PORT` | HTTP Server Port | Integer (default: 5001) | Public / Config |
| `DATABASE_URL` | PostgreSQL direct connection string | PostgreSQL URI | **Secret (Restricted)** |
| `SUPABASE_URL` | Supabase instance URL | HTTPS URL | Internal Config |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (bypasses RLS)| JWT String | **Top Secret (Privileged)** |
| `JWT_SECRET` | Secret key for signing access tokens | $\ge 32$ chars random string | **Top Secret (Crypto)** |
| `JWT_REFRESH_SECRET` | Secret key for signing refresh tokens | $\ge 32$ chars random string | **Top Secret (Crypto)** |
| `REDIS_URL` | Redis instance connection URI | Redis URI / Disabled | Internal Config |
| `CLOUDINARY_API_SECRET` | Secret for signed uploads & media deletion | Secret string | **Secret (Cloud Provider)** |
| `META_VERIFY_TOKEN` | Webhook verification challenge token | Secret string | **Secret (Integration)** |
| `META_APP_SECRET` | App secret for SHA256 HMAC validation | Hex secret string | **Secret (Integration)** |
| `AWS_ACCESS_KEY_ID` | AWS S3 storage access key | Alphanumeric | **Secret (Cloud Provider)** |
| `AWS_SECRET_ACCESS_KEY` | AWS S3 storage secret key | Alphanumeric | **Secret (Cloud Provider)** |

---

## 4. Secret Hygiene & Repository Rules

1. **Zero Plaintext Secrets in Version Control:**
   - `.env`, `.env.local`, `.env.production`, `*.pem`, `*.key` are strictly ignored in `.gitignore`.
   - Only `.env.local.example` and `.env.production.example` (containing sanitized placeholders) are committed.
2. **Compile-Time Define Policy:**
   - Flutter release binaries must be compiled with secrets passed via CI/CD environment variables or secure keystores.
   - Client applications must NEVER store privileged backend credentials (e.g. `SUPABASE_SERVICE_ROLE_KEY` or `CLOUDINARY_API_SECRET`).
3. **Audit Verification:**
   - Static analysis tools (`git-secrets` / pre-commit hooks) must scan commits for accidental secret leakage.
