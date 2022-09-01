# ~/.bashrc: executed by bash(1) for non-login shells.

#source /etc/environment

# use system bashrc as basis
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
elif [ -f /etc/skel/.bashrc ]; then
    . /etc/skel/.bashrc
elif [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

# colors
case "$TERM" in
    xterm-color|*-256color|rxvt|screen|xterm-kitty)

        # command line decorations
        command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
    ;;
esac

shopt -s expand_aliases

# sane defaults
alias ls='ls -p --color=auto'
if command -v exa &> /dev/null
then
    alias ll="exa -lh"
    alias la="exa -lAh"
    alias lat="exa -lAh --tree"
else
    alias ll='ls -lh'
    alias la="ls -lAh"
fi

alias grep='grep --color=auto'
alias more=less

export RANGER_LOAD_DEFAULT_RC=FALSE

# helpers
alias tmux="tmux -2"

# use neovim instead of vim if available
if command -v nvim &> /dev/null
then
    alias vi="nvim"
    alias vim="nvim"
fi

# use vim as default editor and (and bindings for bash)
export VISUAL="vim"
export EDITOR="vim -e"
set -o vi

# for fuzzy finder
if [ -f ~/.fzf.bash ]; then
    source ~/.fzf.bash

    function gg {
        query=""
        if [ $# -eq 1 ]; then
            query="-q ""${1}"""
        fi
        dst=`find ${HOME}/src/ -type d -name '.git' | sed "s#${HOME}/src/\(.*\)\.git#\1#g" | fzf $query`
        cd "${HOME}/src/$dst"
    }
fi

# for z
if [ -f /usr/libexec/z.sh ]; then
    . /usr/libexec/z.sh
fi

## git-annex related (currently not in use)
#alias koti='git --work-tree=${HOME} --git-dir=${HOME}/.koti'

# if running WSL, forward X11 to Windows host
if [ -n "$WSL_DISTRO_NAME" ]; then
    export DISPLAY=$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null):0
    export LIBGL_ALWAYS_INDIRECT=1
fi

# if inside toolbox
if [ -n "$TOOLBOX_PATH" ]
then
    alias open="flatpak-xdg-open"
    alias email="flatpak-xdg-email"
    alias xdg-open="flatpak-xdg-open"
    alias xdg-email="flatpak-xdg-email"
else
    alias open="xdg-open"
    alias email="xdg-email"
fi

# load host specific configuration
if [ -f $HOME/.bashrc_local ]; then
    . $HOME/.bashrc_local
fi

# # For sway
# if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
#     exec sway
#     export XDG_DATA_DIRS="${XDG_DATA_DIRS}:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"
#     exec dbus-launch --exit-with-session sway
# fi
