# ~/.config/bash/prompt.bash: the bash prompt, sourced last from ~/.bashrc.
#
#   ⬢ toolbox ~/src/project main *+ ↑1 .venv ⚙1 ✘ 1|0 12.4s
#   ❯ _
#
# - user@host only over ssh or as root; container or jail name when in one
# - git state from git's own git-prompt.sh (shipped with git everywhere)
# - virtualenv, background jobs, exit status (per pipe stage) and duration,
#   each only when there is something to say
# - the symbol turns red after a failed command, '#' when root
# - vi mode is shown with the cursor shape (see ~/.config/readline/inputrc)
# - terminal integration: window title shows the running command, OSC 7
#   reports the cwd (new tabs open in the same directory) and OSC 133 marks
#   prompts (jump between them / select output in Ghostty, kitty, WezTerm,
#   iTerm2, VS Code, tmux 3.4+...)
#
# Tunables: PROMPT_SLOW (seconds before the duration is shown, default 3).
# Works with bash 3.2 (macOS /bin/bash) and later.

# shellcheck disable=SC2034  # GIT_PS1_* and others are read by other code

if [ "$TERM" = dumb ]; then
    PS1='\w\$ '
    return
fi

#-----------------
# One-time setup
#-----------------

# git's prompt helper; every OS ships it somewhere else
if ! declare -F __git_ps1 >/dev/null; then
    for f in \
        /usr/share/git-core/contrib/completion/git-prompt.sh \
        /usr/lib/git-core/git-sh-prompt \
        /usr/local/share/git-core/contrib/completion/git-prompt.sh \
        "${HOMEBREW_PREFIX:-/opt/homebrew}/etc/bash_completion.d/git-prompt.sh" \
        /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh \
        /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-prompt.sh
    do
        if [ -r "$f" ]; then
            . "$f"
            break
        fi
    done
    unset f
fi
GIT_PS1_SHOWDIRTYSTATE=1        # * unstaged, + staged
GIT_PS1_SHOWSTASHSTATE=1        # $ stash
GIT_PS1_SHOWUNTRACKEDFILES=1    # % untracked
GIT_PS1_SHOWUPSTREAM=auto       # < behind, > ahead, <> diverged, = in sync
GIT_PS1_SHOWCONFLICTSTATE=yes   # |CONFLICT
GIT_PS1_DESCRIBE_STYLE=branch   # detached HEAD as branch~N
GIT_PS1_SHOWCOLORHINTS=1
GIT_PS1_HIDE_IF_PWD_IGNORED=1
# (a huge repo can opt out of the dirty check: git config bash.showDirtyState false)

# Escape sequences beyond colors confuse the Linux console and old terminals
__prompt_fancy=
case $TERM in
    linux|vt*|cons*) ;;
    *) __prompt_fancy=1 ;;
esac

if [ -n "$__prompt_fancy" ]; then
    case "${LC_ALL:-${LC_CTYPE:-$LANG}}" in
        *[Uu][Tt][Ff]-8*|*[Uu][Tt][Ff]8*) __prompt_utf8=1 ;;
    esac
fi
if [ -n "$__prompt_utf8" ]; then
    __prompt_sym='❯' __prompt_err='✘' __prompt_box='⬢' __prompt_bg='⚙'
else
    __prompt_sym='$' __prompt_err='x' __prompt_box='@' __prompt_bg='&'
fi
[ "$EUID" -eq 0 ] && __prompt_sym='#'

# Colors (\[ \] tell readline they take no space)
__p_reset='\[\e[0m\]'
__p_bold='\[\e[1m\]'
__p_red='\[\e[31m\]'
__p_green='\[\e[32m\]'
__p_yellow='\[\e[33m\]'
__p_blue='\[\e[34m\]'
__p_magenta='\[\e[35m\]'
__p_cyan='\[\e[36m\]'

