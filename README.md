# dotfiles

Bash, vim/neovim, tmux, git and ranger configuration for Linux (Fedora),
macOS and FreeBSD, installed with [dotbot](https://github.com/anishathalye/dotbot).

```sh
git clone --recursive <repo-url> ~/.dotfiles
~/.dotfiles/install
```

`install` applies `install.conf.yaml` and then `install.<os>.yaml` (`linux`,
`darwin`, `freebsd`) if present. Re-running it is safe.

## Layout

| Path | Linked to | |
|---|---|---|
| `profile`, `bash_profile`, `bashrc` | `~/.profile` ... | environment (POSIX sh), interactive bash |
| `config/*` | `~/.config/*` | bash prompt, readline, git, nvim, ranger |
| `bin/*`, `bin-linux/*` | `~/.local/bin/` | scripts |
| `mytools/` | `uv tool install --editable` | Python CLI helpers |
| `gitconfig.local`, `sshconfig` | copied once to `~/.gitconfig`, `~/.ssh/config` | machine-specific templates |
| `ansible/` | | packages + dotfiles for all machines |

Machine-specific shell setup goes to `~/.bashrc.d/*` (not tracked).

`xdg/` holds an XDG user-dirs mapping onto short home directories (`~/inbox`,
`~/img`, `~/media/video`, `~/music`). It is not linked by default; see
`install.linux.yaml`.

## Machines without root

Nothing here needs root. Every tool is optional: the shell detects what the
system has and skips the rest. `install` fills the important gaps in
`~/.local`:

- fzf: fetched from its GitHub release via the pinned `ext/fzf` submodule,
  when the system has none
- mytools: `uv tool install`, or run from the source tree when uv is missing
- shellcheck in the commit hook: run through `uv` when not installed

- fonts: `nerdfont` installs the Nerd Fonts symbols into the user font
  directory, which ranger's devicons, vim and the prompt need for icons. It
  works as a fontconfig fallback, so the terminal font stays as it is
  (`nerdfont check` verifies; `nerdfont install JetBrainsMono` and
  `nerdfont terminal` cover terminals without font fallback)

uv itself installs without root:
`curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh`.

## Packages

`ansible/site.yml` installs the packages these files expect (dnf, pkg or
Homebrew), makes bash the login shell and runs `install`. Hosts marked
`dotfiles_root=false` get only home-directory installs:

```sh
cd ansible
cp inventory.example.ini inventory.ini   # list your machines
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```

## Hooks

`install` points `core.hooksPath` at `.githooks/`: commits are scanned with
gitleaks for secrets and staged shell scripts with shellcheck.
