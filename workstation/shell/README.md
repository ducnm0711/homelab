# Shell

This directory holds shell configuration for the macOS workstation.
The setup uses zsh, Oh My Zsh, Starship, Fira Code Nerd Font, and Zed.

## Overview

- zsh is the login shell.
- Oh My Zsh provides plugins and keyboard shortcuts.
- Starship provides the prompt and terminal UI.
- Fira Code Nerd Font provides the icons and ligatures.
- Zed is the default editor and uses the Catppuccin theme.

Note: The Oh My Zsh theme and the `kube-ps1` prompt are deprecated.
Starship replaces all prompt and terminal UI customization.
The configuration keeps only the Oh My Zsh plugins that add shortcuts and completion.

## Prerequisites

Install Homebrew.
See https://brew.sh.

## Install zsh and Oh My Zsh

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

Install fzf and its key bindings:

```bash
brew install fzf
"$(brew --prefix)/opt/fzf/install"
```

The fzf installer adds these shortcuts:

- `Ctrl+R`: search the command history.
- `Ctrl+T`: paste a file path.
- `Alt+C`: change the directory.

Set the plugin list in `~/.zshrc`:

```zsh
ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
  encode64
  kubectl
  fzf
  zsh-syntax-highlighting
)
```

Do not set an Oh My Zsh theme.
Starship draws the prompt.

## Install Starship

Install Starship:

```bash
brew install starship
```

Copy the repository configuration:

```bash
mkdir -p "$HOME/.config"
cp workstation/shell/starship.toml "$HOME/.config/starship.toml"
```

Add this line at the end of `~/.zshrc`:

```zsh
eval "$(starship init zsh)"
```

The configuration uses the Catppuccin Mocha palette.
The palette needs a Nerd Font.

## Apply the repository config

Run this command from the repository root.
Back up the current `~/.zshrc` first.
Link the repository `zshrc` to the home directory:

```bash
ln -sf "$PWD/workstation/shell/zshrc" "$HOME/.zshrc"
```

The `zshrc` uses `$HOME` for all user paths.

The `zshrc` removes these deprecated items:

- The Oh My Zsh theme.
- The `kube-ps1` plugin.
- The `KUBE_PS1_*` settings.

The `kubectl` plugin stays because it provides completion.
The `kubectl` plugin does not change the prompt.

## Install Fira Code Nerd Font

Install the font:

```bash
brew install --cask font-fira-code-nerd-font
```

Open Font Book and confirm that "FiraCode Nerd Font" is present.

## Install Zed

Install Zed:

```bash
brew install --cask zed
```

Install the Catppuccin theme:

1. Open the command palette with `Cmd+Shift+P`.
2. Run `zed: extensions`.
3. Search for `Catppuccin`.
4. Install the extension.
5. Restart Zed.

## Configure Zed

Add these settings to the Zed user settings file:

```json
{
  "theme": {
    "mode": "dark",
    "dark": "Catppuccin Mocha",
    "light": "Catppuccin Latte"
  },
  "buffer_font_family": "FiraCode Nerd Font",
  "buffer_font_fallbacks": [
    "Fira Code",
    "Menlo",
    "Monaco",
    "Courier New",
    "monospace"
  ],
  "buffer_font_size": 15,
  "buffer_font_features": {
    "calt": true
  },
  "terminal": {
    "font_family": "FiraCode Nerd Font",
    "font_fallbacks": [
      "Fira Code",
      "Menlo",
      "Monaco",
      "Courier New",
      "monospace"
    ],
    "font_size": 13,
    "font_features": {
      "calt": true
    },
    "line_height": {
      "custom": 1.2
    }
  }
}
```

The repository copy is at `workstation/shell/zed-settings.json`.

Zed settings file:

- `~/.config/zed/settings.json`

Open the settings with `zed: open settings` from the command palette.
Restart Zed after the change.
The `Catppuccin` extension provides the theme names.
The `calt` feature enables Fira Code ligatures.

## Configure Cursor (optional)

Zed is the default editor.
Use this section only if you also use Cursor.

Add these settings to the Cursor user settings file:

```json
{
  "editor.fontFamily": "'FiraCode Nerd Font', 'Fira Code', Menlo, Monaco, 'Courier New', monospace",
  "editor.fontLigatures": true,
  "terminal.integrated.fontFamily": "'FiraCode Nerd Font', 'Fira Code', Menlo, Monaco, 'Courier New', monospace",
  "terminal.integrated.fontLigatures": true,
  "terminal.integrated.fontSize": 13
}
```

The repository copy is at `workstation/shell/settings.json`.

Cursor settings file:

- `~/Library/Application Support/Cursor/User/settings.json`

Restart the application after the change.

## Verification

Check the login shell:

```bash
echo "$SHELL"
```

Check Starship:

```bash
starship --version
```

Open a new terminal and confirm these items:

- The prompt shows the Starship segments.
- The icons and ligatures render correctly.
- `Ctrl+R` opens the fzf history search.
- `Right Arrow` accepts an autosuggestion.
- Zed shows the Catppuccin Mocha theme.
- The Zed editor and terminal use FiraCode Nerd Font.

## Files

- `zshrc`: zsh and Oh My Zsh configuration.
- `starship.toml`: Starship prompt configuration.
- `settings.json`: Cursor font settings.
- `zed-settings.json`: Zed editor, theme, and terminal font settings.
