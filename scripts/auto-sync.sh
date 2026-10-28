#!/usr/bin/env bash
# pgOS auto-sync — commit + push any changes to origin/main.
# Driven by ~/.config/systemd/user/pgos-sync.timer (every 15 min, Persistent).
set -u
cd "$HOME/pgos" || exit 1

if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    git add -A
    git commit -q -m "auto-sync: $(date '+%Y-%m-%d %H:%M')" && echo "committed auto-sync"
fi

git pull --rebase --autostash -q 2>/dev/null
if ! git push -q 2>/dev/null; then
    echo "push failed this cycle (network/keyring asleep?) — will retry on next timer tick"
fi
