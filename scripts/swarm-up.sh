#!/usr/bin/env bash
# Project Manhattan — spawn a swarm on THIS laptop via tmux. One pane per role; each pane
# sets its role, runs bootstrap, launches Claude Code, and types `start`.
# Usage:  scripts/swarm-up.sh mbp-1 ceo architect integrator developer tester
#         scripts/swarm-up.sh mbp-2 developer developer tester security researcher pm designer reviewer
# First arg = this machine's short label; remaining args = the roles to spawn.
set -euo pipefail

MACHINE="${1:?usage: swarm-up.sh <machine-label> <role> [role ...]}"; shift
ROLES=("$@"); [ "${#ROLES[@]}" -gt 0 ] || { echo "give at least one role"; exit 1; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION="manhattan-$MACHINE"
command -v tmux >/dev/null || { echo "tmux required"; exit 1; }

tmux has-session -t "$SESSION" 2>/dev/null && { echo "session $SESSION exists; attach with: tmux attach -t $SESSION"; exit 0; }
tmux new-session -d -s "$SESSION" -c "$ROOT"

i=0
for role in "${ROLES[@]}"; do
  [ "$i" -eq 0 ] || tmux split-window -t "$SESSION" -c "$ROOT"
  tmux select-layout -t "$SESSION" tiled >/dev/null
  pane="$SESSION.$i"
  tmux send-keys -t "$pane" "export MANHATTAN_MACHINE='$MACHINE' MANHATTAN_ROLE='$role'" C-m
  tmux send-keys -t "$pane" "bash scripts/bootstrap.sh && claude" C-m
  # give Claude Code a moment to boot, then say the magic word
  tmux send-keys -t "$pane" "sleep 6" C-m
  tmux send-keys -t "$pane" "start" C-m
  i=$((i+1))
done

echo "Spawned ${#ROLES[@]} agents in tmux session '$SESSION'."
echo "Attach:  tmux attach -t $SESSION"
echo "Pause the whole swarm:  update control set status='paused';   (the kill switch)"
