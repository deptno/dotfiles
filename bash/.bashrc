export PATH="$HOME/.opencode/bin:$PATH"

alias gpr='git pull --rebase --autostash'
alias gp='git push'
alias lz='lazygit'
alias oc='opencode'

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

wt() {
  set -euo pipefail

  if [[ -z "${TMUX:-}" ]]; then
    echo "This function can only run inside a tmux session."
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Current directory is not a git repository."
    return 1
  fi

  local REPO_ROOT WORKTREE_ROOT COMMON_GIT_DIR MAIN_WORKTREE_ROOT
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  WORKTREE_ROOT="$REPO_ROOT/.worktrees"
  COMMON_GIT_DIR="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir)"
  MAIN_WORKTREE_ROOT="${COMMON_GIT_DIR%/.git}"

  local GITIGNORE IGNORE_LINE
  GITIGNORE="$REPO_ROOT/.gitignore"
  IGNORE_LINE=".worktrees/"

  if [[ -f "$GITIGNORE" ]]; then
    if ! grep -Fxq "$IGNORE_LINE" "$GITIGNORE"; then
      if [[ -s "$GITIGNORE" && -n "$(tail -c 1 "$GITIGNORE" 2>/dev/null)" ]]; then
        printf '\n' >>"$GITIGNORE"
      fi
      printf '%s\n' "$IGNORE_LINE" >>"$GITIGNORE"
      echo ".gitignore updated: $IGNORE_LINE"
    fi
  else
    printf '%s\n' "$IGNORE_LINE" >"$GITIGNORE"
    echo ".gitignore created and updated: $IGNORE_LINE"
  fi

  mkdir -p "$WORKTREE_ROOT"

  local RUN_CMD
  if [[ $# -eq 0 ]]; then
    RUN_CMD="opencode"
  else
    RUN_CMD="$(printf '%q ' "$@")"
    RUN_CMD="${RUN_CMD% }"
  fi

  local INDEX=1
  while tmux list-windows -F '#I' | grep -Fxq "$INDEX"; do
    INDEX=$((INDEX + 1))
  done

  local WT_PATH BRANCH WIN_NAME
  WT_PATH="$WORKTREE_ROOT/$INDEX"
  BRANCH="worktree/$INDEX"
  WIN_NAME="w"

  is_registered_worktree() {
    git -C "$REPO_ROOT" worktree list --porcelain |
      awk '$1=="worktree"{print $2}' |
      grep -Fxq "$WT_PATH"
  }

  local MODE="create"
  if [[ -e "$WT_PATH" ]]; then
    echo "Already exists: $WT_PATH"
    echo "Choose: [r] reuse  [d] delete and recreate  [c] cancel"
    local CHOICE
    while true; do
      read -r -p "> " CHOICE
      case "$CHOICE" in
        r|R)
          if ! is_registered_worktree; then
            echo "This path is not a registered git worktree. Cannot reuse."
            echo "Choose [d] delete and recreate or [c] cancel."
            continue
          fi
          MODE="reuse"
          break
          ;;
        d|D)
          MODE="recreate"
          break
          ;;
        c|C)
          echo "Canceled."
          return 0
          ;;
        *)
          echo "Enter one of: r / d / c"
          ;;
      esac
    done
  fi

  if [[ "$MODE" == "recreate" ]]; then
    if is_registered_worktree; then
      git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" || true
    else
      rm -rf "$WT_PATH"
    fi
    git -C "$REPO_ROOT" branch -D "$BRANCH" >/dev/null 2>&1 || true
    MODE="create"
  fi

  if [[ "$MODE" == "create" ]]; then
    git -C "$REPO_ROOT" branch -D "$BRANCH" >/dev/null 2>&1 || true
    git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WT_PATH" HEAD
  fi

  local COPIED_ENV=0
  local had_nullglob=0
  local -a ENV_FILES
  if shopt -q nullglob; then
    had_nullglob=1
  fi
  shopt -s nullglob
  ENV_FILES=("$MAIN_WORKTREE_ROOT"/.env*)
  for ENV_FILE in "${ENV_FILES[@]}"; do
    if [[ -f "$ENV_FILE" ]]; then
      cp -f "$ENV_FILE" "$WT_PATH/"
      COPIED_ENV=1
    fi
  done
  if [[ "$had_nullglob" -eq 0 ]]; then
    shopt -u nullglob
  fi

  if [[ "$COPIED_ENV" -eq 1 ]]; then
    echo ".env* copied: $MAIN_WORKTREE_ROOT -> $WT_PATH"
  fi

  local ENV_PREFIX TMUX_SCRIPT
  ENV_PREFIX="$(
    printf 'WT_PATH=%q REPO_ROOT=%q BRANCH=%q RUN_CMD=%q ' \
      "$WT_PATH" "$REPO_ROOT" "$BRANCH" "$RUN_CMD"
  )"

  TMUX_SCRIPT='
set -euo pipefail
cd "$WT_PATH"

echo
echo "[worktree] path: $WT_PATH"
echo "[worktree] branch: $BRANCH"
echo "[run] $RUN_CMD"
echo

set +e
bash -lc "$RUN_CMD"
STATUS=$?
set -e

echo
read -r -p "Delete this worktree and branch ($BRANCH)? [y/N] " ANS || ANS=""
case "$ANS" in
  y|Y|yes|YES)
    git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" || true
    git -C "$REPO_ROOT" branch -D "$BRANCH" || true
    echo "Deleted: $WT_PATH ($BRANCH)"
    ;;
  *)
    echo "Kept: $WT_PATH ($BRANCH)"
    ;;
esac

exit "$STATUS"
'

  tmux new-window -t ":$INDEX" -n "$WIN_NAME" -c "$WT_PATH" "${ENV_PREFIX}bash -lc $(printf '%q' "$TMUX_SCRIPT")"
  tmux select-window -t ":$INDEX"

  echo "Index: $INDEX"
  echo "worktree: $WT_PATH"
  echo "branch: $BRANCH"
}
