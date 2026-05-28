#!/usr/bin/env bash
# ---------------------------------------------------------------
# sync-from-vault.sh
# Mirrors Jayanth-Vault/Python-AI/ → llm-memory-notes/ and pushes
# to GitHub if there are any changes.
#
# Triggered by a systemd user timer (sync-llm-notes.timer) daily at
# 18:00 IST. With Persistent=true on the timer, missed runs (laptop
# off/asleep) are caught up on next boot or wake.
#
# Manual run any time:   ~/Desktop/llm-memory-notes/sync-from-vault.sh
# Force via systemd:     systemctl --user start sync-llm-notes.service
#
# Idempotent: does nothing (and creates no empty commits) if the
# vault and public repo are already in sync.
# ---------------------------------------------------------------

set -euo pipefail

# --- Config -----------------------------------------------------
VAULT_SRC="/home/jayanth/Desktop/Jayanth-Vault/Python-AI/"
REPO_DST="/home/jayanth/Desktop/llm-memory-notes"
LOG_FILE="$REPO_DST/sync.log"
BRANCH="main"

# --- Setup ------------------------------------------------------
# systemd services start with a minimal env; make sure PATH covers
# git / rsync / ssh from any of the standard locations.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
export HOME="/home/jayanth"

# Point git at the SSH key directly — no ssh-agent under systemd.
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new"

# --- Logger -----------------------------------------------------
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $*" >> "$LOG_FILE"
}

log "===== sync-from-vault.sh start ====="

# --- Pre-flight checks ------------------------------------------
if [[ ! -d "$VAULT_SRC" ]]; then
  log "ERROR: vault source not found: $VAULT_SRC"
  exit 1
fi

if [[ ! -d "$REPO_DST/.git" ]]; then
  log "ERROR: destination is not a git repo: $REPO_DST"
  exit 1
fi

# --- Sync vault → public repo -----------------------------------
# --delete: propagate renames/removals from the vault
# Excludes: README/.gitignore/.git/log live in the public repo, not the vault
rsync -av --delete \
  --exclude='.git' \
  --exclude='.obsidian' \
  --exclude='README.md' \
  --exclude='.gitignore' \
  --exclude='sync-from-vault.sh' \
  --exclude='sync.log' \
  "$VAULT_SRC" "$REPO_DST/" >> "$LOG_FILE" 2>&1

# --- Check if anything actually changed -------------------------
cd "$REPO_DST"

if [[ -z "$(git status --porcelain)" ]]; then
  log "No changes detected. Done."
  exit 0
fi

# --- Commit & push ----------------------------------------------
log "Changes detected. Committing and pushing..."

git add -A >> "$LOG_FILE" 2>&1

# Build a short summary of what changed for the commit message
CHANGE_SUMMARY=$(git diff --cached --stat | tail -1)
TIMESTAMP=$(date '+%Y-%m-%d')

git commit -m "Auto-sync from vault ($TIMESTAMP)

$CHANGE_SUMMARY
" >> "$LOG_FILE" 2>&1

if git push origin "$BRANCH" >> "$LOG_FILE" 2>&1; then
  log "Push succeeded."
else
  log "ERROR: push failed. Check log above."
  exit 1
fi

log "===== sync-from-vault.sh done ====="
