function gg -d "Git Go: Change Directory to a Git project inside ~/src folder"
    if test (count $argv) -gt 0
        set dst (find $HOME/src/ -type d -name '.git' | sed "s#$HOME/src/\(.*\)\.git#\1#g" | fzf -q $argv)
    else
        set dst (find $HOME/src/ -type d -name '.git' | sed "s#$HOME/src/\(.*\)\.git#\1#g" | fzf)
    end
    cd "$HOME/src/$dst"
end