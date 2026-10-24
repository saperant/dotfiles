# ~/.profile: login-shell environment.
#
# Read by bash (via ~/.bash_profile), dash, FreeBSD sh and the graphical
# session, so keep this POSIX sh. Interactive bash setup lives in ~/.bashrc.

# Prepend a directory to PATH if it exists and isn't there yet.
path_prepend() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

# Homebrew (macOS on Apple Silicon / Intel, Linuxbrew)
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$brew" ]; then
        eval "$("$brew" shellenv)"
        break
    fi
done
unset brew

# Later entries win. Tool installers (uv, cargo, opencode, ...) like to add
# their own PATH lines to shell files; those are all covered here instead.
path_prepend /snap/bin
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.opencode/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
export PATH

# Ask uv's installer not to edit shell files
export UV_NO_MODIFY_PATH=1

# Editor: neovim, vim or whatever vi the system has
if command -v nvim >/dev/null 2>&1; then
    EDITOR=nvim
elif command -v vim >/dev/null 2>&1; then
    EDITOR=vim
else
    EDITOR="vi"
fi
VISUAL=$EDITOR
export EDITOR VISUAL

export PAGER=less
export LESS='-FRi'

# Keep the system defaults when XDG_DATA_DIRS is unset (an empty entry would
# hide /usr/share from desktop applications)
export XDG_DATA_DIRS="$HOME/.local/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

# MetaFS (local user install)
[ -d "$HOME/.local/share/metafs" ] && export METAFS_ROOT="$HOME/.local/share/metafs"

# if running bash, include .bashrc (it returns early for non-interactive shells)
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
