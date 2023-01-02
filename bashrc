# ~/.bashrc: executed by bash(1) for non-login shells.

#source /etc/environment

# use system bashrc as basis
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

shopt -s expand_aliases

# sane defaults
alias ls='ls -F --color=auto'
alias ll='ls -l'
alias lla='ls -la'
alias grep='grep --color=auto'
alias more=less

export RANGER_LOAD_DEFAULT_RC=FALSE

# helpers
alias path='echo -e ${PATH//:/\\n}'
alias pathadd='export PATH="${PATH}:${PWD}"'
alias tmux="tmux -2"

# use neovim instead of vim if available
if command -v nvim &> /dev/null
then
    alias vi="nvim"
    alias vim="nvim"
    export VISUAL="nvim"
    export EDITOR="nvim -e"
else
    export VISUAL="vim"
    export EDITOR="vim -e"
fi

# use vim as default editor and (and bindings for bash)
set -o vi

# for fuzzy finder
if [ -f ~/.fzf.bash ]
then
    source ~/.fzf.bash
    #export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g"!{.git,node_modules}/*" 2>/dev/null'
    #export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    bind -x '"\C-p": vim $(fzf);'
fi

# for z
if [ -f /usr/libexec/z.sh ]; then
    . /usr/libexec/z.sh
fi

# Export 'SHELL' to child processes.  Programs such as 'screen'
# honor it and otherwise use /bin/sh.
export SHELL

# User specific aliases and functions
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

## Decorate color enabled terminals
#case "$TERM" in
#    xterm-color|*-256color|rxvt|screen|xterm-kitty)
#        # command line decorations
#        command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
#    ;;
#esac

## For WSL: Forward X11 to Windows host
#if [ -n "$WSL_DISTRO_NAME" ]; then
#    export DISPLAY=$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null):0
#    export LIBGL_ALWAYS_INDIRECT=1
#fi

## For sway
#if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
#    exec sway
#    export XDG_DATA_DIRS="${XDG_DATA_DIRS}:/var/lib/flatpak/exports/share:${HOME}/.local/share/flatpak/exports/share"
#    exec dbus-launch --exit-with-session sway
#fi

