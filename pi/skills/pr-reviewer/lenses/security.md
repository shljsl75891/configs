# Lens: Security

Goal: find anything that lets an attacker, a bad input, or a leaked secret cause loss. Include infra and CI files.

## Method

1. **List every trust boundary the hunks touch**: HTTP handlers, queue consumers, webhooks, CLI args, env/config, files, DB rows written by users, third-party responses. Trace each input forward to every sink (query, shell, file path, URL, HTML, log, response).
2. **For every new route/handler/resolver, open its siblings** and compare the auth guard, authorization check, DTO validation, and rate/size limit. A missing one is a finding.
3. **Check `existing-comments.jsonl`** for the same path and nearby line; skip if already raised.
4. **Proven vs. question**: you traced input to sink with `path:line` evidence → Issue/Fix. A plausible path you could not fully confirm → ❓. Never drop a possible 🔴.

## Checks

- **Authn/Authz** — route outside the auth guard; authentication without authorization; `:id` or body id not checked against the caller (IDOR); tenant/org scoping missing in a query; role check done client-side only; privilege escalation via a mass-assigned field.
- **Injection** — string-built SQL/NoSQL/GraphQL/LDAP; `exec`/`execSync` with interpolation (use `execFile`/`spawn` args); `eval`, `new Function`, `vm`; dynamic `require(x)`/`import(x)`; template injection; header/CRLF injection.
- **SSRF / open redirect** — `fetch`/`axios`/`got` on a user-influenced URL with no allowlist or internal-IP block; redirect target from input.
- **Path traversal / files** — `fs`, `path.join`, `sendFile` with user input and no base-dir check; upload without type, size, extension checks; upload stored in a served path; zip-slip.
- **Prototype pollution** — recursive merge, `Object.assign`, `obj[userKey] = v`, lodash `set/merge` on user objects.
- **ReDoS / resource exhaustion** — nested quantifiers or overlapping `.*` on user input; no body-size, page-size, array-length or concurrency cap; unbounded loop/cache/queue fed by input; decompression or expansion before validation.
- **Input validation** — `JSON.parse`, `req.body`, query params, env values used without schema validation; casts (`as`) standing in for validation; NaN/negative/huge numbers accepted.
- **Crypto / secrets** — hardcoded secret, token, key, password, connection string (also in tests, fixtures, config, Dockerfile); weak hash (md5/sha1 for passwords); `Math.random` for tokens/ids; `===` on secrets/HMACs (use `timingSafeEqual`); TLS verification disabled; JWT `none`/unverified decode/no expiry or audience check.
- **Data exposure** — secrets, tokens, PII in logs, errors, responses, analytics; stack traces or raw DB errors to clients; over-broad response objects (entity returned whole); verbose errors that confirm user existence.
- **Web** — CSRF on new cookie-auth state-changing route; cookie missing `HttpOnly`/`Secure`/`SameSite`; permissive CORS (`*` with credentials, reflected origin); missing helmet-style headers.
- **Angular / frontend** — `bypassSecurityTrust*`, `innerHTML`/`[innerHTML]` with dynamic data, `document.write`, `target=_blank` without `noopener`, tokens in `localStorage`, secrets in the bundle/environment files, `postMessage` without origin check.
- **Supply chain** — new or bumped dependency (name typo-squat risk, unmaintained, install scripts), lockfile changes that do not match `package.json`, `git`/URL dependencies, unpinned versions.
- **CI / infra / config** — GitHub Actions: `${{ github.event.* }}`/`head_ref` interpolated in `run:`, `pull_request_target` with checkout of PR code, `permissions` broader than needed, unpinned third-party actions, secrets echoed. Dockerfile: runs as root, `latest` tag, secrets in layers/ARG, `ADD` of remote URL. IaC/config: public bucket, `0.0.0.0/0`, wildcard IAM, debug flags on, default credentials.
- **Logging/audit** — a security-relevant action (auth change, permission change, money movement, deletion) with no audit trail.

## Output

Same JSONL contract as `correctness.md` (one `"type":"file"` line per file read, `"type":"finding"` lines). Severity 🔴 for anything exploitable or leaking secrets/PII. Name source and sink with `path:line` in the Issue text.
