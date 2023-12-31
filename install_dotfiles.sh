#!/bin/bash

echo "Updating apt and packages..."
sudo apt update >/dev/null 2>&1
sudo apt upgrade -y >/dev/null 2>&1

declare -A packages_to_install=(
    ["curl"]=""
    ["wget"]=""
    ["xclip"]=""
    ["ntpdate"]=""
    ["git"]=""
    ["git-delta"]=""
    ["gcm"]=""
    ["python3"]=""
    ["python3-pip"]=""
    ["python3-venv"]=""
    ["ruby"]=""
    ["zsh"]=""
)

get_installed_version() {
    dpkg -s "$1" 2>/dev/null | grep '^Version: ' | awk '{print $2}'
}

installed_packages=()
updated_packages=()
skipped_packages=()

echo "Packages to be installed:"
for package in "${!packages_to_install[@]}"; do
    version=$(get_installed_version "$package")
    if [ -z "$version" ]; then
        echo "- $package (missing)"
    else
        echo "- $package ($version)"
    fi
done

read -p "Proceed with installation? [y/n] " confirm
if [[ $confirm =~ ^[Yy]$ ]]; then
    for package in "${!packages_to_install[@]}"; do
        echo "Installing $package..."

        old_version=$(get_installed_version "$package")
        sudo apt-get install -y "$package" >/dev/null 2>&1
        new_version=$(get_installed_version "$package")

        if [[ -z "$old_version" && -n "$new_version" ]]; then
            installed_packages+=("$package ($new_version)")
        elif [[ "$old_version" != "$new_version" ]]; then
            updated_packages+=("$package ($new_version)")
        elif [[ "$old_version" == "$new_version" ]]; then
            skipped_packages+=("$package ($new_version)")
        fi
    done
else
    echo "Installation cancelled."
    exit 1
fi

echo "Installation Summary:"
[[ ${#installed_packages[@]} -ne O ]] && echo "Installed: ${installed_packages[*]}"
[[ ${#updated_packages[@]} -ne O ]] && echo "Updated: ${updated_packages[*]}"
[[ ${#skipped_packages[@]} -ne O ]] && echo "Skipped: ${skipped_packages[*]}"

echo "Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null 2>&1 \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null 2>&1 \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update >/dev/null 2>&1 \
&& sudo apt install gh -y >/dev/null 2>&1

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "oh-my-zsh already installed."
fi

echo "Installing zsh plugins..."
declare -A plugins_to_clone=(
    ["romkatv/powerlevel10k"]="themes/powerlevel10k"
    ["zsh-users/zsh-autosuggestions"]="plugins/zsh-autosuggestions"
    ["zsh-users/zsh-syntax-highlighting"]="plugins/zsh-syntax-highlighting"
)

for REPO in "${!plugins_to_clone[@]}"; do
    TARGET=${plugins_to_clone[$REPO]}
    PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/$TARGET"

    if [ -d "$PLUGIN_DIR" ]; then
        if [ -z "$(ls -A "$PLUGIN_DIR")" ]; then
            echo "Cloning $TARGET..."
            git clone --depth=1 "https://github.com/$REPO" "$PLUGIN_DIR" >/dev/null 2>&1
        else
            echo "Plugin already present: $TARGET"
        fi
    else
        echo "Cloning $TARGET..."
        git clone --depth=1 "https://github.com/$REPO" "$PLUGIN_DIR">/dev/null 2>&1
    fi
done

echo "Installing gems..."
gem install colorls >/dev/null 2>&1

echo "Symlinking files..."
declare -A files_to_link=(
    ["$HOME/.gitconfig"]="$HOME/dotfiles/.gitconfig"
    ["$HOME/.gitignore"]="$HOME/dotfiles/.gitignore"
    ["$HOME/.zshrc"]="$HOME/dotfiles/.zshrc"
    ["$HOME/.p10k.zsh"]="$HOME/dotfiles/.p10k.zsh"
    ["$HOME/.nanorc"]="$HOME/dotfiles/.nanorc"
)

for LINK_NAME in "${!files_to_link[@]}"; do
    TARGET=${files_to_link[$LINK_NAME]}

    if [ -L "$LINK_NAME" ]; then
        echo "Symlink already exists: $LINK_NAME"
        read -p "Do you want to overwrite it? [y/n] " choice
        case "$choice" in
            y|Y )
                ln -sf "$TARGET" "$LINK_NAME"
                echo "Symlink updated for $LINK_NAME"
                ;;
            * )
                echo "Skipping $LINK_NAME"
                ;;
        esac
    elif [ -e "$LINK_NAME" ]; then
        echo "File exists but is not a symlink: $LINK_NAME"
        read -p "Do you want to replace it with a symlink? [y/n] " choice
        case "$choice" in
            y|Y )
                mv "$LINK_NAME" "${LINK_NAME}.backup"
                ln -s "$TARGET" "$LINK_NAME"
                echo "Symlink created and original file backed up as ${LINK_NAME}.backup"
                ;;
            * )
                echo "Skipping $LINK_NAME"
                ;;
        esac
    else
        ln -s "$TARGET" "$LINK_NAME"
        echo "Symlink created for $LINK_NAME"
    fi
done
