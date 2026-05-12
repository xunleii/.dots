# Applications Installed

This document lists all applications currently installed on the system, categorized by function with brief descriptions.

**Legend:**
- 🏠 = Managed by chezmoi
- 📦 = Homebrew Formula
- 🍺 = Homebrew Cask
- 🍎 = Mac App Store
- 💿 = Manual Installation (DMG/Direct)

## Development Tools

### IDEs & Code Editors
- **Visual Studio Code** (🍺) - Microsoft's popular code editor with extensive extension support
  ```bash
  brew install --cask visual-studio-code
  ```
- **Antigravity** (🍺 + 💿) - AI-powered development environment and code assistant
  ```bash
  brew install --cask antigravity
  ```
- **Neovim** (📦 + 🏠) - Modern, extensible Vim-based terminal text editor
  ```bash
  brew install neovim
  ```

### Development Environment
- **OrbStack** (💿) - Fast, lightweight Docker Desktop alternative for macOS
  ```bash
  # Download from https://orbstack.dev/download
  ```

### Shells & Terminal
- **Fish** (📦 + 🏠) - User-friendly command line shell
  ```bash
  brew install fish
  ```
- **Nushell** (📦) - Modern shell with structured data pipelines
  ```bash
  brew install nushell
  ```
- **Bash** (📦) - Enhanced version of Bourne Again Shell
  ```bash
  brew install bash
  ```
- **iTerm2** (🍺 + 💿) - Advanced terminal emulator for macOS
  ```bash
  brew install --cask iterm2
  ```
- **iTermAI** (💿) - iTerm2 with AI capabilities
  ```bash
  # Download from https://iterm2.com/ai.html
  ```

### CLI Tools & Utilities (Managed by chezmoi)
- **bat** (🏠) - Cat clone with syntax highlighting
  ```bash
  # Managed by mise: mise use -g ubi:sharkdp/bat@latest
  # OR by chezmoi: defined in .chezmoiexternal.toml (fish completion only)
  ```
  # direnv removed — managed by mise
- **lazygit** (🏠) - Terminal UI for git commands
  ```bash
  # Managed by chezmoi: defined in .chezmoiexternal.toml
  # Downloads from https://github.com/jesseduffield/lazygit/releases
  ```
- **mise** (🏠) - Polyglot runtime manager (successor to asdf)
  ```bash
  # Managed by chezmoi: defined in .chezmoiexternal.toml
  # Downloads from https://github.com/jdx/mise/releases
  ```
- **usage** (🏠) - Tool usage specification and CLI generator
  ```bash
  # Managed by chezmoi: defined in .chezmoiexternal.toml
  # Downloads from https://github.com/jdx/usage/releases
  ```
- **zoxide** (🏠) - Smarter cd command with fuzzy directory jumping
  ```bash
  # Managed by chezmoi: defined in .chezmoiexternal.toml
  # Downloads from https://github.com/ajeetdsouza/zoxide/releases
  ```
- **Bitwarden Secrets Manager (bws)** (🏠) - CLI for Bitwarden secrets management
  ```bash
  # Managed by chezmoi: defined in .chezmoiexternal.toml
  # Downloads from https://github.com/bitwarden/sdk-sm/releases
  ```

## System Utilities

### System Monitoring & Management
- **btop** (📦 + 🏠) - Resource monitor with interactive interface
  ```bash
  brew install btop
  ```
- **iStat Menus** (💿) - Advanced Mac system monitor in menu bar
  ```bash
  # Download from https://bjango.com/mac/istatmenus/
  ```
- **ncdu** (📦) - NCurses disk usage analyzer
  ```bash
  brew install ncdu
  ```
- **tree-sitter** (📦) - Parser generator and incremental parsing library
  ```bash
  brew install tree-sitter@0.25
  ```
- **Atuin** (📦 + 💿) - Magical shell history with sync capabilities
  ```bash
  brew install atuin
  ```

### File Management & Sync
- **RsyncUI** (🍺 + 💿) - GUI for rsync file synchronization
  ```bash
  brew install --cask rsyncui
  ```
- **RAR** (🍺) - Archive compression utility
  ```bash
  brew install --cask rar
  ```
- **eza** (📦) - Modern replacement for ls command
  ```bash
  brew install eza
  ```

### Text & Search Utilities
- **grep** (📦) - Enhanced GNU grep for text search
  ```bash
  brew install grep
  ```
- **lnav** (📦) - Advanced log file navigator
  ```bash
  brew install lnav
  ```
- **colordiff** (📦) - Colorized diff output
  ```bash
  brew install colordiff
  ```

