
# ~/.bashrc (optimized, modern, production-clean; GNU/Linux-focused)
# NOTE: This file is for interactive shells. Keep scripts clean.
[[ $- != *i* ]] && return

# -------------------------------------------------------------
# Session banner (startup info + fortune + exit line)
# - Banner + fortune run once per process tree (exported marker)
# - Exit line only if no existing EXIT trap is set
# -------------------------------------------------------------
if [[ -z ${__BASH_SESSION_BANNER_SHOWN-} ]]; then
  export __BASH_SESSION_BANNER_SHOWN=1
  _p_cyan=$'\e[36m'
  _p_red=$'\e[31m'
  _p_dim=$'\e[2m'
  _p_reset=$'\e[0m'

  printf '%sThis is BASH %s%s %s(DISPLAY=%s)%s\n' \
    "$_p_cyan" "${BASH_VERSION%.*}" "$_p_reset" \
    "$_p_dim" "${DISPLAY:-no DISPLAY}" "$_p_reset"

  printf '%s' "$_p_dim"
  date
  printf '%s\n' "$_p_reset"

  command -v fortune >/dev/null 2>&1 && fortune -s
fi

# Print a goodbye line on exit (interactive top-level only), without clobbering existing EXIT traps.
if [[ ${BASH_SUBSHELL-0} -eq 0 ]] && [[ -z $(trap -p EXIT) ]]; then
  trap 'printf "%sSee you, space cowboy...%s\n" "$_p_red" "$_p_reset"' EXIT
fi

# -------------------------------------------------------------
# History (fast, shared, de-duplicated)
# -------------------------------------------------------------
shopt -s histappend
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
# export HISTTIMEFORMAT='%F %T  '   # uncomment for timestamps in `history`

# Sync history across concurrent shells efficiently (no full reloads)
__hist_sync() { history -a; history -n; }

# -------------------------------------------------------------
# Terminal ergonomics (interactive only)
# -------------------------------------------------------------
# Disable flow control (XOFF/XON) so Ctrl-S doesn't freeze the terminal
stty -ixon 2>/dev/null || true

# Cursor: vertical bar (DECSCUSR). Use printf (more predictable than echo -e).
# Comment out if your terminal doesn't support it.
printf '\e[6 q' 2>/dev/null || true

# -------------------------------------------------------------
# Pager / less (UTF-8 + modern terminals)
# -------------------------------------------------------------
export PAGER=${PAGER:-less}
export LESS='-R -F -X -i -S'
export LESSHISTFILE=-

# Enable lesspipe if present (auto-handle .gz, .xz, tar, etc.)
if command -v lesspipe >/dev/null 2>&1; then
  export LESSOPEN='|lesspipe %s'
elif [[ -x /usr/bin/lesspipe.sh ]]; then
  export LESSOPEN='|/usr/bin/lesspipe.sh %s'
fi

# -------------------------------------------------------------
# Shell niceties 
# -------------------------------------------------------------
shopt -s checkwinsize

# Load user aliases if present (keeps ~/.bashrc small)
[[ -r ~/.bash_aliases ]] && . ~/.bash_aliases

# Machine-specific overrides (not synced; create per-host as needed)
[[ -r ~/.bash_aliases.local ]] && . ~/.bash_aliases.local

