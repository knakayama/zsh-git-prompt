# heavily inspired by http://qiita.com/mollifier/items/8d5a627d773758dd8078

setopt prompt_subst

autoload -Uz vcs_info
autoload -Uz add-zsh-hook
autoload -Uz is-at-least
autoload -Uz colors && colors

zstyle ':vcs_info:*' max-exports 1
zstyle ':vcs_info:*' enable git

if is-at-least 4.3.10; then
  zstyle ':vcs_info:git:*' formats '%m'
  zstyle ':vcs_info:git:*' check-for-changes true
fi

if is-at-least 4.3.11; then
  zstyle ':vcs_info:git+set-message:*' hooks \
    git-hook-begin     \
    git-branch-name    \
    git-local-diff     \
    git-remote-diff    \
    git-stash-count    \
    git-branch-count

  # initial hook function
  # call this function only when inside git work tree
  function +vi-git-hook-begin() {
    if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]]; then
      # if returing ret val 0, then do not call after function(s)
      return 1
    fi

    return 0
  }

  # more deeply insight git branch name than %b
  function +vi-git-branch-name() {
    local git_branch_name
    local yellow="%{$fg_bold[yellow]%}"
    local reset="%{${reset_color}%}"

    git_branch_name="$(git rev-parse --abbrev-ref=loose HEAD 2>/dev/null)"
    hook_com[misc]+="${yellow}${git_branch_name//[^a-z0-9\/]/-}${reset}|"
  }

  # display local diff(s)
  function +vi-git-local-diff() {

    local git_local_diff
    local clean="clean"
    local green="%{$fg_bold[green]%}"
    local reset="%{${reset_color}%}"
    local cmd

    case "$OSTYPE" in
      darwin*|freebsd*)
        cmd="script -q /dev/null git status --short --ignore-submodules=dirty"
        ;;
      linux*)
        cmd="script --quiet /dev/null --command 'git status --short --ignore-submodules=dirty'"
        ;;
      *)
        return 1
        ;;
    esac
    # preserve git status color
    # http://stackoverflow.com/questions/7641392/bash-command-preserve-color-when-piping
    git_local_diff="$(
      sh -c "$cmd" \
      | awk '{print $1}' \
      | sort | uniq -c \
      | awk '
          {
            # if you want to bold color, set color.status.* with bold attribute
            # http://stackoverflow.com/questions/12795790/how-to-colorize-git-status-output
            if ($2 ~ /31m/) {
              printf "%s\033[1;31m%s\033[0m", $2, $1
            }
            else if ($2 ~ /32m/) {
              printf "%s\033[1;32m%s\033[0m", $2, $1
            }
            else {
              # default color is red
              printf "%s\033[1;31m%s\033[0m", $2, $1
            }
          }
        ' \
      | cat
    )"

    if [[ -n "$git_local_diff" ]]; then
      hook_com[misc]+="$git_local_diff"
    else
      hook_com[misc]+="${green}${clean}${reset}"
    fi
  }

  # display remote diff(s)
  function +vi-git-remote-diff() {

    local git_remote_name
    local git_branch_name
    local git_remote_diff
    local red="%{$fg_bold[red]%}"
    local reset="%{${reset_color}%}"

    git_branch_name="$(git rev-parse --abbrev-ref=loose HEAD 2>/dev/null)"
    git_remote_name="$(git config branch.${git_branch_name}.remote 2>/dev/null)"

    # FIXME: display remote diffs on any branch
    if [[ -n "$git_remote_name" && "$git_branch_name" == "master" ]]; then
      git_remote_diff="$(
        git rev-list --left-right \
          refs/remotes/${git_remote_name}/${git_branch_name}...HEAD \
          | grep -oE '^[><]' \
          | sort | uniq -c \
          | awk '{printf "%s", $2$1} END {printf "\n"}'
      )"
    fi

    if [[ -n "$git_remote_diff" ]]; then
      hook_com[misc]+="|${red}${git_remote_diff}${reset}"
    fi
  }

  # display stashed number(s)
  function +vi-git-stash-count() {

    local stash_num
    local stash_suffix="S"
    local red="%{$fg_bold[red]%}"
    local reset="%{${reset_color}%}"

    stash_num=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

    if [[ $stash_num -ne 0 ]]; then
      hook_com[misc]+="|${red}${stash_suffix}${stash_num}${reset}"
    fi
  }

  function +vi-git-branch-count() {

    local branch_num
    local branch_suffix="B"
    local red="%{$fg_bold[red]%}"
    local reset="%{${reset_color}%}"

    branch_num=$(git branch | wc -l | tr -d ' ')

    if [[ $branch_num -gt 1  ]]; then
      hook_com[misc]+="|${red}${branch_suffix}${branch_num}${reset}"
    fi
  }
fi

function -zsh-git-prompt() {
  local -a messages
  local zsh_git_prompt
  LANG=en_US.UTF-8 vcs_info

  # if vcs_info is empty, then not set prompt
  if [[ -z "$vcs_info_msg_0_" ]]; then
    zsh_git_prompt=""
  else
    messages=("(")
    [[ -n "$vcs_info_msg_0_" ]] && messages+=("$vcs_info_msg_0_")
    messages+=(")")

    # concatenate
    zsh_git_prompt="${(j::)messages}"
  fi

  echo "$zsh_git_prompt"
}

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: ft=zsh sw=2 ts=2 et