### Cleanup & Maintenance
- **AppCleaner** (🍺 + 💿) - Thorough application uninstaller
  ```bash
  brew install --cask appcleaner
  ```
- **TrashMe 3** (🍎) - Advanced application uninstaller
  ```bash
  mas install 1490879410
  ```

## Security & Privacy

### VPN & Network Security
- **NordVPN** (🍎 + 💿) - VPN service for privacy and security
  ```bash
  mas install 905953485
  ```
- **Tailscale** (💿) - Zero-config VPN mesh network
  ```bash
  # Download from https://tailscale.com/download/mac
  ```

### Security Tools
- **Little Snitch** (💿) - Network monitoring and firewall
  ```bash
  # Download from https://www.obdev.at/products/littlesnitch/
  ```
- **GnuPG** (📦) - GNU Privacy Guard for encryption
  ```bash
  brew install gnupg
  ```
- **pinentry** (📦) - Secure password entry
  ```bash
  brew install pinentry
  ```
- **pinentry-mac** (📦) - macOS native pinentry
  ```bash
  brew install pinentry-mac
  ```

### Password Management
- **Bitwarden** (🍎 + 💿) - Open-source password manager
  ```bash
  mas install 1352778147
  ```
- **Yubico Authenticator** (🍎 + 💿) - 2FA authenticator for YubiKey
  ```bash
  mas install 1497506650
  ```

## Productivity & Communication

### Communication
- **Slack** (🍺 + 🍎 + 💿) - Team collaboration and messaging platform
  ```bash
  brew install --cask slack
  # OR: mas install 803453959
  ```
- **Proton Mail Bridge** (💿) - Desktop bridge for ProtonMail
  ```bash
  # Download from https://proton.me/mail/bridge
  ```

### Productivity Tools
- **Raycast** (💿) - Productivity launcher and command center
  ```bash
  # Download from https://www.raycast.com/
  ```
- **Magnet** (🍎 + 💿) - Window management tool
  ```bash
  mas install 441258766
  ```

## Internet & Browsing

### Web Browsers
- **Google Chrome** (💿) - Google's web browser
  ```bash
  # Download from https://www.google.com/chrome/
  ```
- **Zen Browser** (🍺 + 💿) - Privacy-focused web browser
  ```bash
  brew install --cask zen-browser
  ```
- **Safari** (💿) - Apple's default web browser
  ```bash
  # Pre-installed on macOS
  ```

## Media & Entertainment

### Media Players
- **VLC** (🍺 + 💿) - Versatile media player
  ```bash
  brew install --cask vlc
  ```
- **tinyMediaManager** (💿) - Media library management tool
  ```bash
  # Download from https://www.tinymediamanager.org/
  ```

### Gaming
- **Steam** (💿) - Gaming platform and store
  ```bash
  # Download from https://store.steampowered.com/about/
  ```
- **League of Legends** (💿) - Multiplayer online battle arena game
  ```bash
  # Download from https://www.leagueoflegends.com/
  ```

## 3D Printing & Manufacturing

### 3D Printing Software
- **BambuStudio** (💿) - Slicer for Bambu Lab 3D printers
  ```bash
  # Download from https://bambulab.com/en/download/studio
  ```
- **BambuSuite** (💿) - Complete suite for Bambu Lab printers
  ```bash
  # Download from https://bambulab.com/en/download
  ```

### CAD, Electronics & Design
- **Autodesk Fusion** (💿) - Cloud-based 3D CAD/CAM/CAE software
  ```bash
  # Download from https://www.autodesk.com/products/fusion-360/
  ```
- **EasyEDA** (🍺 + 💿) - Electronic circuit design and PCB layout
  ```bash
  brew install --cask easyeda
  ```

### Printing Tools
- **Brother iPrint&Scan** (🍎 + 💿) - Brother printer management
  ```bash
  mas install 1193539993
  ```
- **Labelife** (🍎 + 💿) - Label printing software
  ```bash
  mas install 1560922539
  ```

## Hardware & System Tools

### Network Tools
- **trippy** (📦) - Network diagnostic tool with visual traceroute
  ```bash
  brew install trippy
  ```
- **ipcalc** (📦) - IP subnet calculator
  ```bash
  brew install ipcalc
  ```

## AI & Machine Learning

- **Claude** (💿) - Anthropic's AI assistant desktop application
  ```bash
  # Download from https://claude.ai/download
  ```
- **Ollama** (📦) - Local large language model runner
  ```bash
  brew install ollama
  ```

## Miscellaneous

- **mas** (📦) - Mac App Store command-line interface
  ```bash
  brew install mas
  ```
