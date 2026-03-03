# server 환경에서 256 컬러 지원을 위해 지정
case "$-" in
*i*)
  if [ "$TERM" = "xterm" ]; then
    export TERM=xterm-256color
  fi
  ;;
esac

alias gpr='git pull --rebase --autostash'
alias gp='git push'
alias lz='lazygit'
alias oc='opencode'

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [[ -f "$HOME/wt.sh" ]]; then
  source "$HOME/wt.sh"
elif [[ -f "$HOME/dotfiles/shell/scripts/wt.sh" ]]; then
  source "$HOME/dotfiles/shell/scripts/wt.sh"
fi
