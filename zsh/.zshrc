export LANG=en_US.UTF-8
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/data"
export PGHOST=localhost

if [ -e ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

# powerlevel10k first
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


export EDITOR='vim'

export HISTSIZE=1000000000
export SAVEHIST=1000000000
setopt EXTENDED_HISTORY

export GEM_HOME=~/.gem/ruby/2.6.8

export PATH="${PATH}:${HOME}/.krew/bin"

fpath+=${ZDOTDIR:-~}/.zsh_functions

# bun completions
[ -s "${HOME}/.bun/_bun" ] && source "${HOME}/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

## wsl
if [[ -d /usr/local/share/chruby ]]; then
  source /usr/local/share/chruby/chruby.sh
  source /usr/local/share/chruby/auto.sh
fi

# android
if [[ -z $ANDROID_HOME ]]; then
  export ANDROID_HOME=$HOME/Library/Android/sdk
  export PATH=$PATH:$ANDROID_HOME/emulator
  export PATH=$PATH:$ANDROID_HOME/tools
  export PATH=$PATH:$ANDROID_HOME/tools/bin
  export PATH=$PATH:$ANDROID_HOME/platform-tools
  export PATH=$PATH:~/.local/share/nvim/lsp_servers/rust
fi
export PATH=$HOME/bin:/usr/local/bin:$PATH


# ohmyzsh
ZSH="${HOME}/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# osx only
if [[ $(uname -s) == "Darwin" ]]; then
  export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH" 
  export PATH="$HOME/.local/bin:$PATH"

  # brew lib
  export DYLD_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_LIBRARY_PATH"

  # chruby
  if [[ -d /opt/homebrew/opt/chruby/share/chruby ]]; then
    source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
    source /opt/homebrew/opt/chruby/share/chruby/auto.sh
  fi

  # nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

  # if [[ $(sysctl -n machdep.cpu.brand_string | cut -d ' ' -f1-2) == "Apple M1" ]]; then
  # fi
  
  # aseprite cli 추가
  export PATH=$PATH:/Applications/Aseprite.app/Contents/MacOS
fi

# poetry
if [ ! -d "$ZSH/custom/plugins/poetry" ]; then
  mkdir $ZSH/custom/plugins/poetry
fi
poetry completions zsh > $ZSH/custom/plugins/poetry/_poetry
export POETRY_CONFIG_DIR=~/.config/pypoetry
export POETRY_CACHE_DIR=~/.cache/pypoetry
export POETRY_DATA_DIR=~/.local/share/pypoetry

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  bundler
  dotenv
  macos
  ruby
  urltools
  rust
  node
  direnv
  aws
  kubectl
  kube-ps1
  kubetail
  poetry
)

source $ZSH/oh-my-zsh.sh

autoload -U +X bashcompinit && bashcompinit
source <(helm completion zsh)

# bind hstr
if which hstr > /dev/null 2>&1; then \
  bindkey -s "\C-r" "\C-a hstr -- \C-j"; \
fi

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# tpm
if [[ -z "$TMUX" ]]; then
  if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi

  if [[ ! -f ~/.oh-my-zsh/themes/zsh-syntax-highlighting.sh ]]; then
    curl https://raw.githubusercontent.com/dracula/zsh-syntax-highlighting/master/zsh-syntax-highlighting.sh -sSo ~/.oh-my-zsh/themes/zsh-syntax-highlighting.sh
  fi
  source ~/.oh-my-zsh/themes/zsh-syntax-highlighting.sh
fi

