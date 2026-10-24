# ~/.bashrc: interactive bash on Linux, macOS and FreeBSD.
#
# Kept compatible with bash 3.2 (macOS /bin/bash); newer features are guarded.
# Machine-specific additions go to ~/.bashrc.d/*, which is not tracked.

# non-interactive shells (scp, rsync, bash -c) need nothing from here
case $- in
    *i*) ;;
    *) return ;;
esac

# readline config lives under XDG; set before anything initializes readline
export INPUTRC="${XDG_CONFIG_HOME:-$HOME/.config}/readline/inputrc"

# System defaults first. Fedora's /etc/bashrc loads /etc/profile.d (colors,
# completion, vte, toolbox); macOS /etc/profile already sources /etc/bashrc
# for login shells; Debian's bash reads /etc/bash.bashrc by itself.
if [ -f /etc/bashrc ]; then
    case $OSTYPE in
        darwin*) shopt -q login_shell || . /etc/bashrc ;;
        *) . /etc/bashrc ;;
    esac
fi

#---------
# History
#---------
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/bash/history"
[ -d "${HISTFILE%/*}" ] || mkdir -p "${HISTFILE%/*}"
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth
HISTIGNORE='ls:ll:la:l:bg:fg:history:clear:exit'
HISTTIMEFORMAT='%F %T  '
shopt -s histappend cmdhist
# (the prompt runs `history -a` so parallel shells don't lose history)

#----------------
# Shell options
#----------------
shopt -s checkwinsize
shopt -s globstar checkjobs 2>/dev/null  # bash 4+

#--------------------
# Colors and aliases
#--------------------
case $OSTYPE in
    darwin*|freebsd*)
        export CLICOLOR=1  # BSD ls
        ;;
    *)
        alias ls='ls --color=auto'
        # Fedora's profile.d already sets LS_COLORS
        if [ -z "$LS_COLORS" ] && command -v dircolors >/dev/null 2>&1; then
            if [ -r ~/.dircolors ]; then
                eval "$(dircolors -b ~/.dircolors)"
            else
                eval "$(dircolors -b)"
            fi
        fi
        ;;
esac
alias grep='grep --color=auto'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias more=less

# make less more friendly for non-text input files (Debian; Fedora sets
# LESSOPEN in profile.d)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
if command -v notify-send >/dev/null 2>&1; then
    alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
fi

# helpers
alias path='echo -e ${PATH//:/\\n}'
alias pathadd='export PATH="${PATH}:${PWD}"'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

export RANGER_LOAD_DEFAULT_RC=FALSE
# cht.sh keeps its config, cookie and history here instead of ~/.cht.sh
export CHTSH="${XDG_CONFIG_HOME:-$HOME/.config}/cht.sh"

# use neovim instead of vim if available (EDITOR is set in ~/.profile)
if command -v nvim >/dev/null 2>&1; then
    alias vi="nvim"
    alias vim="nvim"
fi

#------------
# Completion
#------------
# Fedora loads bash-completion from profile.d; elsewhere find it ourselves.
# bash-completion 2 needs bash 4.2+.
if [ -z "$BASH_COMPLETION_VERSINFO" ] && ! shopt -oq posix &&
    [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    for f in \
        /usr/share/bash-completion/bash_completion \
        /usr/local/share/bash-completion/bash_completion.sh \
        "${HOMEBREW_PREFIX:-/opt/homebrew}/etc/profile.d/bash_completion.sh" \
        /etc/bash_completion
    do
        if [ -r "$f" ]; then
            . "$f"
            break
        fi
    done
    unset f
fi

#-------
# Tools
#-------
# fzf: key bindings (Ctrl-T, Ctrl-R, Alt-C) and completion. fzf 0.48+ prints
# its own setup; older packages ship the scripts.
if command -v fzf >/dev/null 2>&1; then
    if __fzf_init=$(fzf --bash 2>/dev/null); then
        eval "$__fzf_init"
    else
        for f in \
            /usr/share/fzf/shell/key-bindings.bash \
            /usr/share/doc/fzf/examples/key-bindings.bash \
            /usr/local/share/examples/fzf/shell/key-bindings.bash
        do
            if [ -r "$f" ]; then
                . "$f"
                break
            fi
        done
        unset f
    fi
    unset __fzf_init

    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    # Ctrl-P: pick files with fzf and open them in the editor
    __fzf_edit() {
        local files=() f
        while IFS= read -r f; do
            files+=("$f")
        done < <(fzf --multi)
        [ ${#files[@]} -gt 0 ] && "${VISUAL:-vi}" "${files[@]}"
    }
    bind -m vi-insert -x '"\C-p": __fzf_edit'
    bind -m vi-command -x '"\C-p": __fzf_edit'
    bind -m emacs -x '"\C-p": __fzf_edit'
fi

# directory jumping: zoxide if installed, otherwise z.sh
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
else
    for f in /usr/libexec/z.sh "${HOMEBREW_PREFIX:-/opt/homebrew}/etc/profile.d/z.sh"; do
        if [ -r "$f" ]; then
            . "$f"
            break
        fi
    done
    unset f
fi

#--------------------------------------
# Local additions (machine specific)
#--------------------------------------
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

## git-annex related (currently not in use)
#alias koti='git --work-tree=${HOME} --git-dir=${HOME}/.koti'

## For WSL: Forward X11 to Windows host
#if [ -n "$WSL_DISTRO_NAME" ]; then
#    export DISPLAY=$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null):0
#    export LIBGL_ALWAYS_INDIRECT=1
#fi

## For Sway without login manager
#if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
#    exec sway
#    export XDG_DATA_DIRS="${XDG_DATA_DIRS}:/var/lib/flatpak/exports/share:${HOME}/.local/share/flatpak/exports/share"
#    exec dbus-launch --exit-with-session sway
#fi

# Prompt last: it wraps PROMPT_COMMAND and must see everything added above
if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/bash/prompt.bash" ]; then
    . "${XDG_CONFIG_HOME:-$HOME/.config}/bash/prompt.bash"
fi