# Who and where: user@host over ssh or as root, plus container/jail name.
# Names go into PS1 by reference so odd characters are never expanded.
__prompt_ctr=
if [ -n "$CONTAINER_ID" ]; then                     # distrobox
    __prompt_ctr=$CONTAINER_ID
elif [ -f /run/.containerenv ]; then                # toolbox, podman
    __prompt_ctr=$(sed -n 's/^name="\(.*\)"$/\1/p' /run/.containerenv 2>/dev/null)
    : "${__prompt_ctr:=container}"
elif [ -f /.dockerenv ]; then
    __prompt_ctr=docker
fi
case $OSTYPE in
    freebsd*)
        [ "$(sysctl -n security.jail.jailed 2>/dev/null)" = 1 ] && __prompt_ctr="jail:${HOSTNAME%%.*}"
        ;;
esac

__prompt_head=
if [ "$EUID" -eq 0 ]; then
    __prompt_head="${__p_bold}${__p_red}\u@\h${__p_reset} "
elif [ -n "$SSH_CONNECTION$SSH_TTY" ]; then
    __prompt_head="${__p_bold}${__p_green}\u@\h${__p_reset} "
fi
[ -n "$__prompt_ctr" ] &&
    __prompt_head="${__prompt_head}${__p_magenta}${__prompt_box} \${__prompt_ctr}${__p_reset} "

# Window title: the directory (with user@host over ssh) while at the prompt
__prompt_title=
if [ -n "$__prompt_fancy" ]; then
    if [ -n "$SSH_CONNECTION$SSH_TTY" ]; then
        __prompt_title='\[\e]0;\u@\h: \w\a\]'
    else
        __prompt_title='\[\e]0;\w\a\]'
    fi
fi

PROMPT_DIRTRIM=4                # bash 4+: ~/…/deep/path/of/four
VIRTUAL_ENV_DISABLE_PROMPT=1    # we show the venv ourselves

# Milliseconds since some epoch into __prompt_ms
if [ -n "$EPOCHREALTIME" ]; then
    __prompt_clock() {
        __prompt_ms=${EPOCHREALTIME//[!0-9]/}   # radix is locale dependent
        __prompt_ms=$((__prompt_ms / 1000))
    }
else
    __prompt_clock() { __prompt_ms=$((SECONDS * 1000)); }
fi

#--------------------------------------
# Hooks: before a command, before PS1
#--------------------------------------

# DEBUG trap: runs before every command, but only acts on the first command
# typed after the prompt (__prompt_arm runs last in PROMPT_COMMAND).
__prompt_preexec() {
    [ -n "$__prompt_armed" ] || return 0
    # the prompt itself (empty Enter): nothing ran
    case $BASH_COMMAND in
        __prompt_precmd*)
            __prompt_armed=
            return 0
            ;;
    esac
    # not a command: tab completion, bind -x widgets
    [ -n "$COMP_LINE" ] && return 0
    [ -n "${READLINE_POINT+x}" ] && return 0

    __prompt_armed=
    __prompt_ran=1
    __prompt_clock
    __prompt_start=$__prompt_ms
    if [ -n "$__prompt_fancy" ]; then
        # end of input (133;C), default cursor shape, command as window title
        printf '\e]133;C\a\e[0 q\e]0;%s\a' "${BASH_COMMAND//[[:cntrl:]]/}"
    fi
}

__prompt_arm() {
    __prompt_armed=1
}

