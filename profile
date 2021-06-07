alias more="less"
alias mroe="less"
alias dc="cd"
alias ls="ls -F --color=none"
alias ll="ls -l"
alias lla="ls -la"

export WORK="/work/$(echo $HOME | awk -F '/' '{print $3}')/$USER"
alias cdw="cd $WORK"

function c {
  curl cheat.sh/$1
}
