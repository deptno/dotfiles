alias gpr='git pull --rebase --autostash'
alias gp='git push'
alias lz='lazygit'
alias oc='opencode'

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [[ -f "$HOME/wt.sh" ]]; then
  source "$HOME/wt.sh"
elif [[ -f "$HOME/dotfiles/shell/wt.sh" ]]; then
  source "$HOME/dotfiles/shell/wt.sh"
fi