# alias
alias k=kubectl
alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"
alias m=multipass
alias tt=neomutt
alias wol5600x=$XDG_CONFIG_HOME/sh/wol_x5600.sh
alias shutdown5600x=$XDG_CONFIG_HOME/sh/shutdown_x5600.sh
alias wol5950x=$XDG_CONFIG_HOME/sh/wol_x5950.sh
alias min="open -a /Applications/Min.app"
alias ll="exa --long --all --icons --git --time-style=long-iso --color-scale --links --header --sort=mod --reverse --group-directories-first"
alias lln="exa --long --all --icons --git --time-style=long-iso --color-scale --links --header --reverse --group-directories-first"
alias hl-gh="GREP_COLOR='2;37' grep --color=always -E 'true|$' \
  | GREP_COLOR='2;36;47' grep --color=always -E 'false|$' \
  | GREP_COLOR='5;31;47' grep --color=always -Ei 'release\/|$' \
  | GREP_COLOR='1;33;41' grep --color=always -Ei 'prod\/|$' \
  | GREP_COLOR='2;32' grep --color=always -Ei 'master|APPROVED|$' \
  | GREP_COLOR='1;34' grep --color=always -E 'MERGEABLE|$' \
  | GREP_COLOR='2;37' grep --color=always -E 'UNKNOWN|MERGED|CONFLICTING|REVIEW_REQUIRED|$' \
  | GREP_COLOR='36' grep --color=always -Ei 'b2c-\d{5}|$' \
  | GREP_COLOR='1;3;4;33;41' grep --color=always -E 'Revert|$' \
  | GREP_COLOR='1;3;4;30;42' grep --color=always -E 'refs\/bisect\/good|$' \
  | GREP_COLOR='1;3;4;31;43' grep --color=always -E 'refs\/bisect\/bad|$' \
  | GREP_COLOR='1;34;47' grep --color=always -Ei 'jhgu.dev|$' \
  | GREP_COLOR='1;30;47' grep --color=always -Ei 'deptno|deptno-zb|$'"
