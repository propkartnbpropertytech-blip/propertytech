# 19 — AI SECURITY & SECRETS SANITIZATION STANDARD

## 1. Zero Secrets in AI Outputs & Commits
AI coding agents are strictly prohibited from:
- Committing live API keys, JWT secrets, passwords, or private keys to git.
- Printing production credentials or unredacted tokens in chat responses, artifacts, or execution logs.
- Embedding hardcoded database credentials in scratch scripts.

## 2. Automated Secret Detection Rules
Automated pre-commit and CI scans reject any code matching:
- AWS Access Keys: `AKIA[0-9A-Z]{16}`
- RSA Private Keys: `BEGIN RSA PRIVATE KEY`
- Live Stripe / API Keys: `sk_live_[0-9a-zA-Z]{24}`
- Unsanitized Bearer Tokens: `Bearer [A-Za-z0-9-_]{20,}`

## 3. Safe Credential Handling Protocol
When configuration requires secrets:
1. Reference the environment variable name (e.g. `process.env.SUPABASE_SERVICE_ROLE_KEY`).
2. Add placeholder examples in `.env.example` (e.g. `SUPABASE_SERVICE_ROLE_KEY=your_key_here`).
3. Never write real secrets to disk outside host-level `.env.production` or `.env.local` files protected by `.gitignore` and `.dockerignore`.
