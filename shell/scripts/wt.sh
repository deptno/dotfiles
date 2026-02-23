wt() {
  if [[ -z "${TMUX:-}" ]]; then
    echo '이 함수는 tmux 세션 안에서만 실행할 수 있습니다.'
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo '현재 디렉토리는 git 저장소가 아닙니다.'
    return 1
  fi

  local CURRENT_REPO_ROOT REPO_ROOT WORKTREE_ROOT COMMON_GIT_DIR
  CURRENT_REPO_ROOT="$(git rev-parse --show-toplevel)"
  COMMON_GIT_DIR="$(git -C "$CURRENT_REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || git -C "$CURRENT_REPO_ROOT" rev-parse --git-common-dir)"
  REPO_ROOT="${COMMON_GIT_DIR%/.git}"
  WORKTREE_ROOT="$REPO_ROOT/.worktrees"

  local GITIGNORE IGNORE_LINE
  GITIGNORE="$REPO_ROOT/.gitignore"
  IGNORE_LINE='.worktrees/'

  if [[ -f "$GITIGNORE" ]]; then
    if ! grep -Fxq "$IGNORE_LINE" "$GITIGNORE"; then
      if [[ -s "$GITIGNORE" && -n "$(tail -c 1 "$GITIGNORE" 2>/dev/null)" ]]; then
        printf '\n' >>"$GITIGNORE"
      fi
      printf '%s\n' "$IGNORE_LINE" >>"$GITIGNORE"
      echo ".gitignore에 추가됨: $IGNORE_LINE"
    fi
  else
    printf '%s\n' "$IGNORE_LINE" >"$GITIGNORE"
    echo ".gitignore 생성 및 추가됨: $IGNORE_LINE"
  fi

  mkdir -p "$WORKTREE_ROOT"
  git -C "$REPO_ROOT" worktree prune --expire now >/dev/null 2>&1 || true

  local RUN_CMD
  if [[ $# -eq 0 ]]; then
    RUN_CMD='opencode'
  else
    RUN_CMD="$(printf '%q ' "$@")"
    RUN_CMD="${RUN_CMD% }"
  fi

  local INDEX WT_PATH BRANCH
  INDEX=1
  # 케이스 1: 이미 있는 창 인덱스는 건너뛴다
  # 케이스 2: 가장 먼저 비어있는 창 인덱스를 선택한다
  while tmux list-windows -F '#I' | grep -Fxq "$INDEX"; do
    INDEX=$((INDEX + 1))
  done

  # 선택된 인덱스를 그대로 worktree 경로/브랜치에 사용한다
  WT_PATH="$WORKTREE_ROOT/$INDEX"
  BRANCH="worktree/$INDEX"

  is_registered_worktree() {
    git -C "$REPO_ROOT" worktree list --porcelain |
      awk '$1=="worktree"{print $2}' |
      grep -Fxq "$WT_PATH"
  }

  delete_branch_if_exists() {
    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
      git -C "$REPO_ROOT" worktree prune --expire now >/dev/null 2>&1 || true
      if ! git -C "$REPO_ROOT" branch -D "$BRANCH" >/dev/null 2>&1; then
        echo "브랜치 정리에 실패했습니다: $BRANCH"
        echo '먼저 `git worktree list` 결과를 확인해주세요.'
        return 1
      fi
    fi
  }

  local MODE
  MODE='create'
  # 선택된 인덱스의 worktree 경로가 이미 있으면 재사용/재생성/취소를 물어본다
  if [[ -e "$WT_PATH" ]]; then
    echo "이미 존재함: $WT_PATH"
    echo "선택: [r] 재사용  [d] 삭제 후 재생성  [c] 취소"

    local CHOICE
    while true; do
      printf '> '
      read -r CHOICE
      case "$CHOICE" in
      r | R)
        if ! is_registered_worktree; then
          echo "이 경로는 git worktree로 등록되어 있지 않습니다. 재사용 불가."
          echo "[d] 삭제 후 재생성 또는 [c] 취소를 선택하세요."
          continue
        fi
        MODE='reuse'
        break
        ;;
      d | D)
        MODE='recreate'
        break
        ;;
      c | C)
        echo '취소됨.'
        return 0
        ;;
      *)
        echo 'r / d / c 중 하나를 입력하세요.'
        ;;
      esac
    done
  fi

  if [[ "$MODE" == 'recreate' ]]; then
    if is_registered_worktree; then
      git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" >/dev/null 2>&1 || true
    else
      rm -rf "$WT_PATH"
    fi
    delete_branch_if_exists || return 1
    MODE='create'
  fi

  if [[ "$MODE" == 'create' ]]; then
    delete_branch_if_exists || return 1
    if ! git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WT_PATH" HEAD; then
      echo 'worktree 생성에 실패했습니다.'
      return 1
    fi
  fi

  local COPIED_ENV=0 ENV_FILE
  while IFS= read -r ENV_FILE; do
    cp -f "$ENV_FILE" "$WT_PATH/"
    COPIED_ENV=1
  done < <(find "$REPO_ROOT" -maxdepth 1 -type f -name '.env*' 2>/dev/null)

  if [[ "$COPIED_ENV" -eq 1 ]]; then
    echo ".env* 복사 완료: $REPO_ROOT -> $WT_PATH"
  fi

  local ENV_PREFIX TMUX_SCRIPT
  ENV_PREFIX="$(
    printf 'WT_PATH=%q REPO_ROOT=%q BRANCH=%q RUN_CMD=%q ' \
      "$WT_PATH" "$REPO_ROOT" "$BRANCH" "$RUN_CMD"
  )"

  TMUX_SCRIPT='
cd "$WT_PATH" || exit 1

echo
echo "[worktree] path: $WT_PATH"
echo "[worktree] branch: $BRANCH"
echo "[run] $RUN_CMD"
echo

bash -lc "$RUN_CMD"
STATUS=$?

echo
read -r -p "이 worktree와 브랜치($BRANCH)를 삭제할까요? [y/N] " ANS || ANS=""
case "$ANS" in
  y|Y|yes|YES)
    if [[ -d "$REPO_ROOT" ]]; then
      cd "$REPO_ROOT" || cd "$HOME" || true
    else
      cd "$HOME" || true
    fi
    git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" >/dev/null 2>&1 || true
    git -C "$REPO_ROOT" branch -D "$BRANCH" >/dev/null 2>&1 || true
    echo "삭제 완료: $WT_PATH ($BRANCH)"
    ;;
  *)
    echo "유지합니다: $WT_PATH ($BRANCH)"
    ;;
esac

echo
echo "[worktree] command exit status: $STATUS"
exec "${SHELL:-/bin/bash}" -l
'

  tmux new-window -t ":$INDEX" -n '' -c "$WT_PATH" "${ENV_PREFIX}bash -lc $(printf '%q' "$TMUX_SCRIPT")"
  tmux select-window -t ":$INDEX"

  echo "사용 INDEX: $INDEX"
  echo "worktree: $WT_PATH"
  echo "branch: $BRANCH"
}