# dircolors + grep color (GNU toolchain friendly)
if command -v dircolors >/dev/null 2>&1; then
  # Respect user-defined dircolors if present
  if [[ -r ~/.dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors)"
  else
    eval "$(dircolors -b)"
  fi
fi

# Bash completion (if installed)
if ! shopt -oq posix; then
  if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    . /usr/share/bash-completion/bash_completion
  elif [[ -r /etc/bash_completion ]]; then
    . /etc/bash_completion
  fi
fi

# Editor
export EDITOR=${EDITOR:-vim}

# -------------------------------------------------------------
# Prompt (speed-optimized; Linux /proc fast paths + caching)
# -------------------------------------------------------------
_c0=$'\e[0m'
c_red=$'\e[31m'
c_green=$'\e[32m'
c_yellow=$'\e[33m'
c_cyan=$'\e[36m'
c_bred=$'\e[1;31m'
c_bcyan=$'\e[1;36m'
c_alert=$'\e[1;37;41m'
c_user=$'\e[1;38;5;80m'

if [[ $EUID -eq 0 ]]; then _userc=$c_bred; else _userc=$c_user; fi
if [[ -n ${SSH_CONNECTION-} || -n ${SSH_TTY-} ]]; then _hostc=$c_green; else _hostc=$c_bcyan; fi

_ncpu=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
_sload=$((100 * _ncpu)); _mload=$((200 * _ncpu)); _xload=$((400 * _ncpu))

# git prompt helper (optional)
if [[ -r ~/.git-prompt.sh ]]; then
  # shellcheck disable=SC1090
  source ~/.git-prompt.sh
fi

__pwd_cache=''
__diskc_cache="$c_green"
__git_cache=''
__git_pwd_cache=''

__loadc_cache="$c_green"
__load_last_s=-99999
__load_period=2

__disk_last_s=-99999
__disk_period=10

__is_remote_pwd_cache=0
__is_remote_pwd_for=''

__compute_load_color() {
  local x
  IFS=' ' read -r x _ </proc/loadavg
  x=${x/./}
  x=$((10#$x))
  if (( x > _xload )); then printf '%s' "$c_alert"
  elif (( x > _mload )); then printf '%s' "$c_bred"
  elif (( x > _sload )); then printf '%s' "$c_red"
  else printf '%s' "$c_green"
  fi
}

__load_color_cached() {
  local now=$SECONDS
  if (( now - __load_last_s >= __load_period )); then
    __load_last_s=$now
    __loadc_cache=$(__compute_load_color)
  fi
  printf '%s' "$__loadc_cache"
}

__jobs_color() {
  if [[ -n $(jobs -ps 2>/dev/null) ]]; then printf '%s' "$c_yellow"
  elif [[ -n $(jobs -pr 2>/dev/null) ]]; then printf '%s' "$c_cyan"
  else printf '%s' "$_c0"
  fi
}

__pwd_is_remote_fs() {
  if [[ $PWD == "$__is_remote_pwd_for" ]]; then
    return $__is_remote_pwd_cache
  fi
  __is_remote_pwd_for=$PWD
  __is_remote_pwd_cache=1

  if command -v findmnt >/dev/null 2>&1; then
    local fstype
    fstype=$(findmnt -n -T "$PWD" -o FSTYPE 2>/dev/null)
    case $fstype in
      nfs|nfs4|cifs|smb3|sshfs|fuse.sshfs|fuse.*|davfs|afs|9p|ceph|glusterfs|gcsfuse|s3fs)
        __is_remote_pwd_cache=0; return 0 ;;
      *) __is_remote_pwd_cache=1; return 1 ;;
    esac
  fi
  __is_remote_pwd_cache=1
  return 1
}

__refresh_disk_color_if_needed() {
  local now=$SECONDS

  if [[ $PWD != "$__pwd_cache" ]]; then
    __pwd_cache=$PWD
    if [[ ! -w $PWD ]]; then __diskc_cache=$c_red; return; fi
    if ! __pwd_is_remote_fs; then __diskc_cache=$c_cyan; return; fi
    (( now - __disk_last_s < __disk_period )) && return
  else
    (( now - __disk_last_s < __disk_period )) && return
  fi

  __disk_last_s=$now
  local used
  used=$(df -P -- "$PWD" 2>/dev/null | awk 'END{gsub(/%/,"",$5); print $5+0}')
  if [[ -z $used ]]; then __diskc_cache=$c_cyan
  elif (( used > 95 )); then __diskc_cache=$c_alert
  elif (( used > 90 )); then __diskc_cache=$c_bred
  else __diskc_cache=$c_green
  fi
}

__refresh_git_if_needed() {
  [[ $PWD == "$__git_pwd_cache" ]] && return
  __git_pwd_cache=$PWD
  __git_cache=''

  local d=$PWD i=0
  while (( i < 12 )); do
    if [[ -e "$d/.git" ]]; then
      if declare -F __git_ps1 >/dev/null 2>&1; then
        __git_cache="$(__git_ps1 ' (%s)')"
      else
        __git_cache=" ($(git branch --show-current 2>/dev/null))"
      fi
      return
    fi
    [[ $d == / ]] && break
    d=${d%/*}; [[ -z $d ]] && d=/; ((i++))
  done
}

__prompt_build() {
  __refresh_disk_color_if_needed
  __refresh_git_if_needed

  local loadc jobc title=""
  loadc=$(__load_color_cached)
  jobc=$(__jobs_color)

  case ${TERM-} in xterm*|rxvt*|screen*|tmux*) title=$'\[\e]0;[\u@\h] \w\a\]' ;; esac

  PS1="\[${loadc}\][\A\[${_c0}\] "
  PS1+="\[${_userc}\]\u\[${_c0}\]@\[${_hostc}\]\h\[${_c0}\]]\n"
  PS1+="    \[${__diskc_cache}\]\w\[${_c0}\]${__git_cache} "
  PS1+="\[${jobc}\]>\[${_c0}\] "
  PS1+="${title}"
}

# Combine prompt + history sync in a single PROMPT_COMMAND
PROMPT_COMMAND="__hist_sync; __prompt_build"
