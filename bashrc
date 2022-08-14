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

        # # base16 shell
        # BASE16_SHELL="$HOME/.config/base16-shell/"
        # [ -n "$PS1" ] && \
        #     [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        #         eval "$("$BASE16_SHELL/profile_helper.sh")"
        # BASE16_SHELL_HOOKS="$HOME/.config/base16-hooks/"

        # show system information if neofetch is installed
        if [[ -z "${NEOFETCH_SHOWN+x}" ]]; then
            command -v neofetch >/dev/null 2>&1 && neofetch
            export NEOFETCH_SHOWN="true"
        fi

        # default to better versions of software where possible
        command -v colordiff >/dev/null 2>&1 && alias diff='colordiff'
        command -v neomutt >/dev/null 2>&1 && alias mutt='neomutt'

        # command line decorations
        command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
    ;;
esac

shopt -s expand_aliases

# sane defaults
alias bc='bc -l'        # use bc with mathlib support
alias cp="cp -i"        # confirm before overwriting something
alias df='df -h'       # human-readable sizes
alias free='free -m'   # show sizes in MB
alias ls='ls -p --color=auto'
alias ll='ls -l'
alias grep='grep --color=auto'
alias more=less

export RANGER_LOAD_DEFAULT_RC=FALSE

# helpers
alias open='xdg-open'
alias path='echo -e ${PATH//:/\\n}'
alias pathadd='export PATH="${PATH}:${PWD}"'
alias tmux="tmux -2"

# requires: pip install xkcdpass
alias genpass="xkcdpass -w fin-kotus -V -v '[a-z]' -n 4 -d-"

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

    function cdf {
        dst=`cdb -l | fzf`
        cdb $dst
    }

    function cdg {
        query=""
        if [ $# -eq 1 ]; then
            query="-q ""${1}"""
        fi
        dst=`find ${HOME}/src/ -type d -name '.git' | sed "s#${HOME}/src/\(.*\)\.git#\1#g" | fzf $query`
        cd "${HOME}/src/$dst"
    }
    export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g"!{.git,node_modules}/*" 2>/dev/null'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    # bind -x '"\C-p": vim $(fzf);'
fi

## git-annex related (currently not in use)
#alias koti='git --work-tree=${HOME} --git-dir=${HOME}/.koti'

# if running WSL, forward X11 to Windows host
if [ -n "$WSL_DISTRO_NAME" ]; then
    export DISPLAY=$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null):0
    export LIBGL_ALWAYS_INDIRECT=1
fi

# Export 'SHELL' to child processes.  Programs such as 'screen'
# honor it and otherwise use /bin/sh.
export SHELL

# Adjust the prompt depending on whether we're in 'guix environment'.
if [ -n "$GUIX_ENVIRONMENT" ]
then
    PS1='\u@\h \w [env]\$ '
else
    PS1='\u@\h \w\$ '
fi

# load host specific configuration
if [ -f $HOME/.bashrc_local ]; then
    . $HOME/.bashrc_local
fi

# # For sway
# if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
#     exec sway
#     export XDG_DATA_DIRS="${XDG_DATA_DIRS}:/var/lib/flatpak/exports/share:/home/saku/.local/share/flatpak/exports/share"
#     exec dbus-launch --exit-with-session sway
# fi
