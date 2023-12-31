#!/bin/bash

# Update apt
apt update
apt upgrade -y

# Install from apt
apt install \
    curl wget xclip \
    ntpdate \
    git git-delta gcm \
    python3 python3-pip python3-venv \
    ruby \
    zsh zsh-syntax-highlighting \
    -y

# Install oh-my-zsh
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh

# Install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& apt update \
&& apt install gh -y

# Symlink dotfiles
GITCONFIG="$HOME/.gitconfig"
GITCONFIG_TARGET="$HOME/dotfiles/.gitconfig"

if [ -L "$GITCONFIG" ]; then
    echo "Symlink already exists: $GITCONFIG"
    # Optional: Prompt to overwrite or skip
elif [ -e "$GITCONFIG" ]; then
    echo "File exists but is not a symlink: $GITCONFIG"
    # Handle this situation - maybe backup the existing file or prompt the user
else
    ln -s "$GITCONFIG_TARGET" "$GITCONFIG"
    echo "Symlink created for $GITCONFIG"
fi

ZSHRC="$HOME/.zshrc"
ZSHRC_TARGET="$HOME/dotfiles/.zshrc"

if [ -L "$ZSHRC" ]; then
    echo "Symlink already exists: $ZSHRC"
    # Optional: Prompt to overwrite or skip
elif [ -e "$ZSHRC" ]; then
    echo "File exists but is not a symlink: $ZSHRC"
    # Handle this situation - maybe backup the existing file or prompt the user
else
    ln -s "$ZSHRC_TARGET" "$ZSHRC"
    echo "Symlink created for $ZSHRC"
fi

P10K="$HOME/.p10k.zsh"
P10K_TARGET="$HOME/dotfiles/.p10k.zsh"

if [ -L "$P10K" ]; then
    echo "Symlink already exists: $P10K"
    # Optional: Prompt to overwrite or skip
elif [ -e "$P10K" ]; then
    echo "File exists but is not a symlink: $P10K"
    # Handle this situation - maybe backup the existing file or prompt the user
else
    ln -s "$P10K_TARGET" "$P10K"
    echo "Symlink created for $P10K"
fi

# Install Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

source ~/.zshrc
