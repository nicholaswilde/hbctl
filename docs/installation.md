# Installation

`hbctl` is distributed as a prebuilt Rust binary via Homebrew, APT, Scoop, and GitHub Releases, or can be compiled from source with Cargo.

## :beer: Homebrew (macOS / Linux)

Install `hbctl` via [Homebrew](https://brew.sh/) using [`nicholaswilde/homebrew-tap`](https://github.com/nicholaswilde/homebrew-tap):

```bash
brew install nicholaswilde/homebrew-tap/hbctl
```

Or tap the repository first:

```bash
brew tap nicholaswilde/homebrew-tap
brew install hbctl
```

## :package: APT (Debian / Ubuntu)

Install `.deb` packages (`amd64`, `arm64`, `armhf`, `armel`) from the [`nicholaswilde/apt`](https://github.com/nicholaswilde/apt) repository ([nicholaswilde.io/apt](https://nicholaswilde.io/apt)), which bundles the binary, man page, and shell completions:

### 1. Add Repository Signing Key

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://nicholaswilde.io/apt/public.key | sudo gpg --dearmor -o /etc/apt/keyrings/nicholaswilde-apt.gpg
sudo chmod a+r /etc/apt/keyrings/nicholaswilde-apt.gpg
```

### 2. Add APT Source

=== "Deb822 (Debian 12+ / Ubuntu 22.04+)"

    ```bash
    sudo tee /etc/apt/sources.list.d/nicholaswilde.sources << 'EOF'
    Types: deb
    URIs: https://nicholaswilde.io/apt
    Suites: stable
    Components: main
    Signed-By: /etc/apt/keyrings/nicholaswilde-apt.gpg
    EOF
    ```

=== "Traditional One-Line (`.list`)"

    ```bash
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/nicholaswilde-apt.gpg] https://nicholaswilde.io/apt stable main" | sudo tee /etc/apt/sources.list.d/nicholaswilde-apt.list
    ```

### 3. Update & Install

```bash
sudo apt update
sudo apt install hbctl
```

## :icecream: Scoop (Windows)

Install `hbctl` via [Scoop](https://scoop.sh/) using [`nicholaswilde/scoop-bucket`](https://github.com/nicholaswilde/scoop-bucket):

```powershell
scoop bucket add nicholaswilde https://github.com/nicholaswilde/scoop-bucket
scoop install nicholaswilde/hbctl
```

## :inbox_tray: GitHub Releases & Self-Update

Download prebuilt archives (`.tar.gz`, `.zip`), SHA-256 checksums, and `.deb` packages for Linux, macOS, and Windows from the [GitHub Releases](https://github.com/nicholaswilde/hbctl/releases) page.

Update `hbctl` in-place directly from `nicholaswilde/hbctl` GitHub releases (alias: `hbctl self-update`):

```bash
# Check if a newer release is available without installing:
hbctl update --check

# Update interactively to the latest release:
hbctl update

# Update without confirmation prompt:
hbctl update --yes

# Install a specific release version or tag:
hbctl update --version 0.1.4 --yes
```

## :crab: Build or Install from Source

### Prerequisites

- [Rust toolchain](https://rustup.rs/)
- [Task](https://taskfile.dev/) (optional, recommended)

### Install or Build Locally

```bash title="Install with Cargo"
cargo install --git https://github.com/nicholaswilde/hbctl
```

```bash title="Build locally"
git clone https://github.com/nicholaswilde/hbctl.git
cd hbctl
task build:local
# Or directly with Cargo:
cargo build --release
```

The compiled binary will be placed at `target/release/hbctl`.

## :books: Shell Completions

Generate shell completion scripts for Bash, Zsh, Fish, PowerShell, and Elvish using `hbctl completions <shell>`:

=== "Bash"

    ```bash
    # Add to ~/.bashrc for interactive sessions:
    eval "$(hbctl completions bash)"

    # Or install to standard completion directory:
    hbctl completions bash > ~/.local/share/bash-completion/completions/hbctl
    ```

=== "Zsh"

    ```bash
    # Add to ~/.zshrc (after compinit):
    source <(hbctl completions zsh)

    # Or save to your fpath directory:
    hbctl completions zsh > ~/.zfunc/_hbctl
    # (Ensure fpath includes ~/.zfunc and autoload -Uz compinit && compinit is called)
    ```

=== "Fish"

    ```fish
    # Save to standard fish completion directory:
    hbctl completions fish > ~/.config/fish/completions/hbctl.fish

    # Or load directly in current session:
    hbctl completions fish | source
    ```

=== "PowerShell"

    ```powershell
    # Append to your PowerShell profile:
    hbctl completions powershell >> $PROFILE

    # Or load into active session:
    hbctl completions powershell | Out-String | Invoke-Expression
    ```

=== "Elvish"

    ```elvish
    # Append to your Elvish rc:
    hbctl completions elvish >> ~/.elvish/rc.elv

    # Or load into active session:
    eval (hbctl completions elvish | slurp)
    ```

Pre-generated completion scripts are also available in the [`completions/`](https://github.com/nicholaswilde/hbctl/tree/main/completions) folder.

## :page_facing_up: Man Page

Generate or view the UNIX man page:

```bash
# Generate man page
task man
# Or with binary
hbctl man > assets/hbctl.1

# Preview formatted man page
man -l assets/hbctl.1
```
