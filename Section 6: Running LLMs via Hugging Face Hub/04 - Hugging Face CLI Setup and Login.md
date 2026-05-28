---
title: Hugging Face CLI Setup and Login
date: 2026-05-28
source: "Section 6 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 6: Running LLMs via Hugging Face Hub"
tags:
  - hugging-face
  - cli
  - access-token
  - authentication
  - huggingface-hub
  - homebrew
  - pip
  - foundations
  - hands-on
related:
  - "[[02 - Setting up Hugging Face Account]]"
  - "[[03 - Accessing Gated Models]]"
  - "[[05 - Using the Transformers Package]]"
---

# Hugging Face CLI Setup and Login

> [!abstract] TL;DR
> Install the **Hugging Face CLI** (the official command-line tool for the Hub), then **log in** with an **access token** generated from the HF web UI. Two install paths: `pip install -U "huggingface_hub[cli]"` (works everywhere) or `brew install huggingface-cli` (the macOS shortcut I used). Login command: **`huggingface-cli login`** → paste a token created at *Settings → Access Tokens → New token* with at least **Read** permission. Once logged in, the token is cached at `~/.cache/huggingface/token` and **every HF-aware tool on the machine** (`transformers`, `datasets`, `huggingface_hub`, etc.) auto-uses it — no env vars needed.

> [!info] Where this fits
> Fourth note of **Section 6: Running LLMs via Hugging Face Hub**. With an HF account ([[02 - Setting up Hugging Face Account]]) and an accepted gated model ([[03 - Accessing Gated Models]]), this step sets up the **local authentication** so the `transformers` library can download authenticated models. Next: [[05 - Using the Transformers Package]] uses this auth to actually run the model.

---

## 1. What the HF CLI is

A command-line tool for interacting with the Hugging Face Hub:

| Command | What it does |
|---|---|
| `huggingface-cli login` | Cache a token locally for all HF tools |
| `huggingface-cli logout` | Clear the cached token |
| `huggingface-cli whoami` | Show which account is logged in |
| `huggingface-cli download <repo_id>` | Download a model / dataset / Space |
| `huggingface-cli upload <repo_id> <path>` | Push files to a repo |
| `huggingface-cli repo create <repo_id>` | Create a new repo |
| `huggingface-cli scan-cache` | Inspect cached model storage |
| `huggingface-cli delete-cache` | Free up disk space |

For this section, only `login` (and maybe `whoami`) matters. The CLI's role is mostly to **persist the auth token** in a place every HF library reads from.

---

## 2. Installing the CLI

### Option A — `pip` (universal)

```bash
pip install -U "huggingface_hub[cli]"
```

The `[cli]` extra installs the `huggingface-cli` command alongside the Python library. Works on macOS, Linux, Windows.

### Option B — `brew` (macOS only)

```bash
brew install huggingface-cli
```

Same end result, but managed by Homebrew so updates and uninstalls go through `brew`. On my MacBook I went with `brew install huggingface-cli` — one less Python environment thing to worry about.

Either way: after installation, `huggingface-cli` is available as a shell command.

---

## 3. Generating an access token

Tokens are HF's API credentials — similar to OpenAI's `sk-...` keys ([[01 - Setting up OpenAI Account]]).

### Steps

1. Visit **https://huggingface.co/settings/tokens**.
2. Click **New token** (or **Create new token**).
3. Give it a **name** (e.g., `local-dev`, `course-test`).
4. Pick **permission level**:

| Permission | What it allows |
|---|---|
| **Read** | Download models, datasets, list repos (enough for this section) |
| **Write** | Read + push models, datasets, Spaces, modify content |
| **Fine-grained** | Pick exactly which repos / actions the token can do |

5. Click **Create token**.
6. **Copy the token immediately** — HF only shows it once.

> [!warning] Token security
> Treat tokens like passwords:
> - Don't commit to git (use `.env` or the HF cache).
> - Don't paste in screenshots / videos.
> - Revoke any token shown publicly.
> - Use **Read** permission for environments that don't need writes.
> - Use **Fine-grained** for production CI/CD.

---

## 4. Logging in

```bash
huggingface-cli login
```

The CLI prompts:

```
To login, `huggingface_hub` requires a token generated from https://huggingface.co/settings/tokens .
Enter your token (input will not be visible):
```

Paste the token → hit Enter.

```
Add token as git credential? (Y/n)
```

Answer **No** (Git credentials are only needed when pushing repos to HF via Git; for download-only use, skip).

```
Token is valid (permission: read).
Your token has been saved to ~/.cache/huggingface/token
Login successful
```

At this point the CLI is logged in. From here on, any HF tool on the machine will use this token to pull models — no extra setup per project.

---

## 5. Where the token is cached

After successful login, the token is stored at:

| OS | Path |
|---|---|
| **macOS / Linux** | `~/.cache/huggingface/token` |
| **Windows** | `%USERPROFILE%\.cache\huggingface\token` |

Every HF library checks this path automatically:
- `transformers` — for `from_pretrained(...)` calls.
- `datasets` — for downloading datasets.
- `huggingface_hub` — for everything else.

> [!tip] Multi-user setups
> The cache is per-user. On shared machines, each user must run `huggingface-cli login` separately. To override the cache location: `export HF_HOME=/custom/path`.

---

## 6. Verifying login