__prompt_precmd() {
    local status=$? pipe="${PIPESTATUS[*]}"
    history -a

    # Status and duration only describe a command that actually ran, not an
    # empty Enter
    local took=
    if [ -n "$__prompt_ran" ]; then
        __prompt_ran=
        __prompt_clock
        local ms=$((__prompt_ms - __prompt_start)) s
        s=$((ms / 1000))
        if [ "$s" -ge "${PROMPT_SLOW:-3}" ]; then
            if [ "$s" -ge 3600 ]; then
                printf -v took '%dh%02dm' $((s / 3600)) $((s % 3600 / 60))
            elif [ "$s" -ge 60 ]; then
                printf -v took '%dm%02ds' $((s / 60)) $((s % 60))
            elif [ "$s" -lt 10 ] && [ -n "$EPOCHREALTIME" ]; then
                printf -v took '%d.%ds' "$s" $((ms % 1000 / 100))
            else
                took="${s}s"
            fi
        fi
        [ -n "$__prompt_fancy" ] && printf '\e]133;D;%s\a' "$status"
    else
        status=0 pipe=0
    fi

    # Exit status; for pipelines every stage, if any failed
    local err=
    case " $pipe " in
        *" "[1-9]*) [ "$pipe" != "${pipe#* }" ] && err=${pipe// /|} ;;
    esac
    [ "$status" -ne 0 ] && [ -z "$err" ] && err=$status

    # Python virtualenv / conda env ("project" rather than ".venv")
    __prompt_env=
    if [ -n "$VIRTUAL_ENV" ]; then
        __prompt_env=${VIRTUAL_ENV##*/}
        case $__prompt_env in
            .venv|venv|.env|env) __prompt_env=${VIRTUAL_ENV%/*} __prompt_env=${__prompt_env##*/} ;;
        esac
    elif [ -n "$CONDA_DEFAULT_ENV" ] && [ "$CONDA_DEFAULT_ENV" != base ]; then
        __prompt_env=$CONDA_DEFAULT_ENV
    fi

    local jobs=0 _
    for _ in $(jobs -p); do
        jobs=$((jobs + 1))
    done

    # Report cwd to the terminal, unless Fedora's vte.sh already does
    if [ -n "$__prompt_fancy" ] && ! declare -F __vte_osc7 >/dev/null; then
        local dir=${PWD//%/%25}
        printf '\e]7;file://%s%s\a' "$HOSTNAME" "${dir// /%20}"
    fi

    local pre="" post=""
    [ -n "$__prompt_fancy" ] && pre='\[\e]133;A\a\]'
    pre="${pre}${__prompt_title}${__prompt_head}${__p_bold}${__p_blue}\w${__p_reset}"

    [ -n "$__prompt_env" ] && post="${post} ${__p_yellow}\${__prompt_env}${__p_reset}"
    [ "$jobs" -gt 0 ] && post="${post} ${__p_cyan}${__prompt_bg}${jobs}${__p_reset}"
    [ -n "$err" ] && post="${post} ${__p_bold}${__p_red}${__prompt_err} ${err}${__p_reset}"
    [ -n "$took" ] && post="${post} ${__p_yellow}${took}${__p_reset}"

    if [ "$status" -eq 0 ]; then
        post="${post}\n${__p_green}${__prompt_sym}${__p_reset} "
    else
        post="${post}\n${__p_red}${__prompt_sym}${__p_reset} "
    fi
    [ -n "$__prompt_fancy" ] && post="${post}"'\[\e]133;B\a\]'

    if declare -F __git_ps1 >/dev/null; then
        __git_ps1 "$pre" "$post" ' %s'
    else
        PS1="$pre$post"
    fi
}

#---------
# Install
#---------

# Our precmd must run first (to see $?) and the arm last. PROMPT_COMMAND is
# an array on Fedora (bash 5.1+), a string elsewhere. Skip if re-sourced.
case "${PROMPT_COMMAND[*]}" in
    *__prompt_precmd*) ;;
    *)
        if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == "declare -a"* ]]; then
            PROMPT_COMMAND=(__prompt_precmd "${PROMPT_COMMAND[@]}" __prompt_arm)
        else
            # shellcheck disable=SC2128,SC2178  # string form here
            PROMPT_COMMAND="__prompt_precmd${PROMPT_COMMAND:+; $PROMPT_COMMAND}; __prompt_arm"
        fi
        ;;
esac
trap '__prompt_preexec' DEBUG
