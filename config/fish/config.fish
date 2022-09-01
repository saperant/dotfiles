starship init fish | source

# use vim as default editor
if type -q nvim
    # prefer nvim if available
    alias vim="nvim"
    alias vi="nvim"
    export VISUAL="nvim"
    export EDITOR="nvim -e"
else
    export VISUAL="vim"
    export EDITOR="vim -e"
end

if set -q TOOLBOX_PATH
    # if inside toolbox
    alias open="flatpak-xdg-open"
    alias email="flatpak-xdg-email"
    alias xdg-open="flatpak-xdg-open"
    alias xdg-email="flatpak-xdg-email"
else
    alias open="xdg-open"
    alias email="xdg-email"
end

alias more=less

## git-annex related (currently not in use)
##alias koti='git --work-tree=${HOME} --git-dir=${HOME}/.koti'