Quick sanity check:

```bash
huggingface-cli whoami
```

Output:
```
jayanth
```

(Username of the logged-in account.) If it says "Not logged in", repeat the login step.

Even better — try downloading a tiny public file:

```bash
huggingface-cli download bert-base-uncased config.json
```

If a path is printed, auth works end-to-end.

---

## 7. Alternative — environment variable

Instead of `huggingface-cli login`, the token can be set via env var:

```bash
export HF_TOKEN="hf_..."
```

Add to `.env`:
```
HF_TOKEN=hf_...
```

Then load it in Python:
```python
import os
from huggingface_hub import login
login(token=os.environ["HF_TOKEN"])
```

Useful for:
- CI/CD pipelines (no interactive `huggingface-cli login`).
- Docker containers (set the env var at runtime).
- Avoiding storing tokens in plain text in the home dir.

> [!note] Order of precedence
> The HF libraries check (in order):
> 1. `HF_TOKEN` env var.
> 2. Token passed explicitly to function calls.
> 3. The cached token file from `huggingface-cli login`.
>
> Whichever is found first wins.

---

## 8. Multiple tokens — when to use each

For separate environments:

| Token name | Permission | Where it lives |
|---|---|---|
| `local-dev` | Read | Personal laptop, in HF cache |
| `ci-pipeline` | Read | GitHub Actions env var |
| `deploy-prod` | Fine-grained (specific repos only) | Production secret store |
| `push-models` | Write | Used only when uploading custom fine-tunes |

Rotate tokens periodically (every 6 months or after suspected compromise). Revoke immediately if a token leaks.

---

## 9. Common gotchas

> [!warning] CLI / login issues

| Symptom | Likely cause | Fix |
|---|---|---|
| `huggingface-cli: command not found` | Install didn't add to PATH | Use full path or `python -m huggingface_hub.commands.huggingface_cli login` |
| "Invalid token" | Typo / extra whitespace | Re-copy from web; trim whitespace |
| Login succeeds but `transformers` fails | Token has wrong permission | Regenerate as Read or Write |
| Token works locally, fails in Docker | Env var not passed into container | Add `--env HF_TOKEN` to `docker run` |
| Gated model still 401 after login | Gate not accepted | [[03 - Accessing Gated Models]] |
| `whoami` returns "Not logged in" after login | Wrong shell / wrong user | Run in same shell as the login |
| Logout doesn't clear all keys | Multiple caches | Manually delete `~/.cache/huggingface/token` |

---

## 10. State after this step

| Component | Status |
|---|---|
| HF account | ✅ |
| Email confirmed | ✅ |
| Gate(s) accepted | ✅ |
| HF CLI installed | ✅ |
| Access token created | ✅ |
| `huggingface-cli login` successful | ✅ |
| Token cached at `~/.cache/huggingface/token` | ✅ |
| `transformers` package | ❌ (next note) |
| First model downloaded | ❌ (next note) |

---

## 11. Main takeaways

- **HF CLI** = command-line tool for the Hub; mostly used to persist auth tokens.
- Install via **`pip install -U "huggingface_hub[cli]"`** or **`brew install huggingface-cli`**.
- **Access tokens** are HF's API credentials — created at `huggingface.co/settings/tokens`.
- Three permission levels: **Read** (sufficient), **Write**, **Fine-grained**.
- Login: **`huggingface-cli login`** → paste token → cached at `~/.cache/huggingface/token`.
- All HF libraries (`transformers`, `datasets`, `huggingface_hub`) auto-use the cached token.
- Alternative: set **`HF_TOKEN`** env var (better for CI/CD, Docker).
- Verify with **`huggingface-cli whoami`**.
- Rotate tokens periodically; revoke leaked tokens immediately.

---

## 12. Things I still want to figure out

- For **gated commercial models** (Llama 3.x), does the token automatically gain access after gate acceptance, or does the token need to be regenerated?
- What's the **best practice** for tokens in shared dev environments?
- How does HF's **Fine-grained tokens** scoping compare to OpenAI's project keys?
- Are there **automated tools** to scan local code for leaked HF tokens?
- For Docker containers, what's the cleanest way to pass tokens at build vs runtime?
- How does the HF CLI's caching interact with the **`transformers` model cache**?

---

## 13. Things to dig into

- **HF tokens docs**: https://huggingface.co/docs/hub/security-tokens
- **`huggingface_hub` Python API**: https://huggingface.co/docs/huggingface_hub
- **HF CLI command reference**: `huggingface-cli --help`
- **Fine-grained tokens guide**: useful for production scoping.

---

## 14. Next up in this section

Token is cached. Now use it to download and run a model:

- [ ] [[05 - Using the Transformers Package]] — `pip install transformers`, `from transformers import pipeline`, run Gemma 3 locally.

---

## Related
- [[02 - Setting up Hugging Face Account]] — must be logged in on web to generate tokens.
- [[03 - Accessing Gated Models]] — token's reach extends to gated models accepted on the same account.
- [[05 - Using the Transformers Package]] — the immediate consumer of the cached token.

## Sources
- **HF tokens docs**: https://huggingface.co/docs/hub/security-tokens
- **`huggingface_hub` Python API**: https://huggingface.co/docs/huggingface_hub
- **CLI reference**: `huggingface-cli --help`