alias gpl="gh pr list \
  --json author,headRefName,baseRefName,comments,number,title,mergeable,createdAt,isDraft,state,reviewDecision,latestReviews \
  --template \
  '{{tablerow
  (\"#\"|color \"magenta\")
  (\"CREATED_AT\"|color \"magenta\")
  (\"STATE\"|color \"magenta\")
  (\"BASE\"|color \"magenta\")
  (\"HEAD\"|color \"magenta\")
  (\"CONFLICT\"|color \"magenta\")
  (\"AUTHOR\"|color \"magenta\")
  (\"DRAFT\"|color \"magenta\")
  (\"TITLE\"|color \"magenta\")
  (\"@REVIEW_DECISION\"|color \"magenta\")
  (\"LATEST_REVIEWS\"|color \"magenta\")
  (\"STATE\"|color \"magenta\")
}}
{{range .}}
{{tablerow
  .number
  (timeago .createdAt)
  .state
  .baseRefName
  (printf \"👈 %v\" .headRefName)
  .mergeable
  .author.login
  .isDraft
  .title
  (printf \"@%v\" .reviewDecision)
  (printf \"%v\" (join \",\" (pluck \"login\" (pluck \"author\" .latestReviews))))
  (printf \"%v\" (join \" \" (pluck \"state\" .latestReviews)))
}}
{{end}}'"
alias sudo="sudo "
alias watch="watch "
alias lz="lazygit"
alias oc="opencode"

# define function
function gswb() {
  gsw "$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short) - %(committerdate:relative)' | fzf |  awk '{print $1}')"
}
function gswr() {
  gsw "$(git for-each-ref --sort=-committerdate refs/remotes/origin/ --format='%(refname:short) %(committerdate:relative), %(authoremail), %(subject) - ' | fzf | awk '{print $1}' | sed 's|origin/||')"
}
function gmb() {
  gm --no-ff "$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short) - %(committerdate:relative)' | fzf |  awk '{print $1}')"
}
function gpld() {
  gpl "$@" \
  | sed '/^$/d' \
  | sed 's/[^@]COMMENTED/💬/g' \
  | sed 's/[^@]APPROVED/👍/g' \
  | sed 's/[^@]CHANGES_REQUESTED/👎/g' \
  | hl-gh;
}

function review() {
  # stash current status
  branch=@^2
  if [ ! -z "$1" ]; then
    branch=$1
  fi
  echo "$branch $1"
  git reset --mixed $(git merge-base @~ $branch)
  vim $(git diff --name-only --relative)
  git reset --hard HEAD
  git clean -fd
  git pull --rebase
}

if [ -e $XDG_CONFIG_HOME/broot/launcher/bash/br ]; then
  source $XDG_CONFIG_HOME/broot/launcher/bash/br
fi

# begin appcenter completion
# . <(appcenter --completion)
# end appcenter completion

# pyenv
# Load pyenv automatically by appending
# the following to
# ~/.bash_profile if it exists, otherwise ~/.profile (for login shells)
# and ~/.bashrc (for interactive shells) :

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Restart your shell for the changes to take effect.

# Load pyenv-virtualenv automatically by adding
# the following to ~/.bashrc:

eval "$(pyenv virtualenv-init -)"

# pipenv shell automatically
function auto_pipenv_shell {
    if [ ! -n "${PIPENV_ACTIVE+1}" ]; then
        if [ -f "Pipfile" ] ; then
            read "response?Pipfile detected. Do you want to activate the virtual environment? (Y/n): "
            response=${response:-Y}
            if [[ "$response" == [yY] ]]; then
                pipenv shell
            fi
        fi
    fi
}

function cd {
    builtin cd "$@"
    auto_pipenv_shell
}

# 에러가 있음
# auto_pipenv_shell

# yazi, https://yazi-rs.github.io/docs/quick-start
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Added by LM Studio CLI (lms)
export PATH="$PATH:${HOME}/.lmstudio/bin"

# argo cli
export ARGO_NAMESPACE=argo

eval "$(atuin init zsh)"
eval "$(zoxide init zsh)"

dup() {
  if [ -z "$2" ]; then
    echo "Usage: dup [number] [pod-template] [devpod args...]"
    return 1
  fi

  local num="$1"
  local template="$2"
  shift 2

  local template_path="${HOME}/workspace/src/github.com/deptno/cluster-amd64/template/devpod-${template}.yaml"

  if [ ! -f "$template_path" ]; then
    echo "Error: pod template not found:"
    echo "  $template_path"
    return 1
  fi

  devpod provider set-options kubernetes \
    -o LABELS="app=devpod-${num}" \
    -o POD_MANIFEST_TEMPLATE="$template_path" \
  && devpod up "$@"

  if [ $? -eq 0 ]; then
    kubectl wait -n devpod --for=condition=Ready pod -l app=devpod-${num} --timeout=60s

    POD=$(kubectl get pods -n devpod -l app=devpod-${num} \
      -o jsonpath="{.items[0].metadata.name}")

    kubectl cp \
      -n devpod \
      -c codex \
      ~/.config/opencode/opencode.json \
      $POD:/root/.config/opencode/opencode.json
  fi
}
dpac () {
  if [ -z "$2" ]; then
    echo "Usage: dpa [number] [command]"
    return 1
  fi

  local IDX="$1"
  shift

  local CMD=("$@")

  if [ -z "$IDX" ] || [ "${#CMD[@]}" -eq 0 ]; then
    echo "usage: da <index> <command>"
    echo "example: da 0 nvim"
    return 1
  fi

  local POD
  POD=$(kubectl get pods -n devpod \
    -l app=devpod-"$IDX" \
    -o jsonpath='{.items[0].metadata.name}')

  if [ -z "$POD" ]; then
    echo "no pod found for app=devpod-$IDX"
    return 1
  fi

  kubectl exec -it -n devpod "$POD" -c codex -- "${CMD[@]}"
}

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/deptno/.lmstudio/bin"
# End of LM Studio CLI section

# zshrc용: git worktree + tmux window 헬퍼
# 사용:
#   wt                # 기본: opencode
#   wt <cmd...>       # 예: wt pnpm test
#   wt bash -lc '...'

wt() {
  set -euo pipefail

  # tmux 안에서만 실행
  if [[ -z "${TMUX:-}" ]]; then
    echo "이 함수는 tmux 세션 안에서만 실행할 수 있습니다."
    return 1
  fi

  # git repo 확인
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "현재 디렉토리는 git 저장소가 아닙니다."
    return 1
  fi

  local REPO_ROOT WORKTREE_ROOT COMMON_GIT_DIR MAIN_WORKTREE_ROOT
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  WORKTREE_ROOT="$REPO_ROOT/.worktrees"
  COMMON_GIT_DIR="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir)"
  MAIN_WORKTREE_ROOT="${COMMON_GIT_DIR%/.git}"

  # main repo에 .gitignore 보정 (worktree 생성 전에)
  local GITIGNORE IGNORE_LINE
  GITIGNORE="$REPO_ROOT/.gitignore"
  IGNORE_LINE=".worktrees/"

  if [[ -f "$GITIGNORE" ]]; then
    if ! grep -Fxq "$IGNORE_LINE" "$GITIGNORE"; then
      # 마지막 줄 개행 보장
      tail -c 1 "$GITIGNORE" | read -r _ || echo >>"$GITIGNORE"
      echo "$IGNORE_LINE" >>"$GITIGNORE"
      echo ".gitignore에 추가됨: $IGNORE_LINE"
    fi
  else
    printf "%s\n" "$IGNORE_LINE" >"$GITIGNORE"
    echo ".gitignore 생성 및 추가됨: $IGNORE_LINE"
  fi

  mkdir -p "$WORKTREE_ROOT"

  # 실행 커맨드: 기본 opencode, 인자 있으면 그대로
  local RUN_CMD
  if [[ $# -eq 0 ]]; then
    RUN_CMD="opencode"
  else
    RUN_CMD="$(printf '%q ' "$@")"
    RUN_CMD="${RUN_CMD% }"
  fi

  # 1) tmux window index 먼저 확인 -> 비어있는 가장 작은 INDEX 선택
  local INDEX=1
  while tmux list-windows -F '#I' | grep -Fxq "$INDEX"; do
    INDEX=$((INDEX + 1))
  done

  local WT_PATH BRANCH WIN_NAME
  WT_PATH="$WORKTREE_ROOT/$INDEX"
  BRANCH="worktree/$INDEX"
  WIN_NAME="w"

  # worktree가 git에 등록되어 있는지 체크
  is_registered_worktree() {
    git -C "$REPO_ROOT" worktree list --porcelain |
      awk '$1=="worktree"{print $2}' |
      grep -Fxq "$WT_PATH"
  }

  # 2) worktree 경로가 이미 있으면 3지선다
  local MODE="create"
  if [[ -e "$WT_PATH" ]]; then
    echo "이미 존재함: $WT_PATH"
    echo "선택: [r] 재사용  [d] 삭제 후 재생성  [c] 취소"
    local CHOICE
    while true; do
      read -r -p "> " CHOICE
      case "$CHOICE" in
        r|R)
          if ! is_registered_worktree; then
            echo "이 경로는 git worktree로 등록되어 있지 않습니다. 재사용 불가."
            echo "[d] 삭제 후 재생성 또는 [c] 취소를 선택하세요."
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
          echo "취소됨."
          return 0
          ;;
        *)
          echo "r / d / c 중 하나를 입력하세요."
          ;;
      esac
    done
  fi

  # 3) recreate면 기존 정리
  if [[ "$MODE" == "recreate" ]]; then
    if is_registered_worktree; then
      git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" || true
    else
      rm -rf "$WT_PATH"
    fi
    git -C "$REPO_ROOT" branch -D "$BRANCH" >/dev/null 2>&1 || true
    MODE="create"
  fi

  # 4) create면 새 worktree 생성
  if [[ "$MODE" == "create" ]]; then
    git -C "$REPO_ROOT" branch -D "$BRANCH" >/dev/null 2>&1 || true
    git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WT_PATH" HEAD
  fi

  # .env* 복사
  local COPIED_ENV=0
  local -a ENV_FILES
  setopt localoptions null_glob 2>/dev/null || true
  ENV_FILES=("$MAIN_WORKTREE_ROOT"/.env*)
  for ENV_FILE in "${ENV_FILES[@]}"; do
    if [[ -f "$ENV_FILE" ]]; then
      cp -f "$ENV_FILE" "$WT_PATH/"
      COPIED_ENV=1
    fi
  done

  if [[ "$COPIED_ENV" -eq 1 ]]; then
    echo ".env* 복사 완료: $MAIN_WORKTREE_ROOT -> $WT_PATH"
  fi

  # 5) tmux window 생성 후 그 안에서 실행 + 종료 후 삭제 여부 질문
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

bash -lc "$RUN_CMD"
STATUS=$?

echo
read -r -p "이 worktree와 브랜치($BRANCH)를 삭제할까요? [y/N] " ANS || ANS=""
case "$ANS" in
  y|Y|yes|YES)
    git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" || true
    git -C "$REPO_ROOT" branch -D "$BRANCH" || true
    echo "삭제 완료: $WT_PATH ($BRANCH)"
    ;;
  *)
    echo "유지합니다: $WT_PATH ($BRANCH)"
    ;;
esac

exit "$STATUS"
'

  tmux new-window -t ":$INDEX" -n "$WIN_NAME" -c "$WT_PATH" "${ENV_PREFIX}bash -lc $(printf '%q' "$TMUX_SCRIPT")"
  tmux select-window -t ":$INDEX"

  echo "사용 INDEX: $INDEX"
  echo "worktree: $WT_PATH"
  echo "branch: $BRANCH"
}
