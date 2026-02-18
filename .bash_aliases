[[ $- != *i* ]] && return

# -------------------------------------------------------------
# Aliases + interactive helper functions
# -------------------------------------------------------------

# Grep colors (GNU grep)
if grep --color=auto -q "" </dev/null 2>/dev/null; then
  alias grep='grep --color=auto'
  alias egrep='egrep --color=auto'
  alias fgrep='fgrep --color=auto'
fi

# ls family (GNU ls)
if ls --color=auto >/dev/null 2>&1; then
  alias ls='ls --color=auto'
  alias ll='ls -alh --group-directories-first'
  alias la='ll -A'
  alias ltr='ls -alhtr --group-directories-first --color=auto'
  alias recent='ls -alhtr --group-directories-first --color=auto | tail'
  alias lx='ls -alhX --group-directories-first'
  alias lk='ls -alhSr --group-directories-first'
  alias lt='ls -alht  --group-directories-first'
  alias lc='ls -alhtc --group-directories-first'
  alias lu='ls -alhtu --group-directories-first'
  alias lr='ls -alhR --group-directories-first'
  alias lm='ll | less -FRX'
fi

# Quick visibility
alias disp='printf "DISPLAY=%q\n" "${DISPLAY-}"'

# Misc convenience aliases
alias agh='searchbashlogs'
alias gs='git status'
alias more='less'
alias vi="$EDITOR"
alias disp='printf "DISPLAY=%q\n" "${DISPLAY-}"'

# Functions
swap() {
  [[ $# -eq 2 ]] || { printf 'swap: 2 arguments needed\n' >&2; return 1; }
  [[ -e $1 ]]    || { printf 'swap: %s does not exist\n' "$1" >&2; return 1; }
  [[ -e $2 ]]    || { printf 'swap: %s does not exist\n' "$2" >&2; return 1; }

  local a=$1 b=$2 tmp stage=0
  tmp=$(mktemp) || return 1

  rollback() {
    if (( stage >= 1 && stage < 3 )) && [[ -e $tmp && ! -e $a ]]; then
      command mv -- "$tmp" "$a" 2>/dev/null
    fi
    command rm -f -- "$tmp" 2>/dev/null
  }
  trap rollback EXIT INT TERM

  command mv -- "$a" "$tmp" || return 1; stage=1
  command mv -- "$b" "$a"   || return 1; stage=2
  command mv -- "$tmp" "$b" || return 1; stage=3

  trap - EXIT INT TERM
  command rm -f -- "$tmp"
}

removeall() {
  local dir=$PWD
  case "$dir" in
    /|/home|"$HOME")
      printf 'Refusing to operate in critical directory: %s\n' "$dir" >&2
      return 1
      ;;
  esac

  printf "About to delete ALL contents of: %s\n" "$dir"
  read -r -p "Type 'yes' to confirm: " confirm
  [[ $confirm == yes ]] || return 1

  # GNU find: delete everything under cwd
  find . -mindepth 1 -delete
}

searchbashlogs() {
  local q=$*
  [[ -z $q ]] && { printf 'usage: searchbashlogs <query>\n' >&2; return 2; }
  if command -v rg >/dev/null 2>&1; then
    rg --hidden --no-ignore-vcs -- "$q" ~/.logs
  elif command -v ag >/dev/null 2>&1; then
    ag -- "$q" ~/.logs
  else
    printf 'searchbashlogs: install ripgrep (rg) or the_silver_searcher (ag)\n' >&2
    return 127
  fi
}
