# Workstation

This guide sets up a macOS workstation from this repository.
Run the commands from the repository root unless the text says otherwise.

## Prerequisites

- macOS.
- Homebrew. See https://brew.sh.

## Bootstrap

The bootstrap script installs the base packages and the Helm plugins.

```bash
./workstation/bootstrap.sh
```

You can also run `./bootstrap.sh` from the `workstation/` directory.

To also install AGE and SOPS for encrypted secrets, run this command:

```bash
./workstation/bootstrap.sh --with-secrets
```

The script performs these steps:

- It runs `brew bundle` with `workstation/Brewfile`.
- It runs `brew bundle` with `workstation/Brewfile.secrets` when you pass `--with-secrets`.
- It checks that Homebrew and Helm are available.
- It installs the `helm-diff` and `helm-secrets` plugins when they are absent.

For a manual install, run these commands:

```bash
brew bundle --file=workstation/Brewfile
brew bundle --file=workstation/Brewfile.secrets
helm plugin install https://github.com/databus23/helm-diff --verify=false
helm plugin install https://github.com/jkroepke/helm-secrets --verify=false
helm plugin list
```

The second command is optional for users who do not need SOPS secrets.

## Secrets

SOPS secrets use AGE.
The `.sops.yaml` file at the repository root sets the public key.
Complete these steps only when you work with encrypted files.

- Install AGE and SOPS with `./workstation/bootstrap.sh --with-secrets`.
- Create the key directory and generate the key pair:

  ```bash
  mkdir -p "$HOME/.config/sops/age"
  age-keygen -o "$HOME/.config/sops/age/keys.txt"
  ```

- Confirm that your `~/.zshrc` sets `SOPS_AGE_KEY_FILE`.
  The `zshrc.template` file already exports the key path.
- Start the Kubernetes lab when you need it.
  See [../k8s-lab/README.md](../k8s-lab/README.md).

## Shell and terminal

This setup uses zsh, Oh My Zsh, Starship, fzf, Ghostty, and Fira Code Nerd Font.
The Oh My Zsh theme and the `kube-ps1` plugin are deprecated.
Starship draws the prompt.
The `kubectl` plugin stays because it provides completion only.

### Install zsh and Oh My Zsh

macOS includes zsh.
Check the version:

```bash
zsh --version
```

Set zsh as the login shell:

```bash
chsh -s "$(which zsh)"
```

Install Oh My Zsh:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Install the custom plugins:

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
```

Install the fzf key bindings:

```bash
"$(brew --prefix)/opt/fzf/install"
```

The fzf installer adds these shortcuts:

- `Ctrl+R`: search the command history.
- `Ctrl+T`: paste a file path.
- `Alt+C`: change the directory.

### Apply the templates

Back up your current `~/.zshrc` before you copy the template.
Copy each repository template to its target file.

| Template | Target file |
| :--- | :--- |
| `zshrc.template` | `~/.zshrc` |
| `starship.toml.template` | `~/.config/starship.toml` |
| `zed-settings.json.template` | `~/.config/zed/settings.json` |

```bash
cp workstation/zshrc.template "$HOME/.zshrc"
mkdir -p "$HOME/.config"
cp workstation/starship.toml.template "$HOME/.config/starship.toml"
mkdir -p "$HOME/.config/zed"
cp workstation/zed-settings.json.template "$HOME/.config/zed/settings.json"
```

The Starship configuration uses the Catppuccin Mocha palette.
The palette needs a Nerd Font.
The `zshrc.template` file sets `EDITOR` to Zed.
The `zshrc.template` file also sets `SOPS_AGE_KEY_FILE`.

### Install the font and terminal

The Brewfile installs Fira Code Nerd Font and Ghostty.
Open Font Book and confirm that "FiraCode Nerd Font" is present.

## Zed

The Brewfile installs Zed.
Install the Catppuccin extension:

1. Open the command palette with `Cmd+Shift+P`.
2. Run `zed: extensions`.
3. Search for `Catppuccin`.
4. Install the extension.
5. Restart Zed.

Copy `zed-settings.json.template` as shown in the template section.
The settings use Catppuccin Mocha for dark mode and Catppuccin Latte for light mode.
The settings set FiraCode Nerd Font for the editor and the terminal.
The settings enable vim mode and show the minimap.
The settings disable telemetry.
Restart Zed after the change.

## Verification

Check the login shell:

```bash
echo "$SHELL"
```

Check the tools:

```bash
starship --version
helm plugin list
orb status
```

Open a new terminal and confirm these items:

- The prompt shows the Starship segments.
- The icons and ligatures render correctly.
- `Ctrl+R` opens the fzf history search.
- `Right Arrow` accepts an autosuggestion.
- Zed shows the Catppuccin Mocha theme.
- The Zed editor and terminal use FiraCode Nerd Font.

## Files

- `bootstrap.sh`: installs the base packages and the Helm plugins.
- `Brewfile`: lists the base Homebrew packages.
- `Brewfile.secrets`: lists the optional AGE and SOPS packages.
- `zshrc.template`: sets zsh, Oh My Zsh, the editor, and the SOPS key path.
- `starship.toml.template`: sets the Starship prompt.
- `zed-settings.json.template`: sets the Zed theme, font, and behavior.
